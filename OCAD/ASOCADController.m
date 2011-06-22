//
//  ASOCADController.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-02.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASOCADController.h"
#import "ocdimport.h"
#import "ASOCADRenderingOperation.h"
#import <QuartzCore/QuartzCore.h>

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
        blackColor = CGColorCreateGenericRGB(0.0,0.0,0.0,1.0);
        
        colors = [NSArray arrayWithObjects:
                  /* 0 Svart */           (id)blackColor,
                  /* 1 Berg i dagen */    CGColorCreateGenericRGB(0.698,0.702,0.698,1.000),
                  /* 2 Mindre vatten */   CGColorCreateGenericRGB(0.000,0.576,0.773,1.000),
                  /* 3 Vatten */          CGColorCreateGenericRGB(0.537,0.745,0.859,1.000), 
                  /* 4 Höjdkurva */       CGColorCreateGenericRGB(0.745,0.427,0.180,1.000),
                  /* 5 Asfalt */          CGColorCreateGenericRGB(0.867,0.675,0.486,1.000),
                  /* 6 Mkt svårlöpt */    CGColorCreateGenericRGB(0.212,0.663,0.345,1.000), 
                  /* 7 Svårlöpt */        CGColorCreateGenericRGB(0.545,0.769,0.557,1.000),
                  /* 8 Löphindrande */    CGColorCreateGenericRGB(0.773,0.875,0.745,1.000),
                  /* 9 Odlad mark */      CGColorCreateGenericRGB(0.953,0.722,0.357,1.000),
                  /* 10 Öppet sandomr. */ CGColorCreateGenericRGB(0.976,0.847,0.635,1.000),
                  /* 11 Påtryck */        CGColorCreateGenericRGB(0.835,0.102,0.490,1.000),
                  /* 12 Tomtmark */       CGColorCreateGenericRGB(0.631,0.616,0.255,1.000),
                  /* 13 Vitt */           CGColorCreateGenericRGB(1.000,1.000,1.000,1.000),
                  /* 14 Vitt */           CGColorCreateGenericRGB(1.000,0.000,0.000,1.000),
                  /* 15 Brown 50 % */     CGColorCreateGenericRGB(0.867,0.675,0.486,1.000),
                  /* 16 Reserved % */     CGColorCreateGenericRGB(0.000,0.000,0.000,0.000),
                  /* 17 Reserved % */     CGColorCreateGenericRGB(0.000,0.000,0.000,0.000),
                  /* 18 Reserved % */     CGColorCreateGenericRGB(0.000,0.000,0.000,0.000),
                  /* 19 Reserved % */     CGColorCreateGenericRGB(0.000,0.000,0.000,0.000),
                  /* 20 Reserved % */     CGColorCreateGenericRGB(0.000,0.000,0.000,0.000),
                  /* 21 Reserved % */     CGColorCreateGenericRGB(0.000,0.000,0.000,0.000),
                  /* 22 Reserved % */     CGColorCreateGenericRGB(0.000,0.000,0.000,0.000),
                  /* 23 Reserved % */     CGColorCreateGenericRGB(0.000,0.000,0.000,0.000),
                  /* 24 Reserved % */     CGColorCreateGenericRGB(0.000,0.000,0.000,0.000),
                  /* 25 Roads  */		  (id)blackColor,
                  /* 26 Reserved % */     CGColorCreateGenericRGB(0.000,0.000,0.000,0.000),
                  /* 27 Reserved % */     CGColorCreateGenericRGB(0.000,0.000,0.000,0.000),
                  /* 28 Reserved % */     CGColorCreateGenericRGB(0.000,0.000,0.000,0.000),
                  /* 29 Water? */         CGColorCreateGenericRGB(0.537,0.745,0.859,1.000),
                  nil];
        CGColorRetain(blackColor);
        CGColorRetain(blackColor);
        [colors retain];
        for (id c in colors) {
            CGColorRelease((CGColorRef)c);
        }

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
		free(ocdf);
    }
    return self;
}

