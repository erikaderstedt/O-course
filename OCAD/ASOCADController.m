//
//  ASOCADController.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-02.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "ASGenericImageController.h"
#endif
#import "ASOCADController.h"
#import "ocdimport.h"
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

static CGFloat colorData[170] = {
    0.000000, 0.000000, 0.000000, 1.000000, 1.000000,
    0.000000, 0.000000, 0.000000, 0.300000, 1.000000,
    0.870000, 0.180000, 0.000000, 0.000000, 1.000000,
    0.430000, 0.090000, 0.000000, 0.000000, 1.000000,
    0.000000, 0.680000, 0.910000, 0.340000, 1.000000,
    0.000000, 0.280000, 0.410000, 0.050000, 1.000000,
    0.710000, 0.000000, 0.910000, 0.000000, 1.000000,
    0.440000, 0.000000, 0.560000, 0.000000, 1.000000,
    0.230000, 0.000000, 0.270000, 0.000000, 1.000000,
    0.000000, 0.270000, 0.790000, 0.000000, 1.000000,
    0.000000, 0.100000, 0.600000, 0.000000, 1.000000,
    0.000000, 1.000000, 0.000000, 0.000000, 1.000000,
    0.380000, 0.270000, 1.000000, 0.000000, 1.000000,
    0.000000, 0.000000, 0.000000, 0.000000, 1.000000,
    0.000000, 0.000000, 0.000000, 1.000000, 1.000000,
    0.000000, 0.280000, 0.410000, 0.050000, 1.000000,
    0.000000, 0.050000, 0.160000, 0.000000, 1.000000,
    0.000000, 0.500000, 0.000000, 0.000000, 1.000000,
    0.000000, 0.200000, 0.000000, 0.000000, 1.000000,
    0.000000, 0.000000, 0.000000, 0.500000, 1.000000,
    0.170000, 0.030000, 0.000000, 0.000000, 1.000000,
    0.000000, 0.140000, 0.160000, 0.030000, 1.000000,
    0.000000, 0.000000, 0.000000, 0.300000, 1.000000,
    0.000000, 0.000000, 0.000000, 0.150000, 1.000000,
    0.000000, 0.000000, 0.000000, 0.060000, 1.000000,
    0.000000, 0.000000, 0.000000, 1.000000, 1.000000,
    0.000000, 0.000000, 0.000000, 0.000000, 1.000000,
    0.240000, 0.000000, 0.710000, 0.140000, 1.000000,
    0.010000, 0.000000, 0.430000, 0.140000, 1.000000,
    0.000000, 0.000000, 0.000000, 0.000000, 1.000000,
    0.000000, 0.000000, 0.000000, 0.000000, 1.000000,
    0.000000, 0.000000, 0.000000, 0.000000, 1.000000,
    0.000000, 0.180000, 0.560000, 0.000000, 1.000000,
    0.000000, 0.000000, 0.000000, 1.000000, 1.000000
};

@implementation ASOCADController

@synthesize areaColorTransform;
@synthesize secondaryAreaColorTransform;
@synthesize ocadFilePath;

- (id)initWithOCADFile:(NSString *)_path {
    if ((self = [super init])) {

        if (![[NSFileManager defaultManager] fileExistsAtPath:_path]) {
            return nil;
        }
        
        ocdf = calloc(sizeof(struct ocad_file), 1);
        
        // Load the OCD file.
        if (!load_file(ocdf, [_path cStringUsingEncoding:NSUTF8StringEncoding])) {
            return nil;
        }
        load_symbols(ocdf);
        load_objects(ocdf);
        load_strings(ocdf);
        
#if TARGET_OS_IPHONE
        blackColor = [[UIColor blackColor] CGColor];
#else
        blackColor = CGColorCreateGenericCMYK(0.0,0.0,0.0,1.0,1.0);
#endif

        [self parseColors];
        [self parseScale];
        
        self.ocadFilePath = _path;

    
        currentBox = ocdf->bbox;
        
    }
    return self;
}

#if !TARGET_OS_IPHONE
int i;

