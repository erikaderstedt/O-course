//
//  ASOCADController.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-02.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASOCADController.h"
#import "ocdimport.h"

#define PARALLELIZATION 2
#define CONCURRENCY (1 << PARALLELIZATION)

@implementation ASOCADController


- (id)initWithOCADFile:(NSString *)path {
	// Load the ocad file.
	// Go through each type of object and get the resulting paths.
	// Add them to the cache
	// Cache contains:
	// 		path - NSBezierPath
	//		fillcolor - NSColor
	//		strokecolor - NSColor
	//		symbol - NSNumber (NSInteger)
	//		angle - NSNumber (float)
    if ((self = [super init])) {
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
                  /* 25 Roads  */		  [NSColor blackColor],
                  /* 26 Reserved % */     [NSColor clearColor],
                  /* 27 Reserved % */     [NSColor clearColor],
                  /* 28 Reserved % */     [NSColor clearColor],
                  /* 29 Water? */     [NSColor colorWithCalibratedRed:0.537 green:0.745 blue:0.859 alpha:1.000],
                  nil];
        [colors retain];

        if (ocdf != NULL) {
            free(ocdf);
            ocdf = NULL;
        }
        ocdf = calloc(sizeof(struct ocad_file), 1);
        
        // Load the OCD file.
        load_file(ocdf, [path cStringUsingEncoding:NSUTF8StringEncoding]);
        load_symbols(ocdf);
        load_objects(ocdf);
        load_strings(ocdf);
        
        boundingBox = calloc(sizeof(struct LRect), 1);
        get_bounding_box(ocdf, boundingBox);
        currentBox.lower_left.x = boundingBox->lower_left.x;
        currentBox.lower_left.y = boundingBox->lower_left.y;
        currentBox.upper_right.x = boundingBox->upper_right.x;
        currentBox.upper_right.y = boundingBox->upper_right.y;
        
        // Set up a dictionary of color objects, keyed with symbol numbers.
        [self createAreaSymbolColors];

        [self createCache];
    }
    return self;
}

- (NSPoint)approximateCenterOfMap {
	NSInteger x;
	NSDictionary *cachedData;
	NSBezierPath *thePath;
	double randomIndex;
	NSRect pathBounds;
	NSRect wholeMap = NSZeroRect;
	
	if ([cachedDrawingInformation count] == 0) return NSMakePoint(0.0, 0.0);
	
	for (x = 0; x < 10; x++) {
		randomIndex = ((double)([cachedDrawingInformation count] - 1)) * random() / RAND_MAX;
		cachedData = [cachedDrawingInformation objectAtIndex:((NSInteger)randomIndex)];
		thePath = [cachedData objectForKey:@"path"];
		if (thePath != nil) {
			pathBounds = [thePath bounds];
			wholeMap = NSUnionRect(wholeMap, pathBounds);
		}
	}
	return NSMakePoint(NSMidX(wholeMap), NSMidY(wholeMap));
}

- (NSRect)mapBounds {
	NSBezierPath *thePath;
	NSRect pathBounds;
	NSRect wholeMap = NSZeroRect;
	
	if ([cachedDrawingInformation count] == 0) return NSZeroRect;
	
	for (NSDictionary *cachedData in cachedDrawingInformation) {
		thePath = [cachedData objectForKey:@"path"];
		if (thePath != nil) {
			pathBounds = [thePath bounds];
			wholeMap = NSUnionRect(wholeMap, pathBounds);
		}
	}
	return wholeMap;
}

- (NSImage *)renderedMapWithImageSize:(NSSize)sz atPoint:(CGPoint)point {
	// Create an image of the appropriate size.
	NSLog(@"begin rendering");
	NSImage *destinationImage = [[NSImage alloc] initWithSize:sz];
	[destinationImage lockFocus];
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:NSMakeRect(0.0, 0.0, sz.width, sz.height)];
	
    // Render in CONCURRENCY different images, and then composite them on top of each other.
	// Set up a transform.
	NSAffineTransform *at = [NSAffineTransform transform];
	
	NSRect q = [self mapBounds];
    NSAffineTransformStruct ts;
	ts.m12 = 0.0; ts.m21 = 0.0;
    float scale = sz.width/ NSWidth(q);
	ts.m11 = scale; ts.m22 = scale;
	ts.tX = - NSMinX(q)*scale;
	ts.tY = - NSMinY(q)*scale;
	
	NSAffineTransform *t = [NSAffineTransform transform];
	[at setTransformStruct:ts];
	[at concat];
	
	// Draw into the image.
	for (NSDictionary *info in cachedDrawingInformation) {
		NSBezierPath *path = [info valueForKey:@"path"];
		NSColor *stroke = [info valueForKey:@"strokeColor"];
		NSColor *fill = [info valueForKey:@"fillColor"];
			
		if (fill != nil) {
			[fill set];
			[path fill];
		}
		if (stroke != nil) {
			[stroke set];
			[path stroke];
		}
		
	}
	[destinationImage unlockFocus];
	NSLog(@"end rendering");
	return [destinationImage autorelease];
}