- (void)dealloc {
	[renderingQueue waitUntilAllOperationsAreFinished];
	[renderingQueue release];
	[areaSymbolColors release];
	[colors release];
	[cachedDrawingInformation release];
	
	[super dealloc];
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
    CGPathRef thePath;
	CGRect pathBounds;
	CGRect wholeMap = CGRectMake(0.0,0.0,0.0,0.0);
	
	if ([cachedDrawingInformation count] == 0) return NSZeroRect;
	
	for (NSDictionary *cachedData in cachedDrawingInformation) {
		thePath = (CGPathRef)[cachedData objectForKey:@"path"];
		if (thePath != NULL) {
            pathBounds = CGPathGetPathBoundingBox(thePath);
			wholeMap = CGRectUnion(wholeMap, pathBounds);
		}
	}
	return wholeMap;
}

- (void)beginRenderingMapWithSize:(NSSize)sz fromSourceRect:(NSRect)sourceRect whenDone:(void (^)(NSImage *i))completionBlock {
	// Create an image of the appropriate size.
/*	double adjustedScale = 15000 * 0.01 * 0.001 * scale;
	double limit = 8000.0;
	if (sourceRect.size.width * adjustedScale > limit) adjustedScale = limit / sourceRect.size.width;
	if (sourceRect.size.height * adjustedScale > limit) adjustedScale = limit / sourceRect.size.height;
	
	NSSize sz = NSMakeSize(adjustedScale*sourceRect.size.width, adjustedScale * sourceRect.size.height);
*/	
	NSImage *destinationImage = [[NSImage alloc] initWithSize:sz];
	[destinationImage lockFocus];
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:NSMakeRect(0.0, 0.0, sz.width, sz.height)];
	
	NSInteger num = [cachedDrawingInformation count];
	NSInteger i;
	if (renderingQueue != nil) {
		[renderingQueue cancelAllOperations];
		// If we are unlucky, we'll cancel an operation while it is waiting to perform a selector on the main
		// thread (in the completion block). To combat that we sleep for a short while.
		[NSThread sleepForTimeInterval:0.001];
		[renderingQueue waitUntilAllOperationsAreFinished];
	} else {
		renderingQueue = [[NSOperationQueue alloc] init];
	}
	
	NSAffineTransform *at = [NSAffineTransform transform];
	
    NSAffineTransformStruct ts;
	float adjustedScale = sz.width / sourceRect.size.width;

	ts.m12 = 0.0; ts.m21 = 0.0;	
	ts.tX = - NSMinX(sourceRect)*adjustedScale;
	ts.tY = - NSMinY(sourceRect)*adjustedScale;
	ts.m11 = adjustedScale; ts.m22 = adjustedScale;
	[at setTransformStruct:ts];
	
	NSMutableArray *ops = [NSMutableArray arrayWithCapacity:CONCURRENCY];
	ASOCADFinishRenderingOperation *finished = [[[ASOCADFinishRenderingOperation alloc] init] autorelease];

	for (i = 0; i < CONCURRENCY; i++) {

		ASOCADRenderingOperation *render = [[ASOCADRenderingOperation alloc] init];
		render.size = sz;
		render.transform = at;
		render.cachedDrawingInformation = cachedDrawingInformation;
		render.ocdf = ocdf;
		render.startIndex = i*(num >> PARALLELIZATION);
		render.stopIndex = (i == (CONCURRENCY - 1))?num:(render.startIndex + (num >> PARALLELIZATION));
		[ops addObject:render];
		[finished addDependency:render];
		[renderingQueue addOperation:[render autorelease]];
	}
	finished.renderingOperations = ops;
	[finished setWhenDone:completionBlock];
	[renderingQueue addOperation:finished];
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
}

