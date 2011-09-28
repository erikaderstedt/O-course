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
    CGRect      boundingBox;       // The path bounding box is cached because determining it is a fairly expensive operation.
    CGPathRef   path;              
    CGColorRef  fillColor;          // Fill color if the path is to be filled.
    CGColorRef  strokeColor;        // Stroke color if the path should be stroked.
    CTFrameRef  frame;              // A text frame (text objects only).
    CGPoint     midpoint;           // The frame midpoint, about which rotations apply (text objects only).
    
    CGLineCap   capStyle;           // Line cap style (lines only).
    CGLineJoin  joinStyle;          // Line join style (lines only).
    CGFloat     width;              // Line width (lines only).
    
    struct ocad_element *element;   // The OCAD element. Used for hittesting.
    int         colornum;           // Color. Used to sort the cache by color.
    CGFloat     angle;              // Angle (degrees). Used to rotate text objects and to rotate the pattern matrix for areas.    
};

@interface ASOCADController : NSObject <ASMapProvider> {
@private
    struct  ocad_cache *cachedDrawingInfo;
    struct  ocad_cache **sortedCache;
    int     num_cached_objects;

    NSString *ocd_path;
    struct ocad_file *ocdf;
    
    struct LRect *boundingBox;
    struct LRect currentBox;
    
    CFMutableArrayRef colors;
    CGColorRef blackColor;
    int *colorList;
    
    NSMutableDictionary *structureColors;
    NSMutableDictionary *hatchColors;
    NSMutableDictionary *secondaryHatchColors;
    
    NSMutableArray *backgroundImages;
}
- (id)initWithOCADFile:(NSString *)path;
- (void)loadBackgroundImagesRelativeToPath:(NSString *)basePath;
- (void)parseColorStrings;
- (CGColorRef)colorWithNumber:(int)color_number;

- (NSArray *)createCacheFromIndex:(NSInteger)start upToButNotIncludingIndex:(NSInteger)stop step:(NSInteger)step;
- (void)createCache;

- (NSArray *)cachedDrawingInfoForPointObject:(struct ocad_element *)e;
- (NSDictionary *)cachedDrawingInfoForRectangleObject:(struct ocad_element *)e;
- (NSArray *)cacheSymbolElements:(struct ocad_symbol_element *)se atPoint:(NSPoint)origin withAngle:(float)angle totalDataSize:(uint16_t)data_size;
- (NSArray *)cacheSymbolElements:(struct ocad_symbol_element *)se atPoint:(NSPoint)origin withAngle:(float)angle totalDataSize:(uint16_t)data_size element:(struct ocad_element *)element;

+ (NSPoint)translatePoint:(NSPoint)p distance:(float)distance angle:(float)angle;

@end