- (void)loadAdditionalResourcesWithDelegate:(id <ASBackgroundImageLoaderDelegate>)_delegate {
    
    self.backgroundImages = [[NSMutableArray alloc] initWithCapacity:5];
    NSString *basePath = [self.ocadFilePath stringByDeletingLastPathComponent];
    for (i = 0; i < ocdf->num_strings; i++) {
        if (ocdf->string_rec_types[i] != 8) continue;
        NSArray *a = [[NSString stringWithCString:ocdf->strings[i] encoding:NSISOLatin1StringEncoding] componentsSeparatedByString:@"\t"];
        __block NSString *backgroundFileName = a[0];
        if ([backgroundFileName rangeOfString:@"\\"].location != NSNotFound) {
            backgroundFileName = [[backgroundFileName componentsSeparatedByString:@"\\"] lastObject];
        } else {
            backgroundFileName = [backgroundFileName lastPathComponent];
        }
        
        if ([_delegate isIgnoringFilename:backgroundFileName]) continue;

        NSURL *u = [_delegate resolvedURLBookmarkForFilename:backgroundFileName];
        
        if (u != nil) { // We have a bookmark. Use it.
            id <ASMapProvider> provider;
            [u startAccessingSecurityScopedResource];
            if ([[[[u path] pathExtension] lowercaseString] isEqualToString:@"ocd"] ) {
                provider = [[ASOCADController alloc] initWithOCADFile:[u path]];
                [(ASOCADController *)provider prepareCacheWithAreaTransform:self.areaColorTransform secondaryTransform:self.secondaryAreaColorTransform];
            } else {
                provider = [[ASGenericImageController alloc] initWithContentsOfFile:[u path]];
            }
            [u stopAccessingSecurityScopedResource];
            
            if (provider != nil) {
                [self.backgroundImages addObject:provider];
                NSNotification *n = [_delegate mapChangeNotification];
                if (n != nil) [[NSNotificationCenter defaultCenter] postNotification:n];
            }
        } else {
            dispatch_async([_delegate imageLoaderQueue], ^{
                dispatch_semaphore_wait([_delegate imageLoaderSequentializer], DISPATCH_TIME_FOREVER);
                if ([_delegate isIgnoringFilename:backgroundFileName]) {
                    dispatch_semaphore_signal([_delegate imageLoaderSequentializer]);
                } else {
                    
                    CGAffineTransform at = self.areaColorTransform;
                    CGAffineTransform at2 = self.secondaryAreaColorTransform;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSOpenPanel *op = [NSOpenPanel openPanel];
                        [op setAllowsMultipleSelection:NO];
                        [op setCanChooseDirectories:NO];
                        [op setDirectoryURL:[NSURL fileURLWithPath:basePath]];
                        [op setMessage:[NSString stringWithFormat:NSLocalizedString(@"Please locate the background file %@.", nil), backgroundFileName]];
                        [op setPrompt:NSLocalizedString(@"Choose", nil)];
                        
                        [op beginSheetModalForWindow:[_delegate modalWindow] completionHandler:^(NSInteger result) {
                            if (result != NSFileHandlingPanelOKButton) {
                                [_delegate ignoreFurtherRequestsForFile:backgroundFileName];
                            }
                            dispatch_semaphore_signal([_delegate imageLoaderSequentializer]);
                            if (result == NSFileHandlingPanelOKButton) {
                                id <ASMapProvider> secondProvider;
                                if ([[[[op URL] pathExtension] lowercaseString] isEqualToString:@"ocd"] ) {
                                    secondProvider = [[ASOCADController alloc] initWithOCADFile:[[op URL] path]];
                                    [(ASOCADController *)secondProvider prepareCacheWithAreaTransform:at secondaryTransform:at2];
                                    [(ASOCADController *)secondProvider loadAdditionalResourcesWithDelegate:_delegate];
                                } else {
                                    secondProvider = [[ASGenericImageController alloc] initWithContentsOfFile:[[op URL] path]];
                                }
                                
                                if (secondProvider != nil) {
                                    [_delegate addMapURL:[op URL] filename:backgroundFileName];
                                    [self.backgroundImages addObject:secondProvider];
                                    NSNotification *n = [_delegate mapChangeNotification];
                                    if (n != nil) [[NSNotificationCenter defaultCenter] postNotification:n];
                                }
                            }
                        }];
                    });
                }
            });
        }
    }
}

#endif

- (void)prepareCacheWithAreaTransform:(CGAffineTransform)transform {
    [self prepareCacheWithAreaTransform:transform secondaryTransform:CGAffineTransformIdentity];
}

- (void)prepareCacheWithAreaTransform:(CGAffineTransform)transform secondaryTransform:(CGAffineTransform)secondaryTransform {
    self.areaColorTransform = transform;
    self.secondaryAreaColorTransform = secondaryTransform;
    
    [self createAreaSymbolColors];
    [self createCache];
   
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:ocdf->num_symbols];
    for (int j = 0; j < ocdf->num_symbols; j++) {
        struct ocad_symbol *symbol = ocdf->symbols[j];
        NSInteger symNum = symbol->symnum / 1000;
        NSString *s = [[NSString alloc] initWithBytes:symbol->description length:symbol->desclength encoding:NSASCIIStringEncoding];
        BOOL alreadyInList = NO;
        for (NSDictionary *existingObject in ma) {
            if ([[existingObject valueForKey:@"number"] integerValue] == symNum) {
                alreadyInList = YES;
                break;
            }
        }
        if (!alreadyInList) [ma addObject:@{ @"number": @(symNum), @"name":s}];
    }
    self.symbolList = ma;
    
#if TARGET_OS_IPHONE
    free(ocdf);
    ocdf = NULL;
