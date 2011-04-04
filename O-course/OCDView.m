//
//  OCDView.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-02-13.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "OCDView.h"

@implementation OCDView

@synthesize ocdPath=ocd_path;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSLog(@"initialization.");
        // Initialization code here.
        boundingBox = calloc(sizeof(struct LRect), 1);
        
        colors = [NSArray arrayWithObjects:
        /* 0 Svart */           [NSColor blackColor],
        /* 1 Berg i dagen */    [NSColor colorWithCalibratedRed:0.698 green:0.702 blue:0.698 alpha:1.000],
        /* 2 Mindre vatten */   [NSColor colorWithCalibratedRed:0.000 green:0.576 blue:0.773 alpha:1.000],
        /* 3 Vatten */          [NSColor colorWithCalibratedRed:0.537 green:0.745 blue:0.859 alpha:1.000], 
        /* 4 Höjdkurva */       [NSColor colorWithCalibratedRed:0.745 green:0.427 blue:0.180 alpha:1.000],
        /* 5 Asfalt */          [NSColor colorWithCalibratedRed:0.867 green:0.675 blue:0.486 alpha:1.000],
        /* 6 Mkt svårlöpt */    [NSColor colorWithCalibratedRed:0.212 green:0.663 blue:0.345 alpha:1.000], 
        /* 7 Svårlöpt */        [NSColor colorWithCalibratedRed:0.545 green:0.769 blue:0.557 alpha:1.000],
        /* 8 Löphindrande */    [NSColor colorWithCalibratedRed:0.773 green:0.875 blue:0.745 alpha:1.000],
        /* 9 Odlad mark */      [NSColor colorWithCalibratedRed:0.953 green:0.722 blue:0.357 alpha:1.000],
        /* 10 Öppet sandomr. */ [NSColor colorWithCalibratedRed:0.976 green:0.847 blue:0.635 alpha:1.000],
        /* 11 Påtryck */        [NSColor colorWithCalibratedRed:0.835 green:0.102 blue:0.490 alpha:1.000],
        /* 12 Tomtmark */       [NSColor colorWithCalibratedRed:0.631 green:0.616 blue:0.255 alpha:1.000],
        /* 13 Vitt */           [NSColor whiteColor],
        /* 14 Vitt */           [NSColor redColor],
        /* 15 Brown 50 % */     [NSColor colorWithCalibratedRed:0.867 green:0.675 blue:0.486 alpha:1.000],
        /* 16 Reserved % */     [NSColor clearColor],
                  /* 17 Reserved % */     [NSColor clearColor],
                  /* 18 Reserved % */     [NSColor clearColor],
                  /* 19 Reserved % */     [NSColor clearColor],
                  /* 20 Reserved % */     [NSColor clearColor],
                  /* 21 Reserved % */     [NSColor clearColor],
                  /* 22 Reserved % */     [NSColor clearColor],
                  /* 23 Reserved % */     [NSColor clearColor],
                  /* 24 Reserved % */     [NSColor clearColor],
                  /* 25 Reserved % */     [NSColor clearColor],
                  /* 26 Reserved % */     [NSColor clearColor],
                  /* 27 Reserved % */     [NSColor clearColor],
                  /* 28 Reserved % */     [NSColor clearColor],
                  /* 29 Water? */     [NSColor colorWithCalibratedRed:0.537 green:0.745 blue:0.859 alpha:1.000],
                  nil];
        [colors retain];
    }
    
    return self;
}

- (void)awakeFromNib {    
//   self.ocdPath = @"/Users/erik/Documents/Orientering/Kastellegården_ver_1_3_100302.ocd";
    
    self.ocdPath = @"/Users/erik/Documents/Orientering/Bottenstugan_Braseröd_1_2_090123_ocad9.ocd";
//    self.ocdPath = @"/Users/erik/Documents/Orientering/Stor-kungälv_1_06_090426_ocad 9.ocd";
}

