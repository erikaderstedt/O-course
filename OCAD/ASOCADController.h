//
//  ASOCADController.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-02.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import "ASMapProvider.h"
#import "ocdimport.h"

void ColorRelease (CFAllocatorRef allocator,const void *value);
CFArrayRef olorArray();
void draw211 (void * info,CGContextRef context);
void draw309 (void * info,CGContextRef context);
void draw310 (void * info,CGContextRef context);
void draw311 (void * info,CGContextRef context);
void draw402 (void * info,CGContextRef context);
void draw404 (void * info,CGContextRef context);
void draw407or409 (void * info,CGContextRef context);
void draw412 (void * info,CGContextRef context);
void draw413 (void * info,CGContextRef context);
void draw415 (void * info, CGContextRef context);
void drawUnknown( void *info, CGContextRef context);
void draw528 (void * info, CGContextRef context);
void draw709 (void * info, CGContextRef context);

@interface ASOCADController : NSObject <ASMapProvider> {
@private
  	NSMutableArray *cachedDrawingInformation;

    NSString *ocd_path;
    struct ocad_file *ocdf;
    
    struct LRect *boundingBox;
    struct LRect currentBox;
    
    NSArray *colors;
    CGColorRef blackColor;
    NSMutableDictionary *areaSymbolColors;
	
	NSOperationQueue *renderingQueue;
}
- (id)initWithOCADFile:(NSString *)path;

- (void)createAreaSymbolColors;
- (CGColorRef)colorWithNumber:(int)color_number;

- (NSArray *)createCacheFromIndex:(NSInteger)start upToButNotIncludingIndex:(NSInteger)stop;
- (void)createCache;

- (NSDictionary *)cachedDrawingInfoForAreaObject:(struct ocad_element *)e;
- (NSArray *)cachedDrawingInfoForPointObject:(struct ocad_element *)e;
- (NSDictionary *)cachedDrawingInfoForRectangleObject:(struct ocad_element *)e;
- (NSArray *)cachedDrawingInfoForLineObject:(struct ocad_element *)e;
- (NSArray *)cacheSymbolElements:(struct ocad_symbol_element *)se atPoint:(NSPoint)origin withAngle:(float)angle totalDataSize:(uint16_t)data_size;

+ (float)angleBetweenPoint:(NSPoint)p1 andPoint:(NSPoint)p2;
+ (float)angleForCoords:(struct TDPoly *)coords ofLength:(int)total atIndex:(int)i;
+ (NSPoint)translatePoint:(NSPoint)p distance:(float)distance angle:(float)angle;

@end