- (NSDictionary *)cachedDrawingInfoForAreaObject:(struct ocad_element *)e {
    struct ocad_area_symbol *area = (struct ocad_area_symbol *)(e->symbol);
    int c;
    
    if (e->nCoordinates == 0 ||
        area == NULL ||
        area->status == 2 /* Hidden */)
        return nil;
	
	CGMutablePathRef p = CGPathCreateMutable();
	CGPathMoveToPoint(p, NULL, e->coords[0].x >> 8, e->coords[0].y >> 8);
    
    for (c = 0; c < e->nCoordinates; c++) {
        if (e->coords[c].x & 1) {
            // Bezier curve.
			CGPathAddCurveToPoint(p, NULL,	e->coords[c].x >> 8, e->coords[c].y >> 8,
											e->coords[c+1].x >> 8, e->coords[c+1].y >> 8,
								  e->coords[c+2].x >> 8, e->coords[c+2].y >> 8);
            c += 2;
            
        } else      if (e->coords[c].y & 2) {
			CGPathCloseSubpath(p);
			CGPathMoveToPoint(p, NULL, e->coords[c].x >> 8, e->coords[c].y >> 8);
        }
        else {
			CGPathAddLineToPoint(p, NULL, e->coords[c].x >> 8, e->coords[c].y >> 8);
        }
    }
    NSColor *color = [areaSymbolColors objectForKey:[NSNumber numberWithInt:area->symnum]];
    NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:color, @"fillColor", p, @"path", nil];
	CGPathRelease(p);
	return d;
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
	NSDictionary *d = nil;
    
    if (e->nCoordinates == 0 ||
        rect == NULL ||
        rect->status == 2 /* Hidden */) {
        return d;
    }
    
	CGMutablePathRef p = CGPathCreateMutable();
	CGPathMoveToPoint(p, NULL, e->coords[0].x >> 8, e->coords[0].y >> 8);
    
    for (c = 0; c < e->nCoordinates; c++) {
		CGPathAddLineToPoint(p, NULL, e->coords[c].x >> 8, e->coords[c].y >> 8);
    }
	CGPathCloseSubpath(p);
    
    CGColorRef color = [self colorWithNumber:rect->colors[0]];
    
    if (rect->line_width != 0) {
        d = [NSDictionary dictionaryWithObjectsAndKeys:(id)color,@"strokeColor",p, @"path",[NSNumber numberWithInt:rect->line_width], @"width", nil];
    } else {
		d = [NSDictionary dictionaryWithObjectsAndKeys:(id)color, @"fillColor", p, @"path", nil];
	}
	CGPathRelease(p);
	
	return d;
}