#endif
}

- (void)parseScale {
    int i;
    nativeScale = 15000.0; // Default if no scale is found.
    if (ocdf->header->version != 8) {
        for (i = 0; i < ocdf->num_strings; i++) {
            if (ocdf->string_rec_types[i] != 1039) {
                continue;
            }
            NSString *s = [NSString stringWithCString:ocdf->strings[i] encoding:NSISOLatin1StringEncoding];
            NSArray *a = [s componentsSeparatedByString:@"\t"];
            for (NSString *component in a) {
                if ([component hasPrefix:@"m"]) {
                    nativeScale = [[component substringFromIndex:1] doubleValue];
                }
            }
        }
    }
}

- (void)parseColors {
    int i, j, index, highest;
    CGFloat components[5];
    CFArrayCallBacks callbacks;
    
    callbacks.version = 0;
    callbacks.retain = &ColorRetain;
    callbacks.release = &ColorRelease;
    callbacks.copyDescription = NULL;
    callbacks.equal = NULL;
    
    highest = -1;
    if (ocdf->header->version != 8) {
        for (i = 0; i < ocdf->num_strings; i++) {
            if (ocdf->string_rec_types[i] != 9 && ocdf->string_rec_types[i] != 8) {
//                NSLog(@"string: %d %@", ocdf->string_rec_types[i], [NSString stringWithCString:ocdf->strings[i] encoding:NSISOLatin1StringEncoding]);
                continue;
            }
            NSString *s = [NSString stringWithCString:ocdf->strings[i] encoding:NSISOLatin1StringEncoding];
            NSArray *a = [s componentsSeparatedByString:@"\t"];
            for (NSString *component in a) {
                if ([component hasPrefix:@"n"]) {
                    index = [[component substringFromIndex:1] intValue];
                    if (index > highest) highest = index;
                } 
            }
        }
    } else {
        for (i = 0; i < ocdf->ocad8info->nColors; i++) {
            index = ocdf->ocad8info->colors[i].color_number;
            if (index > highest) highest = index;
        }
    }
    if (highest < 33) highest = 33;    
    
    colors = CFArrayCreateMutable(NULL, highest + 1, &callbacks);
    CGColorRef c;
    /* Set the default colors. */
#if TARGET_OS_IPHONE
    CGColorSpaceRef cspace = CGColorSpaceCreateDeviceCMYK();
#else
    CGColorSpaceRef cspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericCMYK);
#endif
    for (i = 0; i < 34;i++) {
        c = CGColorCreate(cspace, colorData + i*5);
        CFArraySetValueAtIndex(colors, i, c); CGColorRelease(c);
    }
    
    for (i = 34; i < highest + 1; i++) {
        CFArraySetValueAtIndex(colors, i, blackColor);
    }
    
    colorList = calloc(highest + 1, sizeof(int));
    j = 0;
        
    if (ocdf->header->version != 8) {
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
            
            // The ordering of the colors as they appear in the file is important. We need to sort the colors in this order.
            // Use a C array where the color index (0-33 or highest) lead to the ordinal.
            colorList[index] = j++;
            CFArraySetValueAtIndex(colors, index, CGColorCreate(cspace, components));
        }
    } else {
        for (i = 0; i < ocdf->ocad8info->nColors; i++) {
            struct ocad8_color_info *ci = ocdf->ocad8info->colors + i;
            index = ci->color_number;
            components[0] = 0.005*ci->cyan;
            components[1] = 0.005*ci->magenta;
            components[2] = 0.005*ci->yellow;
            components[3] = 0.005*ci->black;
            components[4] = 1.0;
            colorList[index] = j++;
            CFArraySetValueAtIndex(colors, index, CGColorCreate(cspace, components));            
        }
    }
    
    CGColorSpaceRelease(cspace);
    
}

- (void)dealloc {

    if (colors != NULL) CFRelease(colors);

    if (cachedDrawingInfo != NULL) {
        int i = 0;
        for (i = 0; i < num_cached_objects; i++) {
            if (cachedDrawingInfo[i].path != NULL) CGPathRelease(cachedDrawingInfo[i].path);
            if (cachedDrawingInfo[i].fillColor != NULL) CGColorRelease(cachedDrawingInfo[i].fillColor);
            if (cachedDrawingInfo[i].secondaryFillColor != NULL) CGColorRelease(cachedDrawingInfo[i].secondaryFillColor);
            if (cachedDrawingInfo[i].frame != NULL) CFRelease(cachedDrawingInfo[i].frame);
        }
        free(cachedDrawingInfo);
        cachedDrawingInfo = NULL;
    }
    if (ocdf != NULL) {
        free(ocdf);
        ocdf = NULL;
    }
    
    if (colorList != NULL) free(colorList);    
    if (blackColor != NULL) CGColorRelease(blackColor);
}

- (BOOL)supportsHiddenSymbolNumbers {
    return YES;
}

