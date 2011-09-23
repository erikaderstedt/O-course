//
//  ASOCADController_Area.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-06-26.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASOCADController_Area.h"

@implementation ASOCADController (ASOCADController_Area)

- (NSDictionary *)cachedDrawingInfoForAreaObject:(struct ocad_element *)e {
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
    CGColorRef daColor = (CGColorRef)[areaSymbolColors objectForKey:[NSNumber numberWithInt:area->symnum]];
    NSNumber *angle = nil;
    if (e->angle != 0 && e->angle != 3600) {
        angle = [NSNumber numberWithDouble:((CGFloat)e->angle)/10.0];
    }

    if (area->fill_enabled) {
        CGColorRef fillColor = [self colorWithNumber:area->fill_color];
        [result addObject:[NSDictionary dictionaryWithObjectsAndKeys:(id)fillColor, @"fillColor", p, @"path", [NSValue valueWithPointer:e],@"element", angle, @"angle", nil]];
    }
	CGPathRelease(p);
	return result;
}

- (CGColorRef)areaColorForSymbol:(struct ocad_area_symbol *)a transform:(CGAffineTransform)transform {
    CGColorSpaceRef cspace = CGColorSpaceCreatePattern(NULL);
    CGPatternRef pattern;
    void *drawFunction;
    void *info;
    CGColorRef cs[2];
    int i;
    for (i = 0; i < a->ncolors; i++) {
        cs[i] = [self colorWithNumber:a->colors[i]];
    }
    info = cs[0];
    
    CGRect pRect;
    switch (a->symnum / 1000) {
        case 211:
            drawFunction = &draw211;
            info = (void *)CFArrayCreate(NULL, (const void **)cs, 2, NULL);
            pRect = CGRectMake(0.0, 0.0, 45.0, 45.0);
            break;
        case 309:
            drawFunction = &draw309;
            pRect = CGRectMake(0.0, 0.0, 1.0, 50.0);
            break;
        case 310:
            drawFunction = &draw310;
            pRect = CGRectMake(0.0, 0.0, 1.0, 30.0);
            break;
        case 311:
            drawFunction = &draw311;
            pRect = CGRectMake(0.0, 0.0, 115.0, 60.0);
            break;
        case 402:
            drawFunction = &draw402;
            pRect = CGRectMake(0.0, 0.0, 71.0, 71.0);
            break;
        case 404:
            drawFunction = &draw404;
            info = (void *)CFArrayCreate(NULL, (const void **)cs, 2, NULL);
            pRect = CGRectMake(0.0, 0.0, 99.0, 99.0);
            break;
        case 407:
            drawFunction = &draw407or409;
            pRect = CGRectMake(0.0, 0.0, 84.0, 1.0);
            break;
        case 409:
            drawFunction = &draw407or409;
            pRect = CGRectMake(0.0, 0.0, 42.0, 1.0);
            break;
        case 412:
            drawFunction = &draw412;
            info = (void *)CFArrayCreate(NULL, (const void **)cs, 2, NULL);
            pRect = CGRectMake(0.0, 0.0, 80.0, 80.0);
            break;
        case 413:
            drawFunction = &draw413;
            info = (void *)CFArrayCreate(NULL, (const void **)cs, 2, NULL);
            pRect = CGRectMake(0.0, 0.0, 170.0, 190.0);
            break;
        case 415:
            drawFunction = &draw415;
            info = (void *)CFArrayCreate(NULL, (const void **)cs, 2, NULL);
            pRect = CGRectMake(0.0, 0.0, 80.0, 80.0);
            break;
        case 528:
            drawFunction = &draw528;
            pRect = CGRectMake(0.0, 0.0, 75.0, 1.0);
            break;
        case 709:
            drawFunction = &draw709;
            pRect = CGRectMake(0.0, 0.0, 60.0, 1.0);
            break;
        default:/*
            if (a->hatch_mode == 1) {
                if (a->hatch_angle1 == 0
            }*/
            drawFunction = &drawUnknown;
            info = blackColor;
            pRect = CGRectMake(0.0, 0.0, 80.0, 80.0);
            break;
    }
    const CGPatternCallbacks callbacks = {0, drawFunction, NULL};
    pattern = CGPatternCreate(info, pRect, transform, pRect.size.width, pRect.size.height, kCGPatternTilingConstantSpacing, true, &callbacks);
    CGFloat components[1] = {1.0};
    CGColorRef c = CGColorCreateWithPattern(cspace, pattern, components);
    CGColorSpaceRelease(cspace);
    CGPatternRelease(pattern);
    
    return c;
}