- (NSArray *)cachedDrawingInfoForLineObject:(struct ocad_element *)e {
    struct ocad_line_symbol *line = (struct ocad_line_symbol *)(e->symbol);
    int c;
	
	CGMutablePathRef p = CGPathCreateMutable();

    NSDictionary *roadCache = nil;
    NSMutableArray *cachedData = [NSMutableArray arrayWithCapacity:10];
    
    if (e->nCoordinates == 0 || (line != NULL && line->status == 2 /* Hidden */)) {
        return [NSArray array];
    }
    
    if (line != NULL && (line->dbl_width != 0)) {
		CGMutablePathRef left = CGPathCreateMutable();
		CGMutablePathRef right = CGPathCreateMutable();
		CGMutablePathRef road = CGPathCreateMutable();

        NSPoint p0 = NSMakePoint(e->coords[0].x >> 8, e->coords[0].y >> 8);
		CGPathMoveToPoint(road, NULL, p0.x, p0.y);
        
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
				CGPathAddCurveToPoint(road, NULL, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
                c += 2;
                p0 = p2; angleSet = NO;
            } else {
                p0 = p1;
				CGPathAddLineToPoint(road, NULL, p1.x, p1.y);
            }
            
        }
        
        // Get the angle to the next normal point. 
        // Translate the point half the width to each side.
        // Create the path to the next point in the normal manner.
        // Be sure to watch for gaps in the left / right lines.
        
        currentAngle = angles;
		NSPoint p1;
		p1 = [[self class] translatePoint:NSMakePoint(e->coords[0].x >> 8, e->coords[0].y >> 8) distance:(line->dbl_width) angle:(*currentAngle + pi/2)]; 
		CGPathMoveToPoint(left, NULL, p1.x, p1.y);
		p1 = [[self class] translatePoint:NSMakePoint(e->coords[0].x >> 8, e->coords[0].y >> 8) distance:(line->dbl_width) angle:(*currentAngle - pi/2)];
		CGPathMoveToPoint(right, NULL, p1.x, p1.y);
        
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

                CGPathAddCurveToPoint(left, NULL, p1l.x, p1l.y, p2l.x, p2l.y, p3l.x, p3l.y);
				CGPathAddCurveToPoint(right, NULL, p1r.x, p1r.y, p2r.x, p2r.y, p3r.x, p3r.y);
                c += 2;
                
            } else {
                if (e->coords[c].x & 4) {
					CGPathMoveToPoint(left, NULL, p1l.x, p1l.y);
				} else {
					CGPathAddLineToPoint(left, NULL, p1l.x, p1l.y);
				}
				
                if (e->coords[c].y & 4) {
					CGPathMoveToPoint(right, NULL, p1r.x, p1r.y);
				} else {
					CGPathAddLineToPoint(right, NULL, p1r.x, p1r.y);
				}
            }
        }
        free(angles);
        
        roadCache = [NSDictionary dictionaryWithObjectsAndKeys:(id)[self colorWithNumber:line->dbl_fill_color], @"strokeColor", 
					 road, @"path", [NSNumber numberWithFloat:line->dbl_width + line->dbl_left_width*0.5 + line->dbl_right_width*0.5], @"width", nil];
        [cachedData addObject:[NSDictionary dictionaryWithObjectsAndKeys:(id)[self colorWithNumber:line->dbl_left_color], @"strokeColor", 
							   left, @"path",[NSNumber numberWithInt:line->dbl_left_width], @"width", 
							   [NSNumber numberWithInt:NSSquareLineCapStyle], @"capStyle", nil]];
        [cachedData addObject:[NSDictionary dictionaryWithObjectsAndKeys:(id)[self colorWithNumber:line->dbl_right_color], @"strokeColor", 
							   right, @"path",[NSNumber numberWithInt:line->dbl_right_width], @"width", 
							   [NSNumber numberWithInt:NSSquareLineCapStyle], @"capStyle", nil]];
    }
    if (e->linewidth != 0 || (line != NULL && line->line_width != 0)) {
		CGPathMoveToPoint(p, NULL, e->coords[0].x >> 8, e->coords[0].y >> 8);
        
        for (c = 0; c < e->nCoordinates; c++) {
            if (e->coords[c].x & 1) {
                // Bezier curve.
				CGPathAddCurveToPoint(p, NULL, e->coords[c].x >> 8, e->coords[c].y >> 8, e->coords[c+1].x >> 8, e->coords[c+1].y >> 8, e->coords[c+2].x >> 8, e->coords[c+2].y >> 8);
                c += 2;
                
            } else {
				CGPathAddLineToPoint(p, NULL, e->coords[c].x >> 8, e->coords[c].y >> 8);
            }
            
            if (e->coords[c].y & 1 && line != NULL && line->corner_d_size != 0) {
                struct ocad_symbol_element *se = (struct ocad_symbol_element *)(line->coords + line->prim_d_size + line->sec_d_size);
                
                float angle = [[self class] angleForCoords:e->coords ofLength:e->nCoordinates atIndex:c];
                [cachedData addObjectsFromArray:[self cacheSymbolElements:se atPoint:NSMakePoint(e->coords[c].x >> 8, e->coords[c].y >> 8) withAngle:angle totalDataSize:(se->ncoords + 2)]];
            }
        }
        NSColor *mainColor;
		NSMutableDictionary *mainLine = [NSMutableDictionary dictionaryWithCapacity:5];

        if (line != NULL && line->line_color < [colors count]) 
            mainColor = [colors objectAtIndex:line->line_color];
        else if (e->color < [colors count])
            mainColor = [colors objectAtIndex:e->color];
        else
            mainColor = [NSColor blackColor];
        
        if (line != NULL && line->main_length != 0) {
			NSMutableArray *dashes = [NSMutableArray arrayWithCapacity:4];
			[dashes addObject:[NSNumber numberWithInt:line->main_length]];
			[dashes addObject:[NSNumber numberWithInt:line->main_gap]];
            if (line->sec_gap > 0) {
				[dashes addObject:[NSNumber numberWithInt:line->main_length]];
				[dashes addObject:[NSNumber numberWithInt:line->sec_gap]];
            }
			[mainLine setObject:dashes forKey:@"dashes"];
        }
        
        if (line != NULL) {
			[mainLine setObject:[NSNumber numberWithFloat:(CGFloat)(line->line_width)] forKey:@"width"];
            switch (line->line_style) {
                case 0:
					[mainLine setObject:[NSNumber numberWithInt:NSBevelLineJoinStyle] forKey:@"joinStyle"];
					[mainLine setObject:[NSNumber numberWithInt:NSButtLineCapStyle] forKey:@"capStyle"];
                    break;
                case 1:
					[mainLine setObject:[NSNumber numberWithInt:NSRoundLineJoinStyle] forKey:@"joinStyle"];
					[mainLine setObject:[NSNumber numberWithInt:NSRoundLineCapStyle] forKey:@"capStyle"];
                    break;
                case 2:
					[mainLine setObject:[NSNumber numberWithInt:NSMiterLineJoinStyle] forKey:@"joinStyle"];
					[mainLine setObject:[NSNumber numberWithInt:NSButtLineCapStyle] forKey:@"capStyle"];
                    break;
            };
        } else {
 			[mainLine setObject:[NSNumber numberWithFloat:(CGFloat)(e->linewidth)] forKey:@"width"];
        }
		[mainLine setObject:mainColor forKey:@"strokeColor"];
		[mainLine setObject:(id)p forKey:@"path"];
        [cachedData addObject:mainLine];
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
	CGAffineTransform at = CGAffineTransformIdentity;
	at = CGAffineTransformTranslate(at, origin.x, origin.y);
    if (angle != 0.0) at = CGAffineTransformRotate(at, angle);
    
    uint16_t se_index;
    if (data_size == 0) data_size = se->ncoords + 2;
    NSMutableArray *cache = [NSMutableArray arrayWithCapacity:data_size];
    
    for (se_index = 0; se_index < data_size;) {
        
		CGMutablePathRef path = CGPathCreateMutable();
        int i;
        CGColorRef color = [self colorWithNumber:se->color];

        switch (se->symbol_type) {
            case 1: /* Line */
				CGPathMoveToPoint(path, &at, se->points[0].x >> 8, se->points[0].y >> 8);
                for (i = 1; i < se->ncoords; i++) {
					CGPathAddLineToPoint(path, &at, se->points[i].x >> 8, se->points[i].y >> 8);
                }
				
                [cache addObject:[NSDictionary dictionaryWithObjectsAndKeys:(id)color, @"strokeColor", 
								  path, @"path", 
								  [NSNumber numberWithInt:se->line_width], @"width",nil]];
                break;
            case 2: /* Area */
				CGPathMoveToPoint(path, &at, se->points[0].x >> 8, se->points[0].y >> 8);
                for (i = 1; i < se->ncoords; i++) {
                    if (se->points[i].x & 1) {
						CGPathAddCurveToPoint(path, &at, se->points[i].x >> 8, se->points[i].y >> 8, se->points[i + 1].x >> 8, se->points[i + 1].y >> 8, se->points[i + 2].x >> 8, se->points[i + 2].y >> 8);                       
                        i += 2;
                        
                    } else {
						CGPathAddLineToPoint(path, &at, se->points[i].x >> 8, se->points[i].y >> 8);
                    }
                }
				CGPathCloseSubpath(path);
                [cache addObject:[NSDictionary dictionaryWithObjectsAndKeys:(id)color, @"fillColor", path, @"path", nil]];
                break;
            case 3:
            case 4: /* Dot. */
				CGPathAddEllipseInRect(path, &at, CGRectMake(-(se->diameter / 2) + (se->points[0].x >> 8), -(se->diameter / 2) + (se->points[0].y >> 8), se->diameter, se->diameter));
                if (se->symbol_type == 3) {
					[cache addObject:[NSDictionary dictionaryWithObjectsAndKeys:(id)color, @"strokeColor", 
									  path, @"path", 
									  [NSNumber numberWithInt:se->line_width], @"width",nil]];
                } else {
                    [cache addObject:[NSDictionary dictionaryWithObjectsAndKeys:(id)color, @"fillColor", path, @"path", nil]];
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

// Open sandy ground. 45x45
void draw211 (void * info,CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 10));
    CGContextFillRect(context, CGRectMake(0.0, 0.0, 45.0, 45.0));
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 0));
    CGContextBeginPath(context);
    CGContextAddEllipseInRect(context, CGRectMake(0.0, 0.0, 18.0, 18.0));
    CGContextFillPath(context);
}