- (void)setHiddenSymbolNumbers:(const int32_t *)symbols count:(size_t)count {
    if (hiddenSymbols != NULL) {
        free(hiddenSymbols);
    }
    if (count > 0) {
        hiddenSymbols = calloc(count, sizeof(int32_t));
        memcpy(hiddenSymbols, symbols, count * sizeof(int32_t));
    } else {
        hiddenSymbols = NULL;
    }
    hiddenSymbolCount = count;
}

- (const int32_t *)hiddenSymbolNumbers:(size_t *)count {
    *count = hiddenSymbolCount;
    return hiddenSymbols;
}

- (CGRect)mapBounds {
    CGPathRef thePath;
	CGRect pathBounds;
	CGRect wholeMap = CGRectMake(0.0,0.0,0.0,0.0);
	BOOL firstSet = NO;
    int i;
    
	if (cachedDrawingInfo == NULL) return CGRectMake(currentBox.lower_left.x >> 8, currentBox.lower_left.y >> 8, (currentBox.upper_right.x >> 8) - (currentBox.lower_left.x >> 8), (currentBox.upper_right.y >> 8) - (currentBox.lower_left.y >> 8));
	
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
    
    for (id <ASMapProvider> bmap in self.backgroundImages) {
        wholeMap = CGRectUnion(wholeMap, [bmap mapBounds]);
    }

	return wholeMap;
}

- (NSInteger)symbolNumberAtPosition:(CGPoint)p {
	NSInteger i, bestIndex = NSNotFound;
    struct ocad_element *element;
    for (i = 0; i < num_cached_objects; i++) {
        element = sortedCache[i]->element;
        if ((element->obj_type == ocad_area_object ||
             element->obj_type == ocad_rectangle_object ||
             element->obj_type == ocad_point_object ||
             element->obj_type == ocad_line_object ) && 
            CGRectContainsPoint(sortedCache[i]->boundingBox, p)) {
            if (CGPathContainsPoint(sortedCache[i]->path, NULL, p, kCFBooleanTrue)) {
                bestIndex = i;
            }
        }
    }
    if (bestIndex != NSNotFound) {
        element = sortedCache[bestIndex]->element;
        return element->symnum / 1000;
    }
 
    for (id <ASMapProvider> background in self.backgroundImages) {
        i = [background symbolNumberAtPosition:p];
        if (i != NSNotFound) return i;
    }
    
    return NSNotFound;
}

- (NSArray *)createCacheFromIndex:(NSInteger)start upToButNotIncludingIndex:(NSInteger)stop step:(NSInteger)step {
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:10000];
    
    NSInteger i;
    struct ocad_element *e;
    enum ocad_object_type type;
	NSArray *a, *b;
	struct ocad_area_symbol *area;

    for (i = start; i < stop; i += step) {
        e = ocdf->elements[i];
        type = (enum ocad_object_type)(e->obj_type);
        if (e->symbol->csmode > 0) continue; // Don't render these.
		switch (type) {
			case ocad_area_object:
				area = (struct ocad_area_symbol *)(e->symbol);
				if (area) {
					[objects addObjectsFromArray:[self cachedDrawingInfoForAreaObject:e]];
				}
				break;
			case ocad_line_object:
				a = [self cachedDrawingInfoForLineObject:e];
                if ([a count] == 2) {
                    NSDictionary *mainLine = a[1];
                    [objects addObject:mainLine];
                }
				if ([a count] > 0) {
                    b = a[0];
                    for (NSDictionary *linePart in b) {
                        [objects addObject:linePart];
                    }
                }
				break;
			case ocad_rectangle_object:
                [objects addObject:[self cachedDrawingInfoForRectangleObject:e]];
				break;
			case ocad_point_object:
				[objects addObjectsFromArray:[self cachedDrawingInfoForPointObject:e]];
				break;
            case ocad_unformatted_text_object:
            case ocad_formatted_text_object:
            case ocad_line_text_object:
                [objects addObject:[self cachedDrawingInfoForTextObject:e]];
                break;
			default:
				break;
		}

    }

    return objects;
}