- (void)createAreaSymbolColors {
    NSInteger i;
    struct ocad_area_symbol *a;
    NSNumber *key;
    
    if (areaSymbolColors != nil) [areaSymbolColors release];
    areaSymbolColors = [[NSMutableDictionary alloc] initWithCapacity:200];
    
    for (i = 0; i < ocdf->num_symbols; i++) {
        a = (struct ocad_area_symbol *)ocdf->symbols[i];
        if ((enum ocad_object_type)a->otp != ocad_area_object) continue;
        key = [NSNumber numberWithInt:a->symnum];
        CGColorRef c;
        
        if (a->hatch_mode == 0 && a->structure_mode == 0) {
            c = [self colorWithNumber:a->colors[0]];
            CGColorRetain(c);
        } else {
            c = [self areaColorForSymbol:a transform:CGAffineTransformIdentity];
            /*
             NSImage *image = [self patternImageForSymbolNumber: a->symnum / 1000];
             if (image != nil) {
             c = [NSColor colorWithPatternImage:image];
             } else {
             // Parse the color format.
             if (a->hatch_mode == 1 && (a->hatch_angle1 == 900 || a->hatch_angle1 == 0)) {
             // Horizontal or vertical stripes.
             if (a->hatch_angle1 == 900) {
             NSImage *pattern = [[NSImage alloc] initWithSize:NSMakeSize(a->hatch_line_width + a->hatch_dist, 1.0)];
             [pattern lockFocus];
             if (a->fill_enabled) 
             [[self colorWithNumber:a->fill_color] set];
             else
             [[NSColor clearColor] set];
             [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, a->hatch_line_width + a->hatch_dist, 1.0)];
             [[self colorWithNumber:a->hatch_color] set];
             [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, a->hatch_line_width, 1.0)];
             [pattern unlockFocus];
             c = [NSColor colorWithPatternImage:[pattern autorelease]];
             } else {
             NSImage *pattern = [[NSImage alloc] initWithSize:NSMakeSize(1.0, a->hatch_line_width + a->hatch_dist)];
             [pattern lockFocus];
             if (a->fill_enabled) 
             [[self colorWithNumber:a->fill_color] set];
             else
             [[NSColor clearColor] set];
             [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 1.0, a->hatch_line_width + a->hatch_dist)];
             [[self colorWithNumber:a->hatch_color] set];
             [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 1.0, a->hatch_line_width)];
             [pattern unlockFocus];
             c = [NSColor colorWithPatternImage:[pattern autorelease]];
             }
             } else {
             NSSize sz;
             
             // Calculate the size.
             float spacing = a->hatch_line_width + a->hatch_dist;
             
             sz = NSMakeSize(spacing * 2.0 * fabs(cosf(((float)a->hatch_angle1) / 10.0 * pi / 180.0)), 
             spacing * 2.0 * fabs(sinf(((float)a->hatch_angle1) / 10.0 * pi / 180.0)));
             
             if (a->hatch_mode == 2) {
             NSSize sz2;
             
             sz2 = NSMakeSize(spacing * 2.0 * fabs(cosf(((float)a->hatch_angle2) / 10.0 * pi / 180.0)), 
             spacing * 2.0 * fabs(sinf(((float)a->hatch_angle2) / 10.0 * pi / 180.0)));
             
             }
             
             sz = NSMakeSize(roundf(sz.width), roundf(sz.height));
             float side = sz.width;
             NSImage *pattern = [[NSImage alloc] initWithSize:sz];
             [pattern lockFocus];
             if (a->fill_enabled) 
             [[self colorWithNumber:a->fill_color] set];
             else
             [[NSColor clearColor] set];
             [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, side, side)];
             [[self colorWithNumber:a->hatch_color] set];
             int hm, angle, j;
             float f_angle;
             NSPoint baseStart, baseEnd;
             for (hm = a->hatch_mode; hm; hm --) {
             NSBezierPath *path = [NSBezierPath bezierPath];
             angle = *(&(a->hatch_angle1) + (hm - 1));
             f_angle = ((float)angle) / 10.0 * pi / 180.0;
             if (f_angle < 0) {
             baseStart = NSMakePoint(0.0, sz.height);
             baseEnd = NSMakePoint(-tanf(f_angle)*sz.height, 0.0);
             } else {
             baseStart = NSMakePoint(0.0, 0.0);
             baseEnd = NSMakePoint(tanf(f_angle)*sz.height, sz.height);
             
             }
             for (j = -5; j <= 5; j++) {
             [path moveToPoint:NSMakePoint(baseStart.x + cosf(f_angle - pi/2)*spacing * j, baseStart.y + sinf(f_angle - pi/2)*spacing*j)];
             [path lineToPoint:NSMakePoint(baseEnd.x + cosf(f_angle - pi/2)*spacing * j, baseEnd.y + sinf(f_angle - pi/2)*spacing*j)];
             }
             [path setLineWidth:a->hatch_line_width];
             [path stroke];
             }
             [pattern unlockFocus];
             c = [NSColor colorWithPatternImage:[pattern autorelease]];
             }
             }
             */
            
        }
        
        [areaSymbolColors setObject:(id)c forKey:key];
        CGColorRelease(c);
    }
}

