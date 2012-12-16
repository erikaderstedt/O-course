//
//  ASOCADController_Area.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-06-26.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASOCADController_Area.h"

@implementation ASOCADController (ASOCADController_Area)

- (NSArray *)cachedDrawingInfoForAreaObject:(struct ocad_element *)e {
    struct ocad_area_symbol *area = (struct ocad_area_symbol *)(e->symbol);
    int c;
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:5];
    
    if (e->nCoordinates == 0 ||
        area == NULL ||
        area->status == 2 /* Hidden */)
        return nil;
	
	CGMutablePathRef p = CGPathCreateMutable();
	CGPathMoveToPoint(p, NULL, e->coords[0].x >> 8, e->coords[0].y >> 8);
    
    // TODO: Handle the case where (e->coords[c].x & 8) is true.
    // TODO: Handle the case where (area->border_enabled) is true.
    // TODO: render the border.
    for (c = 0; c < e->nCoordinates; c++) {
        if (e->coords[c].x & 1) {
            // Bezier curve.
			CGPathAddCurveToPoint(p, NULL,	e->coords[c].x >> 8, e->coords[c].y >> 8,
                                  e->coords[c+1].x >> 8, e->coords[c+1].y >> 8,
								  e->coords[c+2].x >> 8, e->coords[c+2].y >> 8);
            c += 2;
            
        } else if (e->coords[c].y & 2) {
			CGPathCloseSubpath(p);
			CGPathMoveToPoint(p, NULL, e->coords[c].x >> 8, e->coords[c].y >> 8);
        } else {
			CGPathAddLineToPoint(p, NULL, e->coords[c].x >> 8, e->coords[c].y >> 8);
        }
    }

    if (area->fill_enabled) {
        CGColorRef fillColor = [self colorWithNumber:area->fill_color];
        [result addObject:[NSDictionary dictionaryWithObjectsAndKeys:(id)fillColor, @"fillColor", p, @"path", 
                           [NSNumber numberWithInt:kCGPathEOFill], @"fillMode",
                           [NSNumber numberWithInt:area->fill_color], @"colornum",
                           [NSValue valueWithPointer:e],@"element", nil]];
    }
    
    if (area->hatch_mode > 0) {
        [result addObject:[NSDictionary dictionaryWithObjectsAndKeys:[hatchColors objectForKey:[NSNumber numberWithInt:area->symnum]], @"fillColor", 
                           [NSNumber numberWithInt:kCGPathEOFill], @"fillMode",
                           [NSNumber numberWithInt:area->hatch_color], @"colornum",
                           p, @"path", [NSValue valueWithPointer:e],@"element", nil]];
        if (area->hatch_mode == 2) {
            [result addObject:[NSDictionary dictionaryWithObjectsAndKeys:[secondaryHatchColors objectForKey:[NSNumber numberWithInt:area->symnum]], @"fillColor",
                               [NSNumber numberWithInt:kCGPathEOFill], @"fillMode",
                               [NSNumber numberWithInt:area->hatch_color], @"colornum",
                               p, @"path", [NSValue valueWithPointer:e],@"element", nil]];            
        }
    }

    if (area->structure_mode != 0) {
        [result addObject:[NSDictionary dictionaryWithObjectsAndKeys:[structureColors objectForKey:[NSNumber numberWithInt:area->symnum]], @"fillColor", 
                           [NSNumber numberWithInt:kCGPathEOFill], @"fillMode",
                           [NSNumber numberWithInt:((struct ocad_symbol_element *)area->coords)->color], @"colornum",
                           p, @"path", [NSValue valueWithPointer:e],@"element", nil]];
    }
    
    CGPathRelease(p);
	return result;
}