- (void)setOcdPath:(NSString *)ocdPath {
    NSString *o = ocd_path;
    ocd_path = [ocdPath retain];
    [o release];
    
    if (ocdf != NULL) {
        free(ocdf);
        ocdf = NULL;
    }
    ocdf = calloc(sizeof(struct ocad_file), 1);
    
    // Load the OCD file.
    load_file(ocdf, [ocd_path cStringUsingEncoding:NSUTF8StringEncoding]);
    load_symbols(ocdf);
    load_objects(ocdf);
    load_strings(ocdf);
    
    get_bounding_box(ocdf, boundingBox);
    currentBox.lower_left.x = boundingBox->lower_left.x;
    currentBox.lower_left.y = boundingBox->lower_left.y;
    currentBox.upper_right.x = boundingBox->upper_right.x;
    currentBox.upper_right.y = boundingBox->upper_right.y;
    
    // Set up a dictionary of color objects, keyed with symbol numbers.
    [self createAreaSymbolColors];
    
    [self setNeedsDisplay:YES];
}

- (NSImage *)patternImageForSymbolNumber:(int)symbol {
    NSImage *i = nil;
    NSBezierPath *p;
   
    switch (symbol) {
        case 815:
            NSLog(@"oops!");
            break;
        case 211: // Open sandy ground
            i = [[NSImage alloc] initWithSize:NSMakeSize(45.0, 45.0)];
            [i lockFocus];
            [[colors objectAtIndex:10] set];
            [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 45.0, 45.0)];
            p = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0, 0, 18.0, 18.0)];
            [[colors objectAtIndex:0] set];
            [p fill];
            break;
        case 309: // Uncrossable marsh
            i = [[NSImage alloc] initWithSize:NSMakeSize(1.0, 50.0)];
            [i lockFocus];
            [[NSColor clearColor] set];
            [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 1.0, 25.0)];
            [[colors objectAtIndex:2] set];
            [NSBezierPath fillRect:NSMakeRect(0.0, 25.0, 1.0, 25.0)];
            break;
        case 310: // Marsh
            i = [[NSImage alloc] initWithSize:NSMakeSize(1.0, 30.0)];
            [i lockFocus];
            [[NSColor clearColor] set];
            [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 1.0, 20.0)];
            [[colors objectAtIndex:2] set];
            [NSBezierPath fillRect:NSMakeRect(0.0, 20.0, 1.0, 10.0)];
            break;
        case 311: // Indistinct marsh
            i = [[NSImage alloc] initWithSize:NSMakeSize(115.0, 60.0)];
            [i lockFocus];
            [[NSColor clearColor] set];
            [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 115.0, 60.0)];
            [[colors objectAtIndex:2] set];
            [NSBezierPath fillRect:NSMakeRect(12.0, 20.0, 90.0, 10.0)];
            [NSBezierPath fillRect:NSMakeRect(0.0, 50.0, 45.0, 10.0)];
            [NSBezierPath fillRect:NSMakeRect(70.0, 50.0, 45.0, 10.0)];
            break;
        case 402: // Open land with scattered trees
            i = [[NSImage alloc] initWithSize:NSMakeSize(71.0, 71.0)];
            [i lockFocus];
            [[colors objectAtIndex:13] set];
            [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 71.0, 71.0)];
            [[colors objectAtIndex:9] set];
            p = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-20.0, -20.0, 40.0, 40.0)];
            [p fill];
            p = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(51.0, -20.0, 40.0, 40.0)];
            [p fill];
            p = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-20.0, 51.0, 40.0, 40.0)];
            [p fill];
            p = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(51.0, 51.0, 40.0, 40.0)];
            [p fill];
            p = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(15.0, 15.0, 40.0, 40.0)];
            [p fill];
            break;
        case 404: // Rough open land with scattered trees
            i = [[NSImage alloc] initWithSize:NSMakeSize(99.0, 99.0)];
            [i lockFocus];
            [[colors objectAtIndex:9] set];
            [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 99.0, 99.0)];
            [[colors objectAtIndex:13] set];
            p = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-28.0, -28.0, 55.0, 55.0)];
            [p fill];
            p = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(71.0, -28.0, 55.0, 55.0)];
            [p fill];
            p = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-28.0, 71.0, 55.0, 55.0)];
            [p fill];
            p = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(71.0, 71.0, 55.0, 55.0)];
            [p fill];
            p = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(22.0, 22.0, 55.0, 55.0)];
            [p fill];
            
            break;
        case 407: // Undergrowth: slow running
            i = [[NSImage alloc] initWithSize:NSMakeSize(84.0, 1.0)];
            [i lockFocus];
            [[NSColor clearColor] set];
            [NSBezierPath fillRect:NSMakeRect(12.0, 0.0, 72.0, 1.0)];
            [[NSColor colorWithCalibratedRed:0.357 green:0.725 blue:0.467 alpha:1.000] set];
            [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 12.0, 1.0)];            
            break;
        case 409: // Undergrowth: difficult to run
            i = [[NSImage alloc] initWithSize:NSMakeSize(42.0, 1.0)];
            [i lockFocus];
            [[NSColor clearColor] set];
            [NSBezierPath fillRect:NSMakeRect(12.0, 0.0, 30.0, 1.0)];
            [[NSColor colorWithCalibratedRed:0.357 green:0.725 blue:0.467 alpha:1.000] set];
            [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 12.0, 1.0)];            
            break;        
        case 412: // Orchard
            i = [[NSImage alloc] initWithSize:NSMakeSize(80.0, 80.0)];
            [i lockFocus];
            [[colors objectAtIndex:9] set];
            [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 80.0, 80.0)];
            [[colors objectAtIndex:6] set];
            p = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(18.0, 18.0, 45.0, 45.0)];
            [p fill];
            break;
        case 413: // Vineyard
            i = [[NSImage alloc] initWithSize:NSMakeSize(170.0, 190.0)];
            [i lockFocus];
            [[colors objectAtIndex:9] set];
            [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 170.0, 190.0)];
            [[colors objectAtIndex:6] set];
            [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 20.0, 65.0)];
            [NSBezierPath fillRect:NSMakeRect(0.0, 125.0, 20.0, 65.0)];
            [NSBezierPath fillRect:NSMakeRect(85.0, 30.0, 20.0, 130.0)];
            break;
        case 415: // Cultivated land
            i = [[NSImage alloc] initWithSize:NSMakeSize(80.0, 80.0)];
            [i lockFocus];
            [[colors objectAtIndex:9] set];
            [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 80.0, 80.0)];
            [[colors objectAtIndex:0] set];
            p = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(30.0, 30.0, 20.0, 20.0)];
            [p fill];
            
            break;
        case 528: // Permanently out of bounds
            i = [[NSImage alloc] initWithSize:NSMakeSize(75.0, 1.0)];
            [i lockFocus];
            [[NSColor clearColor] set];
            [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 75.0, 1.0)];
            [[colors objectAtIndex:0] set];
            [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 25.0, 1.0)];            
            break;    
        case 709: // Out-of-bounds area
            i = [[NSImage alloc] initWithSize:NSMakeSize(60.0, 1.0)];
            [i lockFocus];
            [[NSColor clearColor] set];
            [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 60.0, 1.0)];
            [[colors objectAtIndex:11] set];
            [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 25.0, 1.0)];            
            break;    
        default:
            NSLog(@"No definition for symbol %d", symbol);
            break;
    }
    
    [i unlockFocus];
    return [i autorelease];
}