// Uncrossable marsh 1x50
void draw309 (void * info,CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 2));
    CGContextFillRect(context, CGRectMake(0.0, 25.0, 1.0, 25.0));
}

// Marsh 1x30
void draw310 (void * info,CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 2));
    CGContextFillRect(context, CGRectMake(0.0, 20.0, 1.0, 10.0));
}

// Indistinct marsh 115x60
void draw311 (void * info,CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 2));
    CGContextFillRect(context, CGRectMake(12.0, 20.0, 90.0, 10.0));
    CGContextFillRect(context, CGRectMake(0.0, 50.0, 45.0, 10.0));
    CGContextFillRect(context, CGRectMake(70.0, 50.0, 45.0, 10.0));
}

// Open land with scattered trees 71x71
void draw402 (void * info,CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 13));
    CGContextFillRect(context, CGRectMake(0.0,0.0,71.0,71.0));
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 9));
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
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 9));
    CGContextFillRect(context, CGRectMake(0.0,0.0,99.0,99.0));
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 13));
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
    CGFloat color[4] = {0.357,0.725,0.467,1.000};
    CGContextSetFillColor(context, color);
    CGContextFillRect(context, CGRectMake(0.0,0.0,12.0,1.0));
}

// Orchard 80x80
void draw412 (void * info,CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 9));
    CGContextFillRect(context, CGRectMake(0.0,0.0,80.0,80.0));
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 6));
    CGContextBeginPath(context);
    CGContextAddEllipseInRect(context, CGRectMake(18.0, 18.0, 45.0, 45.0));
    CGContextFillPath(context);
                              
}

