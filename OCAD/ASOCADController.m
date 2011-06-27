//
//  ASOCADController.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-02.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASOCADController.h"
#import "ocdimport.h"
#import <QuartzCore/QuartzCore.h>
#import "ASOCADController_Text.h"
#import "ASOCADController_Area.h"
#import "ASOCADController_Line.h"

#define PARALLELIZATION 2
#define CONCURRENCY (1 << PARALLELIZATION)

void ColorRelease (CFAllocatorRef allocator,const void *value) {
    CGColorRelease((CGColorRef)value);
}

CFArrayRef CreateColorArray () {
    CGColorRef colors[30] = {
    /* 0 Svart */            CGColorCreateGenericRGB(0.0,0.0,0.0,1.0),
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
    /* 25 Roads  */		    CGColorCreateGenericRGB(0.0,0.0,0.0,1.0),
    /* 26 Reserved % */     CGColorCreateGenericRGB(0.000,0.000,0.000,0.000),
    /* 27 Reserved % */     CGColorCreateGenericRGB(0.000,0.000,0.000,0.000),
    /* 28 Reserved % */     CGColorCreateGenericRGB(0.000,0.000,0.000,0.000),
        /* 29 Water? */         CGColorCreateGenericRGB(0.537,0.745,0.859,1.000) };
    CFArrayCallBacks callbacks;
    callbacks.version = 0;
    callbacks.retain = NULL;
    callbacks.release = &ColorRelease;
    callbacks.copyDescription = NULL;
    callbacks.equal = NULL;
    
    CFArrayRef c = CFArrayCreate(NULL, (const void **)colors, 30, &callbacks);
    
    return c;
}

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
        
        colors = (NSArray *)CreateColorArray();

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
    
    CGColorRelease(blackColor);
	
	[super dealloc];
}

- (NSRect)mapBounds {
    CGPathRef thePath;
	CGRect pathBounds;
	CGRect wholeMap = CGRectMake(0.0,0.0,0.0,0.0);
	BOOL firstSet = NO;
    
	if ([cachedDrawingInformation count] == 0) return NSZeroRect;
	
	for (NSDictionary *cachedData in cachedDrawingInformation) {
		thePath = (CGPathRef)[cachedData objectForKey:@"path"];
		if (thePath != NULL) {
            pathBounds = CGPathGetPathBoundingBox(thePath);
            if (firstSet)
                wholeMap = CGRectUnion(wholeMap, pathBounds);
            else {
                wholeMap = pathBounds;
                firstSet = YES;
            }
		}
	}
	return wholeMap;
}

- (NSInteger)symbolNumberAtPosition:(CGPoint)p {
	NSEnumerator *cacheEnumerator = [cachedDrawingInformation reverseObjectEnumerator];
	NSDictionary *info;
	while ((info = [cacheEnumerator nextObject])) {
		CGPathRef path = (CGPathRef)[info objectForKey:@"path"];
		if (CGPathContainsPoint(path, NULL, p, true)) {
            // TODO: store the symbol number in the cache, and return that instead.
            return 1;
        }
	}
	
	return 0;
}

- (NSArray *)createCacheFromIndex:(NSInteger)start upToButNotIncludingIndex:(NSInteger)stop {
    NSMutableArray *nonBlackAreas = [NSMutableArray arrayWithCapacity:100];
    NSMutableArray *lines = [NSMutableArray arrayWithCapacity:10000];
    NSMutableArray *blackLines = [NSMutableArray arrayWithCapacity:10000];
    NSMutableArray *rectangles = [NSMutableArray arrayWithCapacity:100];
    NSMutableArray *blackAreas = [NSMutableArray arrayWithCapacity:100];
    NSMutableArray *strings = [NSMutableArray arrayWithCapacity:100];
    NSMutableArray *pointObjects = [NSMutableArray arrayWithCapacity:10000];
    
    NSInteger i;
    struct ocad_element *e;
    struct ocad_object_index *o;
    enum ocad_object_type type;
	NSArray *a, *b;
	struct ocad_area_symbol *area;
    CGColorRef black = (CGColorRef)[colors objectAtIndex:0];
    
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
                if ([a count] == 2) {
                    NSDictionary *mainLine = [a objectAtIndex:1];
                    if ((CGColorRef)[mainLine objectForKey:@"strokeColor"] == black) {
                        [blackLines addObject:mainLine];
                    } else {
                        [lines addObject:mainLine];
                    }
                }
				if ([a count] > 0) {
                    b = [a objectAtIndex:0];
                    for (NSDictionary *linePart in b) {
                        if ((CGColorRef)[linePart objectForKey:@"strokeColor"] == black) {
                            [blackLines addObject:linePart];
                        } else {
                            [lines addObject:linePart];
                        }
                    }
                }
				break;
			case ocad_rectangle_object:
				[rectangles addObject:[self cachedDrawingInfoForRectangleObject:e]];
				break;
			case ocad_point_object:
				[pointObjects addObjectsFromArray:[self cachedDrawingInfoForPointObject:e]];
				break;
            case ocad_unformatted_text_object:
            case ocad_formatted_text_object:
            case ocad_line_text_object:
                [strings addObject:[self cachedDrawingInfoForTextObject:e]];
                break;
			default:
				break;
		}

    }

    return [NSArray arrayWithObjects:nonBlackAreas, lines, rectangles, blackAreas, pointObjects, strings, blackLines, nil];
}