- (void)createCache {
    if (cachedDrawingInfo != NULL) {
        num_cached_objects = 0;
        free(cachedDrawingInfo);
        cachedDrawingInfo = NULL;
    }
    
    if (ocdf == NULL) return;
    
    NSMutableArray *invocations = [NSMutableArray arrayWithCapacity:4];
    NSMethodSignature *ms = [self methodSignatureForSelector:@selector(createCacheFromIndex:upToButNotIncludingIndex:step:)];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:CONCURRENCY];

    NSInteger i, num = ocdf->num_objects, start = 0, stop,step;
    for (i = 0; i < CONCURRENCY; i++) {
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:ms];
        [inv setTarget:self];
        [inv setSelector:@selector(createCacheFromIndex:upToButNotIncludingIndex:step:)];

        start = i;
        stop = num;
        step = CONCURRENCY;
        [inv setArgument:&start atIndex:2];
        [inv setArgument:&stop atIndex:3];
        [inv setArgument:&step atIndex:4];
        NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithInvocation:inv];
        [invocations addObject:op];
        [queue addOperation:op];
    }
        
    [queue waitUntilAllOperationsAreFinished];
    
    // Count the number of objects.
    NSInteger frags = 0, j;

    for (NSInvocationOperation *op in invocations) {
        frags += [[op result] count];
    }

    cachedDrawingInfo = calloc(frags, sizeof(struct ocad_cache));
    if (cachedDrawingInfo == NULL) {
        return;
    }
    
    // OCAD8: does not return a consistent number of num_cached_objects.
    // Indicates that we are reading from somewhere we shouldn't, or not filling the correct memory.
    
    j = 0;
    for (NSInvocationOperation *op in invocations) { 
        NSArray *items= [op result];
        for (NSDictionary *item in items) {
            cachedDrawingInfo[j].fillColor = (__bridge CGColorRef)item[@"fillColor"];
            cachedDrawingInfo[j].secondaryFillColor = (__bridge CGColorRef)item[@"2ndFillColor"];
           
            if (item[@"fillMode"]) {
                cachedDrawingInfo[j].fillMode = (enum CGPathDrawingMode)[item[@"fillMode"] intValue];
            } else {
                cachedDrawingInfo[j].fillMode = kCGPathFill;
            }
            cachedDrawingInfo[j].path = (__bridge CGPathRef)item[@"path"];
            cachedDrawingInfo[j].frame  =(__bridge CTFrameRef)item[@"frame"];
            cachedDrawingInfo[j].angle = [item[@"angle"] doubleValue];
            cachedDrawingInfo[j].midpoint = CGPointMake([item[@"midX"] doubleValue], [item[@"midY"] doubleValue]);
            cachedDrawingInfo[j].element = [item[@"element"] pointerValue];
            cachedDrawingInfo[j].colornum = [item[@"colornum"] intValue];

            if (cachedDrawingInfo[j].path != NULL) CGPathRetain(cachedDrawingInfo[j].path);
            if (cachedDrawingInfo[j].fillColor != NULL) CGColorRetain(cachedDrawingInfo[j].fillColor);
            if (cachedDrawingInfo[j].secondaryFillColor != NULL) CGColorRetain(cachedDrawingInfo[j].secondaryFillColor);
            if (cachedDrawingInfo[j].frame != NULL) CFRetain(cachedDrawingInfo[j].frame);
            if (cachedDrawingInfo[j].path != NULL) {
                cachedDrawingInfo[j].boundingBox = CGPathGetBoundingBox(cachedDrawingInfo[j].path);
            }
            j++;
            
        }
    }
    
    num_cached_objects = (int)frags;
    sortedCache = calloc(num_cached_objects, sizeof(struct ocad_cache *));
    for (i = 0; i < num_cached_objects; i++)
        sortedCache[i] = cachedDrawingInfo + i;
    
    psort_b(sortedCache, num_cached_objects, sizeof(struct ocad_cache *), ^(const void *o1, const void *o2) {
        struct ocad_cache *c1 = *(struct ocad_cache **)o1;
        struct ocad_cache *c2 = *(struct ocad_cache **)o2;
        return colorList[c2->colornum] - colorList[c1->colornum];
    });
}

- (NSArray *)cachedDrawingInfoForPointObject:(struct ocad_element *)e {
    struct ocad_point_symbol *point = (struct ocad_point_symbol *)(e->symbol);

    if (point == NULL || point->status == 2) return @[];
    
    float angle = 0.0;
    if (e->angle != -1) angle = ((float)(e->angle)) / 10.0 * M_PI / 180.0;
    return [self cacheSymbolElements:(struct ocad_symbol_element *)(point->points) 
                             atPoint:CGPointMake(e->coords[0].x >> 8, e->coords[0].y >> 8) 
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
        CGPathRef strokedPath = CGPathCreateCopyByStrokingPath(p, NULL, rect->line_width, kCGLineCapButt, kCGLineJoinBevel, 0.5*((float)rect->line_width));
        d = @{@"fillColor": (__bridge id)color, @"path": (__bridge id)strokedPath,
             @"element": [NSValue valueWithPointer:e], 
             @"colornum": [NSNumber numberWithInt:e->color]};
        CGPathRelease(strokedPath);
    } else {
		d = @{@"fillColor": (__bridge id)color, 
             (id)@"path": (__bridge id)p, 
             @"element": [NSValue valueWithPointer:e],
             @"colornum": [NSNumber numberWithInt:e->color]};
	}
	CGPathRelease(p);
	
	return d;
}