- (NSInteger)symbolNumberAtPosition:(CGPoint)p {
	NSEnumerator *cacheEnumerator = [cachedDrawingInformation reverseObjectEnumerator];
	NSDictionary *info;
	while ((info = [cacheEnumerator nextObject])) {
		NSBezierPath *path = [info valueForKey:@"path"];
		if ([path containsPoint:NSPointFromCGPoint(p)]) 
			return [[info valueForKey:@"symbol"] integerValue];
	}
	
	return 0;
}

- (NSArray *)createCacheFromIndex:(NSInteger)start upToButNotIncludingIndex:(NSInteger)stop {
    NSMutableArray *nonBlackAreas = [NSMutableArray arrayWithCapacity:100];
    NSMutableArray *lines = [NSMutableArray arrayWithCapacity:10000];
    NSMutableArray *roads = [NSMutableArray arrayWithCapacity:100];
    NSMutableArray *rectangles = [NSMutableArray arrayWithCapacity:100];
    NSMutableArray *blackAreas = [NSMutableArray arrayWithCapacity:100];
    NSMutableArray *pointObjects = [NSMutableArray arrayWithCapacity:10000];
    
    NSInteger i;
    struct ocad_element *e;
    struct ocad_object_index *o;
    enum ocad_object_type type;
	NSArray *a;
	struct ocad_area_symbol *area;
    
    for (i = start; i < stop; i++) {
        e = ocdf->elements[i];
        o = ocdf->objects[i];
        if (o->status != 1) continue;
        type = (enum ocad_object_type)(e->obj_type);
		switch (type) {
			case ocad_area_object:
				area = (struct ocad_area_symbol *)(e->symbol);
				if (area && area->fill_enabled && area->fill_color) {
					[nonBlackAreas addObject:[self cachedDrawingInfoForAreaObject:e]];
				}
				if (area == NULL || (!area->fill_enabled || (area->fill_color == 0))) {
					[blackAreas addObject:[self cachedDrawingInfoForAreaObject:e]];
				}
				break;
			case ocad_line_object:
				a = [self cachedDrawingInfoForLineObject:e];
				if ([a count] == 2)
					[roads addObject:[a objectAtIndex:1]];
				if ([a count] > 0)
					[lines addObjectsFromArray:[a objectAtIndex:0]];
				break;
			case ocad_rectangle_object:
				[rectangles addObject:[self cachedDrawingInfoForRectangleObject:e]];
				break;
			case ocad_point_object:
				[pointObjects addObjectsFromArray:[self cachedDrawingInfoForPointObject:e]];
				break;
			default:
				break;
		}

    }
	NSLog(@"%d roads", [roads count]);
    [lines addObjectsFromArray:roads];

    return [NSArray arrayWithObjects:nonBlackAreas, lines, rectangles, blackAreas, pointObjects, nil];
}

- (void)createCache {

    if (ocdf == NULL) {
        if (cachedDrawingInformation != nil) {
            [cachedDrawingInformation release];
            cachedDrawingInformation = nil;
        }
        return;
    }
	NSLog(@"begin caching");
    NSMutableArray *invocations = [NSMutableArray arrayWithCapacity:4];
    NSMethodSignature *ms = [self methodSignatureForSelector:@selector(createCacheFromIndex:upToButNotIncludingIndex:)];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:CONCURRENCY];
    
    NSInteger i, num = ocdf->num_objects, start = 0, stop;
    for (i = 0; i < CONCURRENCY; i++) {
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:ms];
        [inv setTarget:self];
        [inv setSelector:@selector(createCacheFromIndex:upToButNotIncludingIndex:)];
        start = i * (num >> PARALLELIZATION); //start = 0;
        stop = (i != (CONCURRENCY - 1))?((i+1)*(num >> PARALLELIZATION)):num;// stop = num;
        [inv setArgument:&start atIndex:2];
        [inv setArgument:&stop atIndex:3];
        NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithInvocation:inv];
        [invocations addObject:op];
        [queue addOperation:op];
    }
    
    if (cachedDrawingInformation != nil) {
        [cachedDrawingInformation removeAllObjects];
    } else {
        cachedDrawingInformation = [NSMutableArray arrayWithCapacity:10000];
    }
    
    [queue waitUntilAllOperationsAreFinished];
    for (i = 0; i < 5; i++) {
        for (NSInvocationOperation *op in invocations) {
            [cachedDrawingInformation addObjectsFromArray:[[op result] objectAtIndex:i]];
        }
    }
    for (NSInvocationOperation *op in invocations) {
        [op release];
    }
    [queue release];
	[cachedDrawingInformation retain];
	NSLog(@"Cached %d paths.", [cachedDrawingInformation count]);
}

