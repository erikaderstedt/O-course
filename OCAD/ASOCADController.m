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

void ColorRelease (CFAllocatorRef allocator,const void *value);
const void *ColorRetain (CFAllocatorRef allocator,const void *value);

void ColorRelease (CFAllocatorRef allocator,const void *value) {
    CGColorRelease((CGColorRef)value);
}

const void *ColorRetain (CFAllocatorRef allocator,const void *value) {
    CGColorRetain((CGColorRef)value);
    return value;
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
        blackColor = CGColorCreateGenericCMYK(0.0,0.0,0.0,1.0,1.0);

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
        
        [self parseColorStrings];
        
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

- (void)parseColorStrings {
    int i, index, highest;
    CGFloat components[5];
    CFArrayCallBacks callbacks;
    
    callbacks.version = 0;
    callbacks.retain = &ColorRetain;
    callbacks.release = &ColorRelease;
    callbacks.copyDescription = NULL;
    callbacks.equal = NULL;
    
    highest = -1;
    for (i = 0; i < ocdf->num_strings; i++) {
        if (ocdf->string_rec_types[i] != 9) continue;
        NSString *s = [NSString stringWithCString:ocdf->strings[i] encoding:NSISOLatin1StringEncoding];
        NSArray *a = [s componentsSeparatedByString:@"\t"];
        for (NSString *component in a) {
            if ([component hasPrefix:@"n"]) {
                index = [[component substringFromIndex:1] intValue];
                if (index > highest) highest = index;
            } 
        }
    }
    
    if (highest < 33) highest = 33;
    
    colors = CFArrayCreateMutable(NULL, highest + 1, &callbacks);
    CGColorRef c;
    /* Set the default colors. */
    c = CGColorCreateGenericCMYK(0.000000, 0.000000, 0.000000, 1.000000, 1.000000); CFArraySetValueAtIndex(colors, 0, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.000000, 0.000000, 0.300000, 1.000000); CFArraySetValueAtIndex(colors, 1, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.870000, 0.180000, 0.000000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 2, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.430000, 0.090000, 0.000000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 3, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.680000, 0.910000, 0.340000, 1.000000); CFArraySetValueAtIndex(colors, 4, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.280000, 0.410000, 0.050000, 1.000000); CFArraySetValueAtIndex(colors, 5, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.710000, 0.000000, 0.910000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 6, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.440000, 0.000000, 0.560000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 7, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.230000, 0.000000, 0.270000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 8, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.270000, 0.790000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 9, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.100000, 0.600000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 10, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 1.000000, 0.000000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 11, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.380000, 0.270000, 1.000000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 12, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.000000, 0.000000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 13, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.000000, 0.000000, 1.000000, 1.000000); CFArraySetValueAtIndex(colors, 14, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.280000, 0.410000, 0.050000, 1.000000); CFArraySetValueAtIndex(colors, 15, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.050000, 0.160000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 16, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.500000, 0.000000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 17, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.200000, 0.000000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 18, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.000000, 0.000000, 0.500000, 1.000000); CFArraySetValueAtIndex(colors, 19, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.170000, 0.030000, 0.000000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 20, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.140000, 0.160000, 0.030000, 1.000000); CFArraySetValueAtIndex(colors, 21, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.000000, 0.000000, 0.300000, 1.000000); CFArraySetValueAtIndex(colors, 22, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.000000, 0.000000, 0.150000, 1.000000); CFArraySetValueAtIndex(colors, 23, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.000000, 0.000000, 0.060000, 1.000000); CFArraySetValueAtIndex(colors, 24, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.000000, 0.000000, 1.000000, 1.000000); CFArraySetValueAtIndex(colors, 25, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.000000, 0.000000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 26, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.240000, 0.000000, 0.710000, 0.140000, 1.000000); CFArraySetValueAtIndex(colors, 27, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.010000, 0.000000, 0.430000, 0.140000, 1.000000); CFArraySetValueAtIndex(colors, 28, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.000000, 0.000000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 29, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.000000, 0.000000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 30, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.000000, 0.000000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 31, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.180000, 0.560000, 0.000000, 1.000000); CFArraySetValueAtIndex(colors, 32, c); CGColorRelease(c); 
    c = CGColorCreateGenericCMYK(0.000000, 0.000000, 0.000000, 1.000000, 1.000000); CFArraySetValueAtIndex(colors, 33, c); CGColorRelease(c);

    
    CGColorSpaceRef cspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericCMYK);
    for (i = 0; i < ocdf->num_strings; i++) {
        if (ocdf->string_rec_types[i] != 9) continue;
        
        NSString *s = [NSString stringWithCString:ocdf->strings[i] encoding:NSISOLatin1StringEncoding];
        NSArray *a = [s componentsSeparatedByString:@"\t"];
        components[4] = 1.0;
        for (NSString *component in a) {
            if ([component hasPrefix:@"n"]) {
                index = [[component substringFromIndex:1] intValue];
            } else if ([component hasPrefix:@"c"]) {
                components[0] = 0.01*[[component substringFromIndex:1] floatValue];
            } else if ([component hasPrefix:@"m"]) {
                components[1] = 0.01*[[component substringFromIndex:1] floatValue];
            } else if ([component hasPrefix:@"y"]) {
                components[2] = 0.01*[[component substringFromIndex:1] floatValue];
            } else if ([component hasPrefix:@"k"]) {
                components[3] = 0.01*[[component substringFromIndex:1] floatValue];
            } else if ([component hasPrefix:@"t"]) {
                components[4] = 0.01*[[component substringFromIndex:1] floatValue];
            }
        }

        CFArraySetValueAtIndex(colors, index, CGColorCreate(cspace, components));
    }

    CGColorSpaceRelease(cspace);

}

