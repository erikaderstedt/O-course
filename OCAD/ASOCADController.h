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

struct ocad_cache {
    CGRect      boundingBox;
    CGPathRef   path;
    CGColorRef  fillColor;
    CGColorRef  strokeColor;
    CTFrameRef  frame;
    CGLineCap   capStyle;
    CGLineJoin  joinStyle;
    CGFloat     width;
    struct ocad_symbol *symbol;
    CGFloat     angle;
    CGPoint     midpoint;
    
    CGFloat     dashes[4];
    int         num_dashes;
};

@interface ASOCADController : NSObject <ASMapProvider> {
@private
    struct  ocad_cache *cachedDrawingInfo;
    int     num_cached_objects;

    NSString *ocd_path;
    struct ocad_file *ocdf;
    
    struct LRect *boundingBox;
    struct LRect currentBox;
    
    CFMutableArrayRef colors;
    CGColorRef blackColor;
    NSMutableDictionary *areaSymbolColors;
}
- (id)initWithOCADFile:(NSString *)path;
- (void)parseColorStrings;
- (CGColorRef)colorWithNumber:(int)color_number;

- (NSArray *)createCacheFromIndex:(NSInteger)start upToButNotIncludingIndex:(NSInteger)stop;
- (void)createCache;

- (NSArray *)cachedDrawingInfoForPointObject:(struct ocad_element *)e;
- (NSDictionary *)cachedDrawingInfoForRectangleObject:(struct ocad_element *)e;
- (NSArray *)cacheSymbolElements:(struct ocad_symbol_element *)se atPoint:(NSPoint)origin withAngle:(float)angle totalDataSize:(uint16_t)data_size;
- (NSArray *)cacheSymbolElements:(struct ocad_symbol_element *)se atPoint:(NSPoint)origin withAngle:(float)angle totalDataSize:(uint16_t)data_size symbol:(struct ocad_symbol *)symbol;

+ (float)angleBetweenPoint:(NSPoint)p1 andPoint:(NSPoint)p2;
+ (float)angleForCoords:(struct TDPoly *)coords ofLength:(int)total atIndex:(int)i;
+ (NSPoint)translatePoint:(NSPoint)p distance:(float)distance angle:(float)angle;

@end