- (NSDictionary *)cachedDrawingInfoForAreaObject:(struct ocad_element *)e {
    struct ocad_area_symbol *area = (struct ocad_area_symbol *)(e->symbol);
    int c;
    
    if (e->nCoordinates == 0 ||
        area == NULL ||
        area->status == 2 /* Hidden */)
        return nil;
    
    NSBezierPath *p = [NSBezierPath bezierPath];
    [p setWindingRule:NSEvenOddWindingRule];
    [p moveToPoint:NSMakePoint(e->coords[0].x >> 8, e->coords[0].y >> 8)];
    
    for (c = 0; c < e->nCoordinates; c++) {
        if (e->coords[c].x & 1) {
            // Bezier curve.
            [p curveToPoint:NSMakePoint(e->coords[c+2].x >> 8, e->coords[c+2].y >> 8) 
              controlPoint1:NSMakePoint(e->coords[c].x >> 8, e->coords[c].y >> 8) 
              controlPoint2:NSMakePoint(e->coords[c+1].x >> 8, e->coords[c+1].y >> 8)];
            
            c += 2;
            
        } else      if (e->coords[c].y & 2) {
            [p closePath];
            [p moveToPoint:NSMakePoint(e->coords[c].x >> 8, e->coords[c].y >> 8)];
        }
        else {
            [p lineToPoint:NSMakePoint(e->coords[c].x >> 8, e->coords[c].y >> 8)];
        }
    }
    NSColor *color = [areaSymbolColors objectForKey:[NSNumber numberWithInt:area->symnum]];
    return [NSDictionary dictionaryWithObjectsAndKeys:color, @"fillColor", p, @"path", nil];
}

- (NSArray *)cachedDrawingInfoForPointObject:(struct ocad_element *)e {
    struct ocad_point_symbol *point = (struct ocad_point_symbol *)(e->symbol);
    
    if (point == NULL || point->status == 2) return [NSArray array];
    
    
    float angle = 0.0;
    if (e->angle != -1) angle = ((float)(e->angle)) / 10.0;
    return [self cacheSymbolElements:(struct ocad_symbol_element *)(point->points) 
                             atPoint:NSMakePoint(e->coords[0].x >> 8, e->coords[0].y >> 8) 
                           withAngle:angle 
                       totalDataSize:point->datasize];
}

- (NSDictionary *)cachedDrawingInfoForRectangleObject:(struct ocad_element *)e {
    struct ocad_rectangle_symbol *rect = (struct ocad_rectangle_symbol *)(e->symbol);
    int c;
    
    if (e->nCoordinates == 0 ||
        rect == NULL ||
        rect->status == 2 /* Hidden */) {
        return nil;
    }
    
    NSBezierPath *p = [NSBezierPath bezierPath];
    
    [p moveToPoint:NSMakePoint(e->coords[0].x >> 8, e->coords[0].y >> 8)];
    
    for (c = 0; c < e->nCoordinates; c++) {
        [p lineToPoint:NSMakePoint(e->coords[c].x >> 8, e->coords[c].y >> 8)];
    }
    [p closePath];
    
    NSColor *color = [self colorWithNumber:rect->colors[0]];
    
    if (rect->line_width != 0) {
        [p setLineWidth:rect->line_width];
        return [NSDictionary dictionaryWithObjectsAndKeys:color,@"strokeColor",p, @"path", nil];
    } 
    
    return [NSDictionary dictionaryWithObjectsAndKeys:color, @"fillColor", p, @"path", nil];    
}