- (void)createAreaSymbolColors {
    // Create the pattern colors for each symbol in the database.
    NSMethodSignature *ms;
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSInvocation *inv;
    [queue setMaxConcurrentOperationCount:3];
    ms = [self methodSignatureForSelector:@selector(createStructureColors)];
    inv = [NSInvocation invocationWithMethodSignature:ms];
    [inv setTarget:self];
    [inv setSelector:@selector(createStructureColors)];
    [queue addOperation:[[[NSInvocationOperation alloc] initWithInvocation:inv] autorelease]];
    
    ms = [self methodSignatureForSelector:@selector(createHatchColors)];
    inv = [NSInvocation invocationWithMethodSignature:ms];
    [inv setTarget:self];
    [inv setSelector:@selector(createHatchColors)];
    [queue addOperation:[[[NSInvocationOperation alloc] initWithInvocation:inv] autorelease]];

    ms = [self methodSignatureForSelector:@selector(createSecondaryHatchColors)];
    inv = [NSInvocation invocationWithMethodSignature:ms];
    [inv setTarget:self];
    [inv setSelector:@selector(createSecondaryHatchColors)];
    [queue addOperation:[[[NSInvocationOperation alloc] initWithInvocation:inv] autorelease]];

    [queue waitUntilAllOperationsAreFinished];

}

- (void)createStructureColors {
    structureColors = [NSMutableDictionary dictionaryWithCapacity:100];
    int i;
    struct ocad_area_symbol *area;
    
    for (i = 0; i < ocdf->num_symbols; i++) {
        if (ocdf->symbols[i]->otp != ocad_area_object) continue;
        area = (struct ocad_area_symbol *)(ocdf->symbols[i]);
        if (area->structure_mode == 0) continue;
        
        [structureColors setObject:(id)[self structureColorForSymbol:area] forKey:[NSNumber numberWithInt:area->symnum]];
    }
    
    [structureColors retain];
}

- (void)createHatchColors {
    hatchColors = [NSMutableDictionary dictionaryWithCapacity:100];
    int i;
    struct ocad_area_symbol *area;
    
    for (i = 0; i < ocdf->num_symbols; i++) {
        if (ocdf->symbols[i]->otp != ocad_area_object) continue;
        area = (struct ocad_area_symbol *)(ocdf->symbols[i]);
        if (area->hatch_mode == 0) continue;
        
        [hatchColors setObject:(id)[self hatchColorForSymbol:area index:0] forKey:[NSNumber numberWithInt:area->symnum]];
    }
    
    [hatchColors retain];
}

- (void)createSecondaryHatchColors {
    secondaryHatchColors = [NSMutableDictionary dictionaryWithCapacity:100];
    int i;
    struct ocad_area_symbol *area;
    
    for (i = 0; i < ocdf->num_symbols; i++) {
        if (ocdf->symbols[i]->otp != ocad_area_object) continue;
        area = (struct ocad_area_symbol *)(ocdf->symbols[i]);
        if (area->hatch_mode != 2) continue;
        
        [secondaryHatchColors setObject:(id)[self hatchColorForSymbol:area index:1] forKey:[NSNumber numberWithInt:area->symnum]];
    }
    
    [secondaryHatchColors retain];    
}