- (void)dealloc
{
    [ocd_path release];
    if (ocdf != NULL) free(ocdf);
    if (boundingBox != NULL) free(ocdf);
    
    [super dealloc];
}

- (void)setColorWithNumber:(int)color_number {
    if (color_number < [colors count]) {
        [[colors objectAtIndex:color_number] set];
    } else {
        [[NSColor blackColor] set];
    }
}

- (NSAffineTransform *)currentTransform {
    
    NSRect frame = [self bounds];

    NSAffineTransformStruct ts;
	ts.m12 = 0.0; ts.m21 = 0.0;
    float scale = NSWidth(frame)/ ((currentBox.upper_right.x >> 8) - (currentBox.lower_left.x >> 8));
	ts.m11 = scale; ts.m22 = scale;
	ts.tX = frame.origin.x - (currentBox.lower_left.x >> 8)*scale;
	ts.tY = frame.origin.y - (currentBox.lower_left.y >> 8)*scale;
	
	NSAffineTransform *t = [NSAffineTransform transform];
	[t setTransformStruct:ts];
    
    return t;
}


- (void)mouseDown:(NSEvent *)theEvent {
    NSAffineTransform *t = [self currentTransform];
    [t invert];
    mouseDownPoint = [t transformPoint:[self convertPointFromBase:[theEvent locationInWindow]]];
}
- (void)mouseUp:(NSEvent *)theEvent {
    NSAffineTransform *t = [self currentTransform];
    [t invert];
    
    NSPoint mouseUpPoint = [t transformPoint:[self convertPointFromBase:[theEvent locationInWindow]]];
    
    currentBox.lower_left.x = (int32_t)(fmin(mouseDownPoint.x, mouseUpPoint.x))  << 8;
    currentBox.lower_left.y = (int32_t)(fmin(mouseDownPoint.y, mouseUpPoint.y))  << 8;
    currentBox.upper_right.x = (int32_t)(fmax(mouseDownPoint.x, mouseUpPoint.x))  << 8;
    currentBox.upper_right.y = (int32_t)(fmax(mouseDownPoint.y, mouseUpPoint.y))  << 8;
    
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    int i;
    struct ocad_element *e;
    struct ocad_object_index *o;
    enum ocad_object_type type;
    
    [[NSColor whiteColor] set];
    if ([[NSGraphicsContext currentContext] isDrawingToScreen]) {
        [NSBezierPath fillRect:dirtyRect];
    }
    
    if (ocdf == NULL) return;

    [NSGraphicsContext saveGraphicsState];
    
	[[self currentTransform] concat];
    
    // Draw areas.    
    for (i = 0; i < ocdf->num_objects; i++) {
        e = ocdf->elements[i];
        o = ocdf->objects[i];
        if (o->status != 1) continue;
        type = (enum ocad_object_type)(e->obj_type);
        if (type == ocad_area_object) {
            struct ocad_area_symbol *area = (struct ocad_area_symbol *)(e->symbol);
            if (area && area->fill_enabled && area->fill_color) {
                [self drawOcadAreaObject:e];
            }
        }
    }
    
    // Draw lines.
    for (i = 0; i < ocdf->num_objects; i++) {
        e = ocdf->elements[i];
        //if (e->reserved0) continue;

        o = ocdf->objects[i];
        if (o->status != 1) continue;
        type = (enum ocad_object_type)(e->obj_type);

        if (type == ocad_line_object) {
            struct ocad_line_symbol *line = (struct ocad_line_symbol *)(e->symbol);
            if (line && line->line_color) {
                [self drawOcadLineObject:e];
            }
        }
    }
    
    // Draw rectangles.
    for (i = 0; i < ocdf->num_objects; i++) {
        e = ocdf->elements[i];
        o = ocdf->objects[i];
        if (o->status != 1) continue;
        type = (enum ocad_object_type)(e->obj_type);
        if (type == ocad_rectangle_object) [self drawOcadRectangleObject:e];
    }
    
    // Draw black areas (typically houses).
    for (i = 0; i < ocdf->num_objects; i++) {
        e = ocdf->elements[i];        
        o = ocdf->objects[i];
        if (o->status != 1) continue;
        type = (enum ocad_object_type)(e->obj_type);
        if (type == ocad_area_object) {
            struct ocad_area_symbol *area = (struct ocad_area_symbol *)(e->symbol);
            if (area == NULL || (!area->fill_enabled || (area->fill_color == 0))) {
                [self drawOcadAreaObject:e];
            }
        }
    }
    
    // Draw black lines.
    for (i = 0; i < ocdf->num_objects; i++) {
        e = ocdf->elements[i];
        //if (e->reserved0) continue;
        
        o = ocdf->objects[i];
        if (o->status != 1) continue;
        type = (enum ocad_object_type)(e->obj_type);
        
        if (type == ocad_line_object) {
            struct ocad_line_symbol *line = (struct ocad_line_symbol *)(e->symbol);
            if (line && !line->line_color) {
                [self drawOcadLineObject:e];
            }
        }
    }
    
    // Draw points
    for (i = 0; i < ocdf->num_objects; i++) {
        e = ocdf->elements[i];
        o = ocdf->objects[i];
        if (o->status != 1) continue;
        type = (enum ocad_object_type)(e->obj_type);
        if (type == ocad_point_object) [self drawOcadPointObject:e];
    }
    
    [NSGraphicsContext restoreGraphicsState];
    
}