- (void)dealloc {
	[areaSymbolColors release];
    if (colors != NULL) CFRelease(colors);

    if (cachedDrawingInfo != NULL) {
        int i = 0;
        for (i = 0; i < num_cached_objects; i++) {
            if (cachedDrawingInfo[i].path != NULL) CGPathRelease(cachedDrawingInfo[i].path);
            if (cachedDrawingInfo[i].strokeColor != NULL) CGColorRelease(cachedDrawingInfo[i].strokeColor);
            if (cachedDrawingInfo[i].fillColor != NULL) CGColorRelease(cachedDrawingInfo[i].fillColor);
            if (cachedDrawingInfo[i].frame != NULL) CFRelease(cachedDrawingInfo[i].frame);
        }
        free(cachedDrawingInfo);
        cachedDrawingInfo = NULL;
    }
    if (ocdf != NULL) {
        free(ocdf);
        ocdf = NULL;
    }
    
    CGColorRelease(blackColor);
	
	[super dealloc];
}

- (CGRect)mapBounds {
    CGPathRef thePath;
	CGRect pathBounds;
	CGRect wholeMap = CGRectMake(0.0,0.0,0.0,0.0);
	BOOL firstSet = NO;
    int i;
    
	if (cachedDrawingInfo == NULL) return CGRectZero;
	
    for (i = num_cached_objects - 1; i >= 0; i--) {        
		thePath = (CGPathRef)cachedDrawingInfo[i].path;
        
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
    
    // This find the path with the smallest area that contains the
    // point. This will not yield the correct result in some cases.
    // TODO: more work.
	int i, bestIndex = -1;
    CGFloat minArea = HUGE_VALF, area;
    for (i = num_cached_objects - 1; i >= 0; i--) {
        if (CGRectContainsPoint(cachedDrawingInfo[i].boundingBox, p)) {
            area = cachedDrawingInfo[i].boundingBox.size.width * cachedDrawingInfo[i].boundingBox.size.height;
            if (area < minArea) {
                minArea = area;
                bestIndex = i;
            }
        }
	}
    if (bestIndex >= 0) {
        struct ocad_element *e;
        e = cachedDrawingInfo[bestIndex].element;
        if (e != NULL) return e->symbol->symnum / 1000;
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
    CGColorRef black = (CGColorRef)CFArrayGetValueAtIndex(colors, 0);
    
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
    if (cachedDrawingInfo != NULL) {
        num_cached_objects = 0;
        free(cachedDrawingInfo);
        cachedDrawingInfo = NULL;
    }
    
    if (ocdf == NULL) return;
    
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
        
    [queue waitUntilAllOperationsAreFinished];
    
    // Count the number of objects.
    NSInteger frags = 0, j,k;

    for (i = 0; i < 7; i++) {
        for (NSInvocationOperation *op in invocations) {
            frags += [[[op result] objectAtIndex:i] count];
        }
    }
    cachedDrawingInfo = calloc(frags, sizeof(struct ocad_cache));
    if (cachedDrawingInfo == NULL) {
        return;
    }
    
    j = 0;
    for (i = 0; i < 7; i++) {
        for (NSInvocationOperation *op in invocations) { 
            NSArray *items= [[op result] objectAtIndex:i];
            for (NSDictionary *item in items) {
                cachedDrawingInfo[j].fillColor = (CGColorRef)[item objectForKey:@"fillColor"];
                cachedDrawingInfo[j].strokeColor = (CGColorRef)[item objectForKey:@"strokeColor"];
                cachedDrawingInfo[j].path = (CGPathRef)[item objectForKey:@"path"];
                cachedDrawingInfo[j].frame  =(CTFrameRef)[item objectForKey:@"frame"];
                cachedDrawingInfo[j].angle = [[item objectForKey:@"angle"] doubleValue];
                cachedDrawingInfo[j].midpoint = CGPointMake([[item objectForKey:@"midX"] doubleValue], [[item objectForKey:@"midY"] doubleValue]);
                cachedDrawingInfo[j].capStyle = (CGLineCap)[[item objectForKey:@"capStyle"] intValue];
                cachedDrawingInfo[j].joinStyle = (CGLineJoin)[[item objectForKey:@"joinStyle"] intValue];
                cachedDrawingInfo[j].width = [[item objectForKey:@"width"] doubleValue];
                cachedDrawingInfo[j].element = [[item objectForKey:@"element"] pointerValue];
                NSArray *dashes = [item objectForKey:@"dashes"];
                if (dashes != nil) {
                    cachedDrawingInfo[j].num_dashes = (int)[dashes count];
                    k = 0;
                    for (NSNumber *dash in dashes) {
                        cachedDrawingInfo[j].dashes[k++] = [dash doubleValue];
                    }
                }
                if (cachedDrawingInfo[j].path != NULL) CGPathRetain(cachedDrawingInfo[j].path);
                if (cachedDrawingInfo[j].strokeColor != NULL) CGColorRetain(cachedDrawingInfo[j].strokeColor);
                if (cachedDrawingInfo[j].fillColor != NULL) CGColorRetain(cachedDrawingInfo[j].fillColor);
                if (cachedDrawingInfo[j].frame != NULL) CFRetain(cachedDrawingInfo[j].frame);
                
                if (cachedDrawingInfo[j].path != NULL) {
                    cachedDrawingInfo[j].boundingBox = CGPathGetBoundingBox(cachedDrawingInfo[j].path);
                }
                j++;
                
            }
        }
    }
    num_cached_objects = (int)frags;
    
    for (NSInvocationOperation *op in invocations) {
        [op release];
    }
    [queue release];
}


- (NSArray *)cachedDrawingInfoForPointObject:(struct ocad_element *)e {
    struct ocad_point_symbol *point = (struct ocad_point_symbol *)(e->symbol);
    
    if (point == NULL || point->status == 2) return [NSArray array];
    
    
    float angle = 0.0;
    if (e->angle != -1) angle = ((float)(e->angle)) / 10.0 * pi / 180.0;
    return [self cacheSymbolElements:(struct ocad_symbol_element *)(point->points) 
                             atPoint:NSMakePoint(e->coords[0].x >> 8, e->coords[0].y >> 8) 
                           withAngle:angle 
                       totalDataSize:point->datasize
                              element:e];
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
        d = [NSDictionary dictionaryWithObjectsAndKeys:(id)color,@"strokeColor",p, @"path",[NSNumber numberWithInt:rect->line_width], @"width", [NSValue valueWithPointer:e], @"element", nil];
    } else {
		d = [NSDictionary dictionaryWithObjectsAndKeys:(id)color, @"fillColor", p, @"path", [NSValue valueWithPointer:e], @"element",nil];
	}
	CGPathRelease(p);
	
	return d;
}

- (NSArray *)cacheSymbolElements:(struct ocad_symbol_element *)se atPoint:(NSPoint)origin withAngle:(float)angle totalDataSize:(uint16_t)data_size {
    return [self cacheSymbolElements:se atPoint:origin withAngle:angle totalDataSize:data_size element:NULL];
}

- (NSArray *)cacheSymbolElements:(struct ocad_symbol_element *)se atPoint:(NSPoint)origin withAngle:(float)angle totalDataSize:(uint16_t)data_size element:(struct ocad_element *)element {
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
								  [NSNumber numberWithInt:se->line_width], @"width",
                                  [NSValue valueWithPointer:element], @"element",
                                  nil]];
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
                [cache addObject:[NSDictionary dictionaryWithObjectsAndKeys:(id)color, @"fillColor", path, @"path", 
                                  [NSValue valueWithPointer:element], @"element", nil]];
                break;
            case 3:
            case 4: /* Dot. */
				CGPathAddEllipseInRect(path, &at, CGRectMake(-(se->diameter / 2) + (se->points[0].x >> 8), -(se->diameter / 2) + (se->points[0].y >> 8), se->diameter, se->diameter));
                if (se->symbol_type == 3) {
					[cache addObject:[NSDictionary dictionaryWithObjectsAndKeys:(id)color, @"strokeColor", 
									  path, @"path", 
                                      [NSValue valueWithPointer:element], @"element",
									  [NSNumber numberWithInt:se->line_width], @"width",nil]];
                } else {
                    [cache addObject:[NSDictionary dictionaryWithObjectsAndKeys:(id)color, @"fillColor", path, @"path", 
                                      [NSValue valueWithPointer:element], @"element", nil]];
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
    if (color_number < CFArrayGetCount(colors)) {
        return (CGColorRef)CFArrayGetValueAtIndex(colors, color_number);
    } else {
        return blackColor;
    }
}