- (CGColorRef)structureColorForSymbol:(struct ocad_area_symbol *)a {
    CGColorSpaceRef cspace = CGColorSpaceCreatePattern(NULL);
    CGPatternRef pattern;
    void *info;
    int c;
    CGRect pRect;
    struct ocad_symbol_element *se = (struct ocad_symbol_element *)(a->coords);
    CGAffineTransform transform = self.areaColorTransform;

    NSAssert(a->structure_mode == 1 || a->structure_mode == 2, @"Invalid structure mode!");
    if (a->data_size == 0) return [self colorWithNumber:0];

    pRect = CGRectMake(-0.5*((CGFloat)a->structure_width), -0.5*((CGFloat)a->structure_height), a->structure_width, a->structure_height);
    if (a->structure_mode == 2) {
        pRect.size.height = 2.0*pRect.size.height;
    } 

    if (a->structure_angle != 0) {
        transform = CGAffineTransformRotate(transform, ((double)a->structure_angle) * M_PI / 180.0 / 10.0);
    }
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGColorRef color = [self colorWithNumber:se->color];
    
    switch (se->symbol_type) {
        case 1: /* Line */
            CGPathMoveToPoint(path, NULL, se->points[0].x >> 8, se->points[0].y >> 8);
            for (c = 1; c < se->ncoords; c++) {
                CGPathAddLineToPoint(path, NULL, se->points[c].x >> 8, se->points[c].y >> 8);
            }
            break;
        case 2: /* Area */
            CGPathMoveToPoint(path, NULL, se->points[0].x >> 8, se->points[0].y >> 8);
            for (c = 1; c < se->ncoords; c++) {
                if (se->points[c].x & 1) {
                    CGPathAddCurveToPoint(path, NULL, se->points[c].x >> 8, se->points[c].y >> 8, 
                                          se->points[c + 1].x >> 8, se->points[c + 1].y >> 8, 
                                          se->points[c + 2].x >> 8, se->points[c + 2].y >> 8);                       
                    c += 2;
                } else {
                    CGPathAddLineToPoint(path, NULL, se->points[c].x >> 8, se->points[c].y >> 8);
                }
            }
            CGPathCloseSubpath(path);
            break;
        case 3:
        case 4: /* Dot. */
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-(se->diameter / 2) + (se->points[0].x >> 8), -(se->diameter / 2) + (se->points[0].y >> 8), se->diameter, se->diameter));
            break;
        default:
            break;
    }
    
    // Supply the path, the color, the symbol element pointer and the structure mode to the pattern drawing function.
    // We need the symbol element to determine what to do with the path and to set the line width for lines.
    void *args[7]; int num_args = 5;
    args[0] = path;
    args[1] = color;
    args[2] = (void *)CFNumberCreate(NULL, kCFNumberSInt16Type, &(se->symbol_type));
    args[3] = (void *)CFNumberCreate(NULL, kCFNumberSInt16Type, &(se->line_width));
    args[4] = (void *)CFNumberCreate(NULL, kCFNumberSInt16Type, &(a->structure_mode));
    if (a->structure_mode == 2) {
        args[5] = (void *)CFNumberCreate(NULL, kCFNumberSInt16Type, &(a->structure_width));
        args[6] = (void *)CFNumberCreate(NULL, kCFNumberSInt16Type, &(a->structure_height));
        num_args += 2;
    }
    info = (void *)CFArrayCreate(NULL, (const void **)args, num_args, &kCFTypeArrayCallBacks);
    CFRelease((CFNumberRef)args[2]);
    CFRelease((CFNumberRef)args[3]);
    CFRelease((CFNumberRef)args[4]);
    if (a->structure_mode == 2) {
        CFRelease((CFNumberRef)args[5]);
        CFRelease((CFNumberRef)args[6]);
    }

    const CGPatternCallbacks callbacks = {0, &drawStructured, NULL};
    pattern = CGPatternCreate(info, pRect, transform, pRect.size.width, pRect.size.height, kCGPatternTilingConstantSpacing, true, &callbacks);
    CGFloat components[1] = {1.0};
    CGColorRef structureColor = CGColorCreateWithPattern(cspace, pattern, components);
    CGColorSpaceRelease(cspace);
    CGPatternRelease(pattern);
    
    return structureColor;
}

- (CGColorRef)hatchColorForSymbol:(struct ocad_area_symbol *)a index:(int)index {    
    // TODO: We do not support hatched symbols that have an "external" rotation applied using the element angle. Fix!
    CGColorSpaceRef cspace = CGColorSpaceCreatePattern(NULL);
    CGPatternRef pattern;
    void *info;
    CGAffineTransform transform = self.areaColorTransform;
    
    NSAssert(a->hatch_mode != 0, @"This symbol does not have a hatch pattern!");
    NSAssert(index < a->hatch_mode, @"Invalid hatch index.");
    NSAssert(a->hatch_mode <= 2, @"Hatch mode needs to be less than or equal to 2.");
    
    int angle = (index == 0)?(a->hatch_angle1):(a->hatch_angle2);
    int direction = 0;
    CGRect pRect;
    if (angle % 900 == 0) {
        if (angle == 0) { // Horizontal pattern.
            pRect = CGRectMake(0.0, 0.0, 1.0, a->hatch_dist);
        } else { // Vertical pattern.
            direction = 1;
            pRect = CGRectMake(0.0, 0.0, a->hatch_dist, 1.0);
        }
    } else {
        pRect = CGRectMake(0.0, 0.0, 1.0, a->hatch_dist);
        transform = CGAffineTransformRotate(transform, ((double)angle) * M_PI / 180.0 / 10.0);
    }

    void *args[3];
    args[0] = [self colorWithNumber:a->hatch_color];
    double width = (double)(a->hatch_line_width);
    args[1] = (void *)CFNumberCreate(NULL, kCFNumberDoubleType, &width);
    args[2] = (void *)CFNumberCreate(NULL, kCFNumberIntType, &direction);
    info = (void *)CFArrayCreate(NULL, (const void **)args, 3, &kCFTypeArrayCallBacks);
    CFRelease((CFNumberRef)args[1]);
    CFRelease((CFNumberRef)args[2]);
    
    const CGPatternCallbacks callbacks = {0, &drawHatched, NULL};
    pattern = CGPatternCreate(info, pRect, transform, pRect.size.width, pRect.size.height, kCGPatternTilingConstantSpacing, true, &callbacks);
    CGFloat components[1] = {1.0};
    CGColorRef c = CGColorCreateWithPattern(cspace, pattern, components);
    CGColorSpaceRelease(cspace);
    CGPatternRelease(pattern);
    
    return c;
}