// Vineyard 170x190
void draw413 (void * info,CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 9));
    CGContextFillRect(context, CGRectMake(0.0,0.0,170.0, 190.0));
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 6));
    CGContextFillRect(context, CGRectMake(0.0, 0.0, 20.0, 65.0));
    CGContextFillRect(context, CGRectMake(0.0, 125.0, 20.0, 65.0));
    CGContextFillRect(context, CGRectMake(85.0, 30.0, 20.0, 130.0));
}

// Cultivated land 80x80
void draw415 (void * info, CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 9));
    CGContextFillRect(context, CGRectMake(0.0,0.0,80.0,80.0));
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 0));
    CGContextBeginPath(context);
    CGContextAddEllipseInRect(context, CGRectMake(30.0, 30.0, 20.0, 20.0));
    CGContextFillPath(context);
}

// Permanently out of bounds 75x1
void draw528 (void * info, CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 0));
    CGContextFillRect(context, CGRectMake(0.0,0.0,25.0,1.0));
}

// Out-of-bounds area 60x1
void draw709 (void * info, CGContextRef context) {
    CGContextSetFillColorWithColor(context, (CGColorRef)CFArrayGetValueAtIndex((CFArrayRef)info, 11));
    CGContextFillRect(context, CGRectMake(0.0,0.0,25.0,1.0));
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
            if (a->colors[0] >= [colors count]) {
                c = blackColor;
            } else {
                c = (CGColorRef)[colors objectAtIndex:a->colors[0]];
            }
            CGColorRetain(c);
        } else {
            CGPatternCallbacks callbacks;
            callbacks.releaseInfo = NULL;
            callbacks.version = 0;
            CGColorSpaceRef cspace = CGColorSpaceCreatePattern(NULL);
            CGPatternRef pattern;
            switch (a->symnum / 1000) {
                case 211:
                    callbacks.drawPattern = draw211;
                    pattern = CGPatternCreate(colors, CGRectMake(0.0, 0.0, 45.0, 45.0), CGAffineTransformIdentity, 45.0, 45.0, kCGPatternTilingConstantSpacingMinimalDistortion, true, &callbacks);
                    break;
                case 309:
                    callbacks.drawPattern = draw309;
                    pattern = CGPatternCreate(colors, CGRectMake(0.0, 0.0, 1.0, 50.0), CGAffineTransformIdentity, 1.0,50.0, kCGPatternTilingConstantSpacingMinimalDistortion, true, &callbacks);
                    break;
                case 310:
                    callbacks.drawPattern = draw310;
                    pattern = CGPatternCreate(colors, CGRectMake(0.0, 0.0, 1.0, 30.0), CGAffineTransformIdentity, 1.0,30.0, kCGPatternTilingConstantSpacingMinimalDistortion, true, &callbacks);
                    break;
                case 311:
                    callbacks.drawPattern = draw311;
                    pattern = CGPatternCreate(colors, CGRectMake(0.0, 0.0, 115.0, 60.0), CGAffineTransformIdentity, 115.0, 60.0, kCGPatternTilingConstantSpacingMinimalDistortion, true, &callbacks);
                    break;
                case 402:
                    callbacks.drawPattern = draw402;
                    pattern = CGPatternCreate(colors, CGRectMake(0.0, 0.0, 71.0, 71.0), CGAffineTransformIdentity, 71.0, 71.0, kCGPatternTilingConstantSpacingMinimalDistortion, true, &callbacks);
                    break;
                case 404:
                    callbacks.drawPattern = draw404;
                    pattern = CGPatternCreate(colors, CGRectMake(0.0, 0.0, 99.0, 99.0), CGAffineTransformIdentity, 99.0, 99.0, kCGPatternTilingConstantSpacingMinimalDistortion, true, &callbacks);
                    break;
                case 407:
                    callbacks.drawPattern = draw407or409;
                    pattern = CGPatternCreate(colors, CGRectMake(0.0, 0.0, 84.0, 1.0), CGAffineTransformIdentity, 84.0, 1.0, kCGPatternTilingConstantSpacingMinimalDistortion, true, &callbacks);
                    break;
                case 409:
                    callbacks.drawPattern = draw407or409;
                    pattern = CGPatternCreate(colors, CGRectMake(0.0, 0.0, 42.0, 1.0), CGAffineTransformIdentity, 42.0, 1.0, kCGPatternTilingConstantSpacingMinimalDistortion, true, &callbacks);
                    break;
                case 412:
                    callbacks.drawPattern = draw412;
                    pattern = CGPatternCreate(colors, CGRectMake(0.0, 0.0, 80.0, 80.0), CGAffineTransformIdentity, 80.0, 80.0, kCGPatternTilingConstantSpacingMinimalDistortion, true, &callbacks);
                    break;
                case 413:
                    callbacks.drawPattern = draw413;
                    pattern = CGPatternCreate(colors, CGRectMake(0.0, 0.0, 170.0, 190.0), CGAffineTransformIdentity, 170.0, 190.0, kCGPatternTilingConstantSpacingMinimalDistortion, true, &callbacks);
                    break;
                case 415:
                    callbacks.drawPattern = draw415;
                    pattern = CGPatternCreate(colors, CGRectMake(0.0, 0.0, 80.0, 80.0), CGAffineTransformIdentity, 80.0, 80.0, kCGPatternTilingConstantSpacingMinimalDistortion, true, &callbacks);
                    break;
                case 528:
                    callbacks.drawPattern = draw528;
                    pattern = CGPatternCreate(colors, CGRectMake(0.0, 0.0, 75.0, 1.0), CGAffineTransformIdentity, 75.0, 1.0, kCGPatternTilingConstantSpacingMinimalDistortion, true, &callbacks);
                    break;
                case 709:
                    callbacks.drawPattern = draw709;
                    pattern = CGPatternCreate(colors, CGRectMake(0.0, 0.0, 60.0, 1.0), CGAffineTransformIdentity, 60.0, 1.0, kCGPatternTilingConstantSpacingMinimalDistortion, true, &callbacks);
                    break;
                    
                default:
                    callbacks.drawPattern = draw407or409;
                    pattern = CGPatternCreate(colors, CGRectMake(0.0, 0.0, 60.0, 1.0), CGAffineTransformIdentity, 60.0, 1.0, kCGPatternTilingConstantSpacingMinimalDistortion, true, &callbacks);
                    break;
                    break;
            }
            CGFloat testComps[4] = {0.0,0.0,0.0,1.0};
            c = CGColorCreateWithPattern(cspace, pattern, testComps);
            CGColorSpaceRelease(cspace);
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

- (CGColorRef)colorWithNumber:(int)color_number {
    if (color_number < [colors count]) {
        return (CGColorRef)[colors objectAtIndex:color_number];
    } else {
        return blackColor;
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

// CATiledLayer delegate stuff.
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    for (NSDictionary *d in cachedDrawingInformation) {
        CGPathRef path = (CGPathRef)[d objectForKey:@"path"];
        CGColorRef strokeColor = (CGColorRef)[d objectForKey:@"strokeColor"];
        CGColorRef fillColor = (CGColorRef)[d objectForKey:@"fillColor"];
        NSNumber *capStyle = [d objectForKey:@"capStyle"];
        NSNumber *joinStyle = [d objectForKey:@"joinStyle"];
        NSNumber *width = [d objectForKey:@"width"];
        
        if (CGRectIntersectsRect(CGPathGetBoundingBox(path), CGContextGetClipBoundingBox(ctx))) {
            CGContextBeginPath(ctx);
            CGContextAddPath(ctx,path);
            if (fillColor != NULL) {
                CGContextSetFillColorWithColor(ctx, fillColor);
                CGContextEOFillPath(ctx);
            }
            if (strokeColor != NULL) {
                CGContextSetStrokeColorWithColor(ctx, strokeColor);
                CGContextSetLineWidth(ctx, [width doubleValue]);
                NSMutableArray *dashes = [d valueForKey:@"dashes"];
                if (dashes != nil) {
                    CGFloat dashValues[4];
                    int i = 0;
                    for (NSNumber *dValue in dashes) {
                        dashValues[i++] = [dValue doubleValue];
                    }
                    CGContextSetLineDash(ctx, 0.0, dashValues, i);
                }
                if (joinStyle != NULL) CGContextSetLineJoin(ctx, (enum CGLineJoin)[joinStyle integerValue]);
                if (capStyle != NULL) CGContextSetLineCap(ctx, (enum CGLineCap)[capStyle integerValue]);
                CGContextStrokePath(ctx);
            }
        }
    }
     
}

@end