- (NSArray *)cachedDrawingInfoForLineObject:(struct ocad_element *)e {
    struct ocad_line_symbol *line = (struct ocad_line_symbol *)(e->symbol);
    int c;
    NSBezierPath *p = [NSBezierPath bezierPath];
    NSDictionary *roadCache = nil;
    NSMutableArray *cachedData = [NSMutableArray arrayWithCapacity:10];
    
    if (e->nCoordinates == 0 || (line != NULL && line->status == 2 /* Hidden */)) {
        return [NSArray array];
    }
    
    if (line != NULL && (line->dbl_width != 0)) {
        NSBezierPath *left = nil, *right = nil, *road = nil;
        left = [NSBezierPath bezierPath];
        right = [NSBezierPath bezierPath];
        road = [NSBezierPath bezierPath];
        [left setLineWidth:line->dbl_left_width];
        [right setLineWidth:line->dbl_right_width];
        [left setLineCapStyle:NSSquareLineCapStyle];
        [right setLineCapStyle:NSSquareLineCapStyle];
        
        [road setLineWidth:line->dbl_width/* + line->dbl_left_width*0.5 + line->dbl_right_width*0.5*/];
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
        
        roadCache = [NSDictionary dictionaryWithObjectsAndKeys:[self colorWithNumber:line->dbl_fill_color], @"strokeColor", road, @"path", nil];
        [cachedData addObject:[NSDictionary dictionaryWithObjectsAndKeys:[self colorWithNumber:line->dbl_left_color], @"strokeColor", left, @"path", nil]];
        [cachedData addObject:[NSDictionary dictionaryWithObjectsAndKeys:[self colorWithNumber:line->dbl_right_color], @"strokeColor", right, @"path", nil]];
		NSLog(@"%d, %@", line->dbl_right_color, [self colorWithNumber:line->dbl_right_color]);
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
                
                float angle = [[self class] angleForCoords:e->coords ofLength:e->nCoordinates atIndex:c];
                [cachedData addObjectsFromArray:[self cacheSymbolElements:se atPoint:NSMakePoint(e->coords[c].x >> 8, e->coords[c].y >> 8) withAngle:angle totalDataSize:(se->ncoords + 2)]];
            }
        }
        NSColor *mainColor;
        if (line != NULL && line->line_color < [colors count]) 
            mainColor = [colors objectAtIndex:line->line_color];
        else if (e->color < [colors count])
            mainColor = [colors objectAtIndex:e->color];
        else
            mainColor = [NSColor blackColor];
        
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
        [cachedData addObject:[NSDictionary dictionaryWithObjectsAndKeys:mainColor, @"strokeColor", p, @"path", nil]];
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
                        [cachedData addObjectsFromArray:[self cacheSymbolElements:(struct ocad_symbol_element *)line->coords 
                                                                          atPoint:NSMakePoint(xp, yp) 
                                                                        withAngle:angle 
                                                                    totalDataSize:0]];
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
                        angle = [[self class] angleBetweenPoint:NSMakePoint(x, y) andPoint:NSMakePoint(x2, y2)];
                        [cachedData addObjectsFromArray:[self cacheSymbolElements:(struct ocad_symbol_element *)line->coords 
                                                                          atPoint:NSMakePoint(x + cos(angle)*(distance - initial_distance), y + sin(angle)*(distance - initial_distance)) 
                                                                        withAngle:angle 
                                                                    totalDataSize:0]];

                    } else {
                        space_left = NO;
                        distance = initial_distance + segment_distance;
                    }
                }
            }
        }
    }
    return [NSArray arrayWithObjects:cachedData, roadCache, nil];
    
}