@end

void drawHatched(void *info, CGContextRef context) {
    // Color is at 0 index, line width is at 1 index, direction is at 2 index.
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 0));
    CFNumberRef n = (CFNumberRef)CFArrayGetValueAtIndex((CFArrayRef)info, 1);    
    double width;
    int direction;
    CFNumberGetValue(n, kCFNumberDoubleType, &width);
    n = (CFNumberRef)CFArrayGetValueAtIndex((CFArrayRef)info, 2);
    CFNumberGetValue(n, kCFNumberIntType, &direction);
    if (direction == 0) {
        CGContextFillRect(context, CGRectMake(0.0, 0.0, 1.0, width));
    } else {
        CGContextFillRect(context, CGRectMake(0.0, 0.0, width, 1.0));        
    }    
}

void drawStructured(void *info, CGContextRef context) {
    CFArrayRef inputValues = (CFArrayRef)info;
    CGPathRef path = CFArrayGetValueAtIndex(inputValues, 0);
    CGColorRef color = (CGColorRef)CFArrayGetValueAtIndex(inputValues, 1);
    int16_t type, line_width, structure_mode;
    
    // For structure_mode 2
    int16_t width, height; 
    CGAffineTransform transform1;
    CGAffineTransform transform2;
    
    CFNumberGetValue((CFNumberRef)CFArrayGetValueAtIndex(inputValues, 2), kCFNumberSInt16Type, &type);
    CFNumberGetValue((CFNumberRef)CFArrayGetValueAtIndex(inputValues, 3), kCFNumberSInt16Type, &line_width);
    CFNumberGetValue((CFNumberRef)CFArrayGetValueAtIndex(inputValues, 4), kCFNumberSInt16Type, &structure_mode);

    
    if (structure_mode == 2) {
        CFNumberGetValue((CFNumberRef)CFArrayGetValueAtIndex(inputValues, 5), kCFNumberSInt16Type, &width);
        CFNumberGetValue((CFNumberRef)CFArrayGetValueAtIndex(inputValues, 6), kCFNumberSInt16Type, &height);
        
        // Translate the context -0.5*width, 1.0*height.
        transform1 = CGAffineTransformMakeTranslation(-0.5*((CGFloat)width), (CGFloat)height);
        
        // Translate the context 1.0*width.
        transform2 = CGAffineTransformMakeTranslation((CGFloat)width, 0.0);
        CGContextSaveGState(context);
    }

    CGPathDrawingMode mode;
    switch (type) {
        case 1:
        case 3:
            CGContextSetLineWidth(context, (CGFloat)line_width);
            CGContextSetLineCap(context, kCGLineCapButt); // TODO: support rounded line ends (flags element in symbol_element structure).
            CGContextSetStrokeColorWithColor(context, color);
            mode = kCGPathStroke;
            break;
        case 2:
        case 4:
            CGContextSetFillColorWithColor(context, color);
            mode = kCGPathEOFill;
            break;
        default:
            break;
    }
    
    CGContextBeginPath(context);
    CGContextAddPath(context, path);
    CGContextDrawPath(context, mode);
    
    if (structure_mode == 2) {
        CGContextBeginPath(context);
        CGContextConcatCTM(context, transform1);
        CGContextAddPath(context, path);
        CGContextDrawPath(context, mode);

        CGContextBeginPath(context);
        CGContextConcatCTM(context, transform2);
        CGContextAddPath(context, path);
        CGContextDrawPath(context, mode);    

        CGContextRestoreGState(context);
    }
}