@end

// Open sandy ground. 45x45
void draw211 (void * info,CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 0));
    CGContextFillRect(context, CGRectMake(0.0, 0.0, 45.0, 45.0));
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 1));
    CGContextBeginPath(context);
    CGContextAddEllipseInRect(context, CGRectMake(0.0, 0.0, 18.0, 18.0));
    CGContextFillPath(context);
}

// Uncrossable marsh 1x50
void draw309 (void * info,CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)info);
    CGContextFillRect(context, CGRectMake(0.0, 25.0, 1.0, 25.0));
}

// Marsh 1x30
void draw310 (void * info,CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)info);
    CGContextFillRect(context, CGRectMake(0.0, 20.0, 1.0, 10.0));
}

// Indistinct marsh 115x60
void draw311 (void * info,CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)info);
    CGContextFillRect(context, CGRectMake(12.0, 20.0, 90.0, 10.0));
    CGContextFillRect(context, CGRectMake(0.0, 50.0, 45.0, 10.0));
    CGContextFillRect(context, CGRectMake(70.0, 50.0, 45.0, 10.0));
}

// Open land with scattered trees 71x71
void draw402 (void * info,CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)info);
    CGContextBeginPath(context);
    CGContextAddEllipseInRect(context, CGRectMake(-20.0, -20.0, 40.0, 40.0));
    CGContextAddEllipseInRect(context, CGRectMake(51.0, -20.0, 40.0, 40.0));
    CGContextAddEllipseInRect(context, CGRectMake(-20.0, 51.0, 40.0, 40.0));
    CGContextAddEllipseInRect(context, CGRectMake(51.0, 51.0, 40.0, 40.0));
    CGContextAddEllipseInRect(context, CGRectMake(15.0, 15.0, 40.0, 40.0));
    CGContextFillPath(context);
}

// Rough open land with scattered trees 99x99
void draw404 (void * info,CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 0));
    CGContextFillRect(context, CGRectMake(0.0,0.0,99.0,99.0));
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 1));
    CGContextBeginPath(context);
    CGContextAddEllipseInRect(context, CGRectMake(-28.0, -28.0, 55.0, 55.0));
    CGContextAddEllipseInRect(context, CGRectMake(71.0, -28.0, 55.0, 55.0));
    CGContextAddEllipseInRect(context, CGRectMake(-28.0, 71.0, 55.0, 55.0));
    CGContextAddEllipseInRect(context, CGRectMake(71.0, 71.0, 55.0, 55.0));
    CGContextAddEllipseInRect(context, CGRectMake(22.0, 22.0, 55.0, 55.0));
    CGContextFillPath(context);
}

// Undergrowth: slow running 84x1
// Undergrowth: difficult to run 42x1
void draw407or409 (void * info,CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)info);
    CGContextFillRect(context, CGRectMake(0.0,0.0,12.0,1.0));
}

// Orchard 80x80
void draw412 (void * info,CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 0));
    CGContextFillRect(context, CGRectMake(0.0,0.0,80.0,80.0));
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 1));
    CGContextBeginPath(context);
    CGContextAddEllipseInRect(context, CGRectMake(18.0, 18.0, 45.0, 45.0));
    CGContextFillPath(context);
    
}

// Vineyard 170x190
void draw413 (void * info,CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 0));
    CGContextFillRect(context, CGRectMake(0.0,0.0,170.0, 190.0));
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 1));
    CGContextFillRect(context, CGRectMake(0.0, 0.0, 20.0, 65.0));
    CGContextFillRect(context, CGRectMake(0.0, 125.0, 20.0, 65.0));
    CGContextFillRect(context, CGRectMake(85.0, 30.0, 20.0, 130.0));
}

// Cultivated land 80x80
void draw415 (void * info, CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 0));
    CGContextFillRect(context, CGRectMake(0.0,0.0,80.0,80.0));
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 1));
    CGContextBeginPath(context);
    CGContextAddEllipseInRect(context, CGRectMake(30.0, 30.0, 20.0, 20.0));
    CGContextFillPath(context);
}

void drawUnknown( void *info, CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)info);
    CGContextFillRect(context, CGRectMake(0.0,0.0,80.0,80.0));
}

// Permanently out of bounds 75x1
void draw528 (void * info, CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)info);
    CGContextFillRect(context, CGRectMake(0.0,0.0,25.0,1.0));
}

// Out-of-bounds area 60x1
void draw709 (void * info, CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)info);
    CGContextFillRect(context, CGRectMake(0.0,0.0,25.0,1.0));
}