- (NSArray *)cacheSymbolElements:(struct ocad_symbol_element *)se atPoint:(NSPoint)origin withAngle:(float)angle totalDataSize:(uint16_t)data_size {
    NSAffineTransform *at = [NSAffineTransform transform];
    [at translateXBy:origin.x yBy:origin.y];
    if (angle != 0.0) [at rotateByRadians:angle];
    
    uint16_t se_index;
    if (data_size == 0) data_size = se->ncoords + 2;
    NSMutableArray *cache = [NSMutableArray arrayWithCapacity:data_size];
    
    for (se_index = 0; se_index < data_size;) {
        
        NSBezierPath *path = [NSBezierPath bezierPath];
        int i;
        NSColor *color = [self colorWithNumber:se->color];

        switch (se->symbol_type) {
            case 1: /* Line */
                [path moveToPoint:NSMakePoint(se->points[0].x >> 8, se->points[0].y >> 8)];
                for (i = 1; i < se->ncoords; i++) {
                    [path lineToPoint:NSMakePoint(se->points[i].x >> 8, se->points[i].y >> 8)];
                }
                [path setLineWidth:se->line_width];
                [cache addObject:[NSDictionary dictionaryWithObjectsAndKeys:color, @"strokeColor", [at transformBezierPath:path], @"path", nil]];
                break;
            case 2: /* Area */
                [path moveToPoint:NSMakePoint(se->points[0].x >> 8, se->points[0].y >> 8)];
                for (i = 1; i < se->ncoords; i++) {
                    if (se->points[i].x & 1) {
                        [path curveToPoint:NSMakePoint(se->points[i + 2].x >> 8, se->points[i + 2].y >> 8) 
                             controlPoint1:NSMakePoint(se->points[i].x >> 8, se->points[i].y >> 8) 
                             controlPoint2:NSMakePoint(se->points[i + 1].x >> 8, se->points[i + 1].y >> 8)];
                        
                        i += 2;
                        
                    } else {
                        [path lineToPoint:NSMakePoint(se->points[i].x >> 8, se->points[i].y >> 8)];
                    }
                }
                [path closePath];
                [cache addObject:[NSDictionary dictionaryWithObjectsAndKeys:color, @"fillColor", [at transformBezierPath:path], @"path", nil]];
                break;
            case 3:
            case 4: /* Dot. */
                path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-(se->diameter / 2) + (se->points[0].x >> 8), -(se->diameter / 2) + (se->points[0].y >> 8), se->diameter, se->diameter)];
                if (se->symbol_type == 3) {
                    [path setLineWidth:se->line_width];
                    [cache addObject:[NSDictionary dictionaryWithObjectsAndKeys:color, @"strokeColor", [at transformBezierPath:path], @"path", nil]];
                } else {
                    [cache addObject:[NSDictionary dictionaryWithObjectsAndKeys:color, @"fillColor", [at transformBezierPath:path], @"path", nil]];
                }
                break;
            default:
                break;
        }
        int nc = se->ncoords;
        se_index += nc + 2;
        se ++;
        se = (struct ocad_symbol_element *)(((struct TDPoly *)se) + nc);
    }
    
    return cache;
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
        NSColor *c;
        c = [NSColor clearColor];
        
        if (a->hatch_mode == 0 && a->structure_mode == 0) {
            if (a->colors[0] >= [colors count]) {
                NSLog(@"color: %d", a->colors[0]);
                c = [NSColor blackColor];
            } else {
                c = [colors objectAtIndex:a->colors[0]];
            }
        } else {
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
            
        }
        
        [areaSymbolColors setObject:c forKey:key];
    }
}

- (NSColor *)colorWithNumber:(int)color_number {
    if (color_number < [colors count]) {
        return [colors objectAtIndex:color_number];
    } else {
        return [NSColor blackColor];
    }
}


+ (float)angleBetweenPoint:(NSPoint)p1 andPoint:(NSPoint)p2 {
    float dx = p2.x - p1.x;
    float dy = p2.y - p1.y;
    if (dx == 0) {
        if (dy > 0) return pi / 2;
        return 3.0*pi / 2;
    }
    float t = atan(dy/dx);
    if (dx < 0) t += pi;
    if (t < 0) t += 2.0*pi;
    return t;    
}

+ (float)angleForCoords:(struct TDPoly *)coords ofLength:(int)total atIndex:(int)i {
    float angle;
    // Crossbar, for symbols 515, 516, 517 et.c.
    if (i == total - 1) {
        if (i > 0) {
            angle = [self angleBetweenPoint:NSMakePoint(coords[i-1].x >> 8, coords[i-1].y >> 8) 
                                      andPoint:NSMakePoint(coords[i].x >> 8, coords[i].y >> 8)];
        } else {
            // Only one point
            angle = 0.0;
        }
    } else if (i == 0) {
        angle = [self angleBetweenPoint:NSMakePoint(coords[i].x >> 8, coords[i].y >> 8) 
                                  andPoint:NSMakePoint(coords[i+1].x >> 8, coords[i+1].y >> 8)];
        
    } else {
        angle = ([self angleBetweenPoint:NSMakePoint(coords[i].x >> 8, coords[i].y >> 8) 
                                   andPoint:NSMakePoint(coords[i+1].x >> 8, coords[i+1].y >> 8)] + 
                 [self angleBetweenPoint:NSMakePoint(coords[i-1].x >> 8, coords[i-1].y >> 8) 
                                   andPoint:NSMakePoint(coords[i].x >> 8, coords[i].y >> 8)]) * 0.5;
    }
    
    return angle;
}

+ (NSPoint)translatePoint:(NSPoint)p distance:(float)distance angle:(float)angle {
    NSPoint q;
    q.x = p.x + cosf(angle)*distance;
    q.y = p.y + sinf(angle)*distance;
    return q;
}


@end