+ (float)angleBetweenPoint:(NSPoint)p1 andPoint:(NSPoint)p2 {
    return atan2(p2.y - p1.y, p2.x - p1.x);
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
    CGContextSetTextDrawingMode(ctx, kCGTextFill);
    int i;
    
    // TODO: Perhaps we can multithread this by rendering into bitmaps and then compositing those bitmaps on top of each other.
    CGRect clipBox = CGContextGetClipBoundingBox(ctx);
    for (i = 0; i < num_cached_objects; i++) {
        CGPathRef path = cachedDrawingInfo[i].path;
        CGColorRef strokeColor = cachedDrawingInfo[i].strokeColor;
        CGColorRef fillColor = cachedDrawingInfo[i].fillColor;
        CTFrameRef frame = cachedDrawingInfo[i].frame;
        CGRect bb = cachedDrawingInfo[i].boundingBox;
        if (CGRectIntersectsRect(bb, clipBox)) {
            CGContextBeginPath(ctx);
            CGContextAddPath(ctx,path);
            if (fillColor != NULL) {
                if (CGColorGetPattern(fillColor) != NULL) {
                    struct ocad_area_symbol *area = (struct ocad_area_symbol *)cachedDrawingInfo[i].element->symbol;
                    CGAffineTransform matrix = CGContextGetCTM(ctx);
                    if (cachedDrawingInfo[i].angle != 0.0) 
                        matrix = CGAffineTransformRotate(matrix, cachedDrawingInfo[i].angle);
                    CGContextSetFillColorWithColor(ctx, [self areaColorForSymbol:area transform:matrix]);
                } else {
                    CGContextSetFillColorWithColor(ctx, fillColor);
                }
                CGContextEOFillPath(ctx);
            }
            if (strokeColor != NULL) {
                CGContextSetStrokeColorWithColor(ctx, strokeColor);
                CGContextSetLineWidth(ctx, cachedDrawingInfo[i].width);
                if (cachedDrawingInfo[i].num_dashes) {
                    CGContextSetLineDash(ctx, 0.0, cachedDrawingInfo[i].dashes, cachedDrawingInfo[i].num_dashes);
                } else {
                    CGContextSetLineDash(ctx, 0.0, NULL, 0);
                }
                CGContextSetLineCap(ctx, (CGLineCap)cachedDrawingInfo[i].capStyle);
                CGContextSetLineJoin(ctx, cachedDrawingInfo[i].joinStyle);
                CGContextStrokePath(ctx);
            }
            if (frame != NULL) {
                CGContextSaveGState(ctx);

                CGFloat alpha = cachedDrawingInfo[i].angle*pi/180.0;
                if (alpha != 0.0) {
                    CGPoint m = cachedDrawingInfo[i].midpoint;
                    CGAffineTransform at = CGAffineTransformMake(cos(alpha), sin(alpha), -sin(alpha), cos(alpha), 
                                                                 m.y*sin(alpha)+ m.x*(1.0-cos(alpha)), 
                                                                 -m.x*sin(alpha) + m.y*(1.0-cos(alpha))); 
                    CGContextConcatCTM(ctx, at);
               } else {
                    CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);                    
                }
                CTFrameDraw(frame, ctx);                
                CGContextRestoreGState(ctx);
            }
        }
    }
     
}

@end