- (NSArray *)cacheSymbolElements:(struct ocad_symbol_element *)se atPoint:(CGPoint)origin withAngle:(float)angle totalDataSize:(uint16_t)data_size {
    return [self cacheSymbolElements:se atPoint:origin withAngle:angle totalDataSize:data_size element:NULL];
}

- (NSArray *)cacheSymbolElements:(struct ocad_symbol_element *)se atPoint:(CGPoint)origin withAngle:(float)angle totalDataSize:(uint16_t)data_size element:(struct ocad_element *)element {
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
                CGPathRef strokedPath = CGPathCreateCopyByStrokingPath(path, NULL, se->line_width, kCGLineCapButt, kCGLineJoinBevel, 0.5*((float)se->line_width));
				
                [cache addObject:@{@"fillColor": (__bridge id)color, @"path": (__bridge id)strokedPath,
                                  @"element": [NSValue valueWithPointer:element],
                                  @"colornum": [NSNumber numberWithInt:se->color]}];
                CGPathRelease(strokedPath);
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
                [cache addObject:@{@"fillColor": (__bridge id)color, @"path": (__bridge id)path,
                                  @"colornum": [NSNumber numberWithInt:se->color],
                                  @"element": [NSValue valueWithPointer:element]}];
                break;
            case 3:
            case 4: /* Dot. */
				CGPathAddEllipseInRect(path, &at, CGRectMake(-(se->diameter / 2) + (se->points[0].x >> 8), -(se->diameter / 2) + (se->points[0].y >> 8), se->diameter, se->diameter));
                if (se->symbol_type == 3) {
                    CGPathRef strokedPath = CGPathCreateCopyByStrokingPath(path, NULL, se->line_width, kCGLineCapButt, kCGLineJoinBevel, 0.5*((float)se->line_width));
					[cache addObject:@{@"fillColor": (__bridge id)color, @"path": (__bridge id)strokedPath,
                                      @"colornum": [NSNumber numberWithInt:se->color],
                                      @"element": [NSValue valueWithPointer:element]}];
                    CGPathRelease(strokedPath);
                } else {
                    [cache addObject:@{@"fillColor": (__bridge id)color, @"path": (__bridge id)path,
                                      @"colornum": [NSNumber numberWithInt:se->color],
                                      @"element": [NSValue valueWithPointer:element]}];
                }
                break;
            default:
                break;
        }
        int nc = se->ncoords;
        se_index += nc + 2;
        se ++;
        se = (struct ocad_symbol_element *)(((struct TDPoly *)se) + nc);
        CGPathRelease(path);
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