- (void)drawOcadPointObject:(struct ocad_element *)e {
    struct ocad_point_symbol *point = (struct ocad_point_symbol *)(e->symbol);
    
    if (point == NULL || point->status == 2) return;

    
    float angle = 0.0;
    if (e->angle != -1) angle = ((float)(e->angle)) / 10.0;
    [self drawSymbolElements:(struct ocad_symbol_element *)(point->points) 
                     atPoint:NSMakePoint(e->coords[0].x >> 8, e->coords[0].y >> 8) 
                   withAngle:angle 
               totalDataSize:point->datasize];
}

- (void)drawOcadRectangleObject:(struct ocad_element *)e {
    struct ocad_rectangle_symbol *rect = (struct ocad_rectangle_symbol *)(e->symbol);
    int c;
    
    if (e->nCoordinates == 0 ||
        rect == NULL ||
        rect->status == 2 /* Hidden */) {
        return;
    }
    
    NSBezierPath *p = [NSBezierPath bezierPath];

    [p moveToPoint:NSMakePoint(e->coords[0].x >> 8, e->coords[0].y >> 8)];
    
    for (c = 0; c < e->nCoordinates; c++) {
        [p lineToPoint:NSMakePoint(e->coords[c].x >> 8, e->coords[c].y >> 8)];
    }
    [p closePath];

    [self setColorWithNumber:rect->colors[0]];
    
    if (rect->line_width != 0) {
        [p setLineWidth:rect->line_width];
        [p stroke];
    } else {
        [p fill];
    }
    
}