- (void)createCache {

    if (ocdf == NULL) {
        if (cachedDrawingInformation != nil) {
            [cachedDrawingInformation release];
            cachedDrawingInformation = nil;
        }
        return;
    }
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
    for (i = 0; i < 7; i++) {
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

// CATiledLayer delegate stuff. Also used by the quicklook plugin.
// In the latter case, layer will be NULL.
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    for (NSDictionary *d in cachedDrawingInformation) {
        CGPathRef path = (CGPathRef)[d objectForKey:@"path"];
        CGColorRef strokeColor = (CGColorRef)[d objectForKey:@"strokeColor"];
        CGColorRef fillColor = (CGColorRef)[d objectForKey:@"fillColor"];
        CTFrameRef frame = (CTFrameRef)[d objectForKey:@"frame"];
        NSNumber *capStyle = [d objectForKey:@"capStyle"];
        NSNumber *joinStyle = [d objectForKey:@"joinStyle"];
        NSNumber *width = [d objectForKey:@"width"];
        CGContextSetTextDrawingMode(ctx, kCGTextFill);
        CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
        if (CGRectIntersectsRect(CGPathGetBoundingBox(path), CGContextGetClipBoundingBox(ctx))) {
            CGContextBeginPath(ctx);
            CGContextAddPath(ctx,path);
            if (fillColor != NULL) {
                if (CGColorGetPattern(fillColor) != NULL) {
                    struct ocad_area_symbol *area = (struct ocad_area_symbol *)[[d objectForKey:@"symbol"] pointerValue];
                    CGAffineTransform matrix = CGContextGetCTM(ctx);                    
                    CGContextSetFillColorWithColor(ctx, [self areaColorForSymbol:area transform:matrix]);
                } else {
                    CGContextSetFillColorWithColor(ctx, fillColor);
                }
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
                } else {
                    CGContextSetLineDash(ctx, 0.0, NULL, 0);
                }
                if (joinStyle != NULL) CGContextSetLineJoin(ctx, (enum CGLineJoin)[joinStyle integerValue]);
                if (capStyle != NULL) CGContextSetLineCap(ctx, (enum CGLineCap)[capStyle integerValue]);
                CGContextStrokePath(ctx);
            }
            if (frame != NULL) {
                CGContextSaveGState(ctx);
                CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
                //CGFloat debugColor[4] = {1.0,0.0,0.0,1.0};
                //CGContextSetStrokeColor(ctx, debugColor);
                //CGContextStrokePath(ctx); 
                /*
                NSValue *transform = [d objectForKey:@"transform"];
                if (transform != nil) {
                    CATransform3D t = [transform CATransform3DValue];
                    CGAffineTransform at = CATransform3DGetAffineTransform(t);
                    NSLog(@"%f %f", at.b, at.c);
                    CGContextConcatCTM(ctx, at);
                    CGContextSetStrokeColor(ctx, debugColor );
                    CGContextBeginPath(ctx);
                    CGContextAddPath(ctx, path);
                    CGContextStrokePath(ctx);
                } */
                CTFrameDraw(frame, ctx);                
                CGContextRestoreGState(ctx);
            }
        }
    }
     
}

@end