// CATiledLayer delegate stuff. Also used by the quicklook plugin.
// In the latter case, layer will be NULL.

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    [self drawLayer:layer inContext:ctx useSecondaryTransform:NO];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx useSecondaryTransform:(BOOL)useSecondaryTransform {
    ASOCADController *dest;
    if (masterController != nil) {
        dest = masterController;
    } else {
        dest = self;
    }
    for (id <ASMapProvider> background in dest.backgroundImages) {
        [background drawLayer:layer inContext:ctx useSecondaryTransform:useSecondaryTransform];
    }
    CGContextSetTextDrawingMode(ctx, kCGTextFill);
    int i, j2, j3;
    struct ocad_cache *cache;
    CGRect clipBox = CGContextGetClipBoundingBox(ctx);
    
    for (i = 0; i < dest->num_cached_objects; i++) {
        cache = dest->sortedCache[i];
        if (hiddenSymbolCount) {
            j3 = cache->element->symnum / 1000;
            for (j2 = 0; j2 < hiddenSymbolCount && hiddenSymbols[j2] != j3; j2++);
            
            if (j2 != hiddenSymbolCount) continue;
        }
        
        CGPathRef path = cache->path;
        CGColorRef fillColor = (useSecondaryTransform && cache->secondaryFillColor)?(cache->secondaryFillColor):(cache->fillColor);
        CGPathDrawingMode fillMode = cache->fillMode;
        CTFrameRef frame = cache->frame;
        CGRect bb = cache->boundingBox;
        if (CGRectIntersectsRect(bb, clipBox)) {
            CGContextBeginPath(ctx);
            CGContextAddPath(ctx,path);
            if (fillColor != NULL) {
                CGContextSetFillColorWithColor(ctx, fillColor);
                if (fillMode == kCGPathEOFill) {
                    CGContextEOFillPath(ctx);
                } else {                    
                    CGContextFillPath(ctx);
                }
            }
            if (frame != NULL) {
                CGContextSaveGState(ctx);

                CGFloat alpha = cache->angle*M_PI/180.0;
                if (alpha != 0.0) {
                    CGPoint m = cache->midpoint;
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

- (ASOCADController *)layoutProxy {
    if (self._layoutProxy == nil) {
        ASOCADController *p = [[ASOCADController alloc] init];
        p->masterController = self;
        self._layoutProxy = p;
    }
    return self._layoutProxy;
}

- (CGFloat)nativeScale {
    return nativeScale;
}

- (void)loadOverprintObjects:(id (^)(CGFloat position_x, CGFloat position_y, enum ASOverprintObjectType otp, NSInteger controlCode, enum ASWhichOfAnySimilarFeature which, enum ASFeature feature, enum ASAppearance appearance,  enum ASDimensionsOrCombination dim, enum ASLocationOfTheControlFlag flag, enum ASOtherInformation other))objectHandler courses:(void (^)(NSString *name, NSArray *overprintObjects))courseHandler {

    int i;
    if (ocdf->header->filetype != 1) { // Course setting project
        return;
    }
    
    NSDictionary *colD = @{@"1.1": @(kASFeatureTerrace),
                           @"1.2": @(kASFeatureSpur),
                           @"1.3": @(kASFeatureRe_Entrant),
                           @"1.4": @(kASFeatureEarthBank),
                           @"1.5": @(kASFeatureEarthWall),
                           @"1.6": @(kASFeatureQuarry),
                           @"1.7": @(kASFeatureErosionGully),
                           @"1.8": @(kASFeatureSmallErosionGully),
                           @"1.9": @(kASFeatureHill),
                           @"1.10": @(kASFeatureKnoll),
                           @"1.11": @(kASFeatureSaddle),
                           @"1.12": @(kASFeatureDepression),
                           @"1.13": @(kASFeatureSmallDepression),
                           @"1.14": @(kASFeaturePit),
                           @"1.15": @(kASFeatureBrokenGround),
                           @"1.16": @(kASFeatureAntHill),
                           @"2.1": @(kASFeatureCliff),
                           @"2.2": @(kASFeatureRockPillar),
                           @"2.3": @(kASFeatureCave),
                           @"2.4": @(kASFeatureBoulder),
                           @"2.5": @(kASFeatureBoulderField),
                           @"2.6": @(kASFeatureBoulderCluster),
                           @"2.7": @(kASFeatureStonyGround),
                           @"2.8": @(kASFeatureBareRock),
                           @"2.9": @(kASFeatureNarrowPassage),
                           @"3.1": @(kASFeatureLake),
                           @"3.2": @(kASFeaturePond),
                           @"3.3": @(kASFeatureWaterhole),
                           @"3.4": @(kASFeatureStream),
                           @"3.5": @(kASFeatureDitch),
                           @"3.6": @(kASFeatureNarrowMarch),
                           @"3.7": @(kASFeatureMarch),
                           @"3.8": @(kASFeatureFirmGroundInMarch),
                           @"3.9": @(kASFeatureWell),
                           @"3.10": @(kASFeatureSpring),
                           @"3.11": @(kASFeatureWaterTrough),
                           @"4.1": @(kASFeatureOpenLand),
                           @"4.2": @(kASFeatureSemiOpenLand),
                           @"4.3": @(kASFeatureForestCorner),
                           @"4.4": @(kASFeatureClearing),
                           @"4.5": @(kASFeatureThicket),
                           @"4.6": @(kASFeatureLinearThicket),
                           @"4.7": @(kASFeatureVegetationBoundary),
                           @"4.8": @(kASFeatureCopse),
                           @"4.9": @(kASFeatureDistinctiveTree),
                           @"4.10": @(kASFeatureTreeStumpOrRootStock),
                           @"5.1": @(kASFeatureRoad),
                           @"5.2": @(kASFeatureTrack),
                           @"5.3": @(kASFeatureRide),
                           @"5.4": @(kASFeatureBridge),
                           @"5.4": @(kASFeatureBridge),
                           @"5.5": @(kASFeaturePowerLine),
                           @"5.6": @(kASFeaturePowerLinePylon),
                           @"5.7": @(kASFeatureTunnel),
                           @"5.8": @(kASFeatureStoneWall),
                           @"5.9": @(kASFeatureFence),
                           @"5.10": @(kASFeatureCrossingPoint),
                           @"5.11": @(kASFeatureBuilding),
                           @"5.12": @(kASFeaturePavedArea),
                           @"5.13": @(kASFeatureRuin),
                           @"5.14": @(kASFeaturePipeline),
                           @"5.15": @(kASFeatureTower),
                           @"5.16": @(kASFeatureShootingPlatform),
                           @"5.17": @(kASFeatureCairn),
                           @"5.18": @(kASFeatureFodderRack),
                           @"5.19": @(kASFeatureCharcoalBurningGround),
                           @"5.20": @(kASFeatureMonument),
                           @"5.21": @(kASFeatureBuildingPassThrough),
                           @"5.22": @(kASFeatureStairway)};
    NSDictionary *colE = @{@"8.1": @(kASAppearanceLow),
                           @"8.2": @(kASAppearanceShallow),
                           @"8.3": @(kASAppearanceDeep),
                           @"8.4": @(kASAppearanceOvergrown),
                           @"8.5": @(kASAppearanceOpen),
                           @"8.6": @(kASAppearanceRocky),
                           @"8.7": @(kASAppearanceMarshy),
                           @"8.8": @(kASAppearanceSandy),
                           @"8.9": @(kASAppearanceNeedleLeaves),
                           @"8.10": @(kASAppearanceBroadLeaves),
                           @"8.11": @(kASAppearanceRuined)};
    NSDictionary *colF = @{@"10.1": @(kASCombinationCrossing),
                           @"10.2": @(kASCombinationJunction)};
    
    NSMutableDictionary *overprintObjects = [NSMutableDictionary dictionaryWithCapacity:200];
    for (i = 0; i < ocdf->num_strings; i++) {
        if (ocdf->string_rec_types[i] != 1) {
            continue;
        }
        NSString *s = [NSString stringWithCString:ocdf->strings[i] encoding:NSISOLatin1StringEncoding];
        NSArray *a = [[s lowercaseString] componentsSeparatedByString:@"\t"];
        enum ASOverprintObjectType type;
        NSInteger controlCode = 0;
        enum ASWhichOfAnySimilarFeature which = kASFeatureNotSpecified;
        enum ASFeature feature = kASFeatureNone;
        enum ASAppearance appearance = (enum ASAppearance)kASFeatureNone;
        enum ASDimensionsOrCombination dim = kASCombinationNone;
        enum ASLocationOfTheControlFlag flag = kASLocationNone;
        enum ASOtherInformation other = kASOtherInformationNone;

        BOOL validType = NO;
        for (NSString *component in a) {
            /*
             // First = Code
             // Y = Type (s=start, c=control, m=marked route, f=finish, d=control description,
             //           n=course title, u=start number, v=variation code, t=text block)
             // b = Symbol for field B (Trail-O, Macr-O, Micr-O)
             // c = Symbol for field C
             // d = Symbol for field D
             // e = Symbol for field E
             // f = Symbol for field F
             // g = Symbol for field G
             // h = Symbol for field H
             // mf = Funnel tapes
             // ot = Text control description object
             // s = Size information
             // t = Text for text description or text for text block
             // u = evelation user [double]
             // v = is evelation user used [boolean]*/
            if ([component hasPrefix:@"y"]) {
                validType = YES;
                const char *typeStr = [[component substringWithRange:NSMakeRange(1, 1)] cStringUsingEncoding:NSASCIIStringEncoding];
                switch (typeStr[0]) {
                    case 's':
                        type = kASOverprintObjectStart;
                        break;
                    case 'c':
                        type = kASOverprintObjectControl;
                        break;
                    case 'm':
                        type = kASOverprintObjectTapedRouteBetweenControls;
                        break;
                    case 'f':
                        type = kASOverprintObjectFinish;
                        break;
                    default:
                        validType = NO;
                        break;
                };
            } else if ([component hasPrefix:@"d"]) {
                feature = (enum ASFeature)[[colD objectForKey:[component substringFromIndex:1]] integerValue];
            } else if ([component hasPrefix:@"e"]) {
                NSNumber *n = [colD objectForKey:[component substringFromIndex:1]];
                if (n != nil) {
                    appearance = (enum ASAppearance)[n integerValue];
                } else {
                    appearance = (enum ASAppearance)[[colE objectForKey:[component substringFromIndex:1]] integerValue];
                    
                }
            } else if ([component hasPrefix:@"f"]) {
                dim = (enum ASDimensionsOrCombination)[[colF objectForKey:[component substringFromIndex:1]] integerValue];
            }
        }
        if (validType && type == kASOverprintObjectControl) {
            controlCode = [a[0] integerValue];
        }
        
        if (validType) {
            
            // Get the element location.
            struct ocad_element *e = element_by_index(ocdf, ocdf->string_obj_indices[i]);
            id o = objectHandler((CGFloat)(e->coords[0].x >> 8), (CGFloat)(e->coords[0].y >> 8),
                                 type, controlCode, which, feature, appearance, dim, flag, other);
            [overprintObjects setObject:o forKey:a[0]];
        }
        
    }
    
    // Now look at the courses.
    for (i = 0; i < ocdf->num_strings; i++) {
        if (ocdf->string_rec_types[i] != 2) {
            continue;
        }
        NSString *s = [NSString stringWithCString:ocdf->strings[i] encoding:NSISOLatin1StringEncoding];
        NSArray *a = [s componentsSeparatedByString:@"\t"];
        NSMutableArray *oo = [NSMutableArray arrayWithCapacity:50];
        for (NSString *component in a) {
            id x = [overprintObjects objectForKey:[[component substringFromIndex:1] lowercaseString]];
            if (x != nil) {
                [oo addObject:x];
            }
        }
        courseHandler(a[0], oo);
    }
}

- (BOOL)hasCourseInformation {
    return ocdf->header->filetype == 1;
}

@end