- (void)drawOcadLineObject:(struct ocad_element *)e {
    struct ocad_line_symbol *line = (struct ocad_line_symbol *)(e->symbol);
    int c;
    NSBezierPath *p = [NSBezierPath bezierPath];
    
    if (e->nCoordinates == 0 || (line != NULL && line->status == 2 /* Hidden */)) {
        return;
    }
    
    if (line != NULL && (line->dbl_width != 0)) {
        NSBezierPath *left, *right, *road;
        left = [NSBezierPath bezierPath];
        right = [NSBezierPath bezierPath];
        road = [NSBezierPath bezierPath];
        [left setLineWidth:line->dbl_left_width];
        [right setLineWidth:line->dbl_right_width];
        [left setLineCapStyle:NSSquareLineCapStyle];
        [right setLineCapStyle:NSSquareLineCapStyle];
        
        [road setLineWidth:line->dbl_width + line->dbl_left_width*0.5 + line->dbl_right_width*0.5];
        [road setWindingRule:NSEvenOddWindingRule];
        NSPoint p0 = NSMakePoint(e->coords[0].x >> 8, e->coords[0].y >> 8);
        [road moveToPoint:p0];
        
        // For each point
        BOOL angleSet = NO;
        float angle = 0.0, thisAngle, nextangle;
        float *angles = calloc(sizeof(float), e->nCoordinates), *currentAngle = angles;
        for (c = 1; c < e->nCoordinates; c++) {
            NSPoint p1 = NSMakePoint(e->coords[c].x >> 8, e->coords[c].y >> 8);
            NSPoint p2 = NSMakePoint(e->coords[c + 1].x >> 8, e->coords[c + 1].y >> 8);
            NSPoint p3 = NSMakePoint(e->coords[c+2].x >> 8, e->coords[c+2].y >> 8);
            
            thisAngle = [[self class] angleBetweenPoint:p1 andPoint:p0];      
            if (angleSet) {
                angle = (thisAngle + angle)*0.5; 
            } else {
                angleSet = YES;
                angle = thisAngle;
            }
            *currentAngle = angle;
            currentAngle ++;
            
            if (e->coords[c].x & 1) {
                // Bezier curve.
                [road curveToPoint:p3 controlPoint1:p1 controlPoint2:p2];
                c += 2;
                p0 = p2; angleSet = NO;
            } else {
                p0 = p1;
                [road lineToPoint:p1];
            }

        }

        // Get the angle to the next normal point. 
        // Translate the point half the width to each side.
        // Create the path to the next point in the normal manner.
        // Be sure to watch for gaps in the left / right lines.
        
        currentAngle = angles;
        [left moveToPoint:[[self class] translatePoint:NSMakePoint(e->coords[0].x >> 8, e->coords[0].y >> 8) distance:(line->dbl_width) angle:(*currentAngle + pi/2)]];
        [right moveToPoint:[[self class] translatePoint:NSMakePoint(e->coords[0].x >> 8, e->coords[0].y >> 8) distance:(line->dbl_width) angle:(*currentAngle - pi/2)]];

        for (c = 1; c < e->nCoordinates; c++) {
            angle = *currentAngle;
            currentAngle++;

            NSPoint p1 = NSMakePoint(e->coords[c].x >> 8, e->coords[c].y >> 8);
            NSPoint p2 = NSMakePoint(e->coords[c + 1].x >> 8, e->coords[c + 1].y >> 8);
            NSPoint p3 = NSMakePoint(e->coords[c+2].x >> 8, e->coords[c+2].y >> 8);
            NSPoint p1l, p2l, p3l, p1r, p2r, p3r;
            p1l = [[self class] translatePoint:p1 distance:(line->dbl_width) angle:(angle + pi/2)];
            p1r = [[self class] translatePoint:p1 distance:(line->dbl_width) angle:(angle - pi/2)];
            
            if (e->coords[c].x & 1) {
                nextangle = *currentAngle;
                // Bezier curve.
                p2l = [[self class] translatePoint:p2 distance:(line->dbl_width) angle:(nextangle + pi/2)];
                p3l = [[self class] translatePoint:p3 distance:(line->dbl_width) angle:(nextangle + pi/2)];
                p2r = [[self class] translatePoint:p2 distance:(line->dbl_width) angle:(nextangle - pi/2)];
                p3r = [[self class] translatePoint:p3 distance:(line->dbl_width) angle:(nextangle - pi/2)];
                
                [left curveToPoint:p3l controlPoint1:p1l controlPoint2:p2l];
                [right curveToPoint:p3r controlPoint1:p1r controlPoint2:p2r];
                c += 2;
                
            } else {
                if (e->coords[c].x & 4) [left moveToPoint:p1l]; else [left lineToPoint:p1l];
                if (e->coords[c].y & 4) [right moveToPoint:p1r]; else [right lineToPoint:p1r];
            }
        }
        free(angles);
        
        [self setColorWithNumber:line->dbl_fill_color];
        [road stroke];
        
        [self setColorWithNumber:line->dbl_left_color];
        [left stroke];
        [self setColorWithNumber:line->dbl_right_color];
        [right stroke];
    }
    
    if (e->linewidth != 0 || (line != NULL && line->line_width != 0)) {
        [p setWindingRule:NSEvenOddWindingRule];
        [p moveToPoint:NSMakePoint(e->coords[0].x >> 8, e->coords[0].y >> 8)];
        
        for (c = 0; c < e->nCoordinates; c++) {
            if (e->coords[c].x & 1) {
                // Bezier curve.
                [p curveToPoint:NSMakePoint(e->coords[c+2].x >> 8, e->coords[c+2].y >> 8) 
                  controlPoint1:NSMakePoint(e->coords[c].x >> 8, e->coords[c].y >> 8) 
                  controlPoint2:NSMakePoint(e->coords[c+1].x >> 8, e->coords[c+1].y >> 8)];
                
                c += 2;
                
            } else {
                [p lineToPoint:NSMakePoint(e->coords[c].x >> 8, e->coords[c].y >> 8)];
            }
            
            if (e->coords[c].y & 1 && line != NULL && line->corner_d_size != 0) {
                struct ocad_symbol_element *se = (struct ocad_symbol_element *)(line->coords + line->prim_d_size + line->sec_d_size);
                
                float angle = [OCDView angleForCoords:e->coords ofLength:e->nCoordinates atIndex:c];
                [self drawSymbolElements:se atPoint:NSMakePoint(e->coords[c].x >> 8, e->coords[c].y >> 8) withAngle:angle totalDataSize:(se->ncoords + 2)];
            }
        }
        if (line != NULL && line->line_color < [colors count]) 
            [[colors objectAtIndex:line->line_color] set];
        else if (e->color < [colors count])
            [[colors objectAtIndex:e->color] set];
        else
            [[NSColor blackColor] set];
        
        if (line != NULL && line->main_length != 0) {
            CGFloat dashes[4];
            int num_dashes = 2;
            dashes[0] = line->main_length;
            dashes[1] = line->main_gap;
            if (line->sec_gap > 0) {
                num_dashes += 2;
                dashes[2] = line->main_length;
                dashes[3] = line->sec_gap;
            }
            [p setLineDash:dashes count:num_dashes phase:0];
        }

        if (line != NULL) {
            [p setLineWidth:(CGFloat)(line->line_width)];
            switch (line->line_style) {
                case 0:
                    [p setLineJoinStyle:NSBevelLineJoinStyle];
                    [p setLineCapStyle:NSButtLineCapStyle];
                    break;
                case 1:
                    [p setLineJoinStyle:NSRoundLineJoinStyle];
                    [p setLineCapStyle:NSRoundLineCapStyle];
                    break;
                case 2:
                    [p setLineJoinStyle:NSMiterLineJoinStyle];
                    [p setLineCapStyle:NSButtLineCapStyle];
                    break;
            };
        } else {
            [p setLineWidth:(CGFloat)(e->linewidth)];        
        }
        [p stroke];
    }
    if (line != NULL && line->prim_d_size) {
        float phase = (float)line->end_length;
        float interval = (float)line->main_length;
        float distance = -phase;
        float angle;
        float x, y, xp, yp;
        int nprim_syms = 0;

        for (c = 0; c < e->nCoordinates - 1; c++) {
            x = (float)(e->coords[c].x >> 8);
            y = (float)(e->coords[c].y >> 8);
            
            if (e->coords[c + 1].x & 1) {
                // Track the bezier curve to find places to put symbols.
                
                float t;
                float x2, y2;
                float xp0, yp0;
                float xb1, yb1, xb2, yb2;
                
                x2 = (float)(e->coords[c + 3].x >> 8);
                y2 = (float)(e->coords[c + 3].y >> 8);
                xb2 = (float)(e->coords[c + 2].x >> 8);
                yb2 = (float)(e->coords[c + 2].y >> 8);
                xb1 = (float)(e->coords[c + 1].x >> 8);
                yb1 = (float)(e->coords[c + 1].y >> 8);
                
                yp0 = y; xp0 = x;
                for (t = 0.025; t < 1.0; t+= 0.025) {
                    xp = powf(1.0-t, 3)*x + 3.0 * powf(1.0-t, 2.0) * t * xb1 + 3.0*(1.0-t)*t*t*xb2 + t*t*t*x2;
                    yp = powf(1.0-t, 3)*y + 3.0 * powf(1.0-t, 2.0) * t * yb1 + 3.0*(1.0-t)*t*t*yb2 + t*t*t*y2;
                    distance += sqrtf((xp - xp0)*(xp - xp0) + (yp - yp0)*(yp - yp0));
                    if (distance > nprim_syms*interval) {
                        angle = [[self class] angleBetweenPoint:NSMakePoint(xp0, yp0) andPoint:NSMakePoint(xp, yp)];
                        [self drawSymbolElements:(struct ocad_symbol_element *)line->coords
                                        atPoint:NSMakePoint(xp, yp)
                                      withAngle:angle
                                   totalDataSize:0];
                        nprim_syms ++;
                    }
                    xp0 = xp; yp0 = yp;
                }
                c += 2;
            } else {
                float x2, y2;
                float segment_distance, initial_distance = distance;
                BOOL space_left = YES;
                x2 = (float)(e->coords[c + 1].x >> 8);
                y2 = (float)(e->coords[c + 1].y >> 8);
                segment_distance = sqrtf((x2-x)*(x2-x) + (y2-y)*(y2-y));

                while (space_left) {
                    distance += nprim_syms * interval - distance;
                    if (distance < initial_distance + segment_distance) {
                        // Ok, it fit
                        nprim_syms ++;                        
                        angle = [OCDView angleBetweenPoint:NSMakePoint(x, y) andPoint:NSMakePoint(x2, y2)];
                        [self drawSymbolElements:(struct ocad_symbol_element *)line->coords 
                                         atPoint:NSMakePoint(x + cos(angle)*(distance - initial_distance), y + sin(angle)*(distance - initial_distance)) 
                                       withAngle:angle
                                   totalDataSize:0];
                    } else {
                        space_left = NO;
                        distance = initial_distance + segment_distance;
                    }
                }
            }
        }
    }

}



@end
