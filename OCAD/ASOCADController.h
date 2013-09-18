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
#if TARGET_OS_IPHONE
#import <CoreText/CoreText.h>
#endif

#if __has_feature(attribute_objc_ivar_unused)
#define UNUSED_IVAR __attribute__((unused))
#else
#define UNUSED_IVAR
#endif

struct ocad_cache {
    CGRect      boundingBox;       // The path bounding box is cached because determining it is a fairly expensive operation.
    CGPathRef   path;              
    CGColorRef  fillColor;          // Fill color if the path is to be filled.
    CGColorRef  secondaryFillColor; // Fill color for a secondary pattern transform.
    
    CGPathDrawingMode fillMode;
    CTFrameRef  frame;              // A text frame (text objects only).
    CGPoint     midpoint;           // The frame midpoint, about which rotations apply (text objects only).
    
    struct ocad_element *element;   // The OCAD element. Used for hittesting.
    int         colornum;           // Color. Used to sort the cache by color.
    CGFloat     angle;              // Angle (degrees). Used to rotate text objects and to rotate the pattern matrix for areas.    

};

@interface ASOCADController : NSObject <ASMapProvider
#if !TARGET_OS_IPHONE
, NSMetadataQueryDelegate
#endif
> {
@private
    struct  ocad_cache *cachedDrawingInfo;
    struct  ocad_cache **sortedCache;
    int     num_cached_objects;

    NSString *ocd_path UNUSED_IVAR;
    struct ocad_file *ocdf;
    
    struct LRect currentBox;
    
    CFMutableArrayRef colors;
    CGColorRef blackColor;
    int *colorList;
    
    NSMutableDictionary *structureColors UNUSED_IVAR;
    NSMutableDictionary *hatchColors UNUSED_IVAR;
    NSMutableDictionary *secondaryHatchColors UNUSED_IVAR;

    NSMutableDictionary *transformedStructureColors UNUSED_IVAR;
    NSMutableDictionary *transformedHatchColors UNUSED_IVAR;
    NSMutableDictionary *transformedSecondaryHatchColors UNUSED_IVAR;

    int32_t     *hiddenSymbols;
    size_t      hiddenSymbolCount;

    NSMutableArray *backgroundImages;
    NSMutableArray *spotlightQueries;
    
    CGAffineTransform areaColorTransform;
    CGAffineTransform secondaryAreaColorTransform;
    NSString *ocadFilePath;
    
    ASOCADController *masterController;
}
@property(nonatomic,assign) CGAffineTransform areaColorTransform;
@property(nonatomic,assign) CGAffineTransform secondaryAreaColorTransform;
@property(nonatomic,strong) NSString *ocadFilePath;
@property(nonatomic, strong) NSArray *symbolList;
@property(nonatomic,strong) ASOCADController *_layoutProxy;

- (id)initWithOCADFile:(NSString *)path;
- (void)prepareCacheWithAreaTransform:(CGAffineTransform)transform;
- (void)prepareCacheWithAreaTransform:(CGAffineTransform)transform secondaryTransform:(CGAffineTransform)secondaryTransform;

#if !TARGET_OS_IPHONE
- (void)loadBackgroundImagesRelativeToPath:(NSString *)basePath;
#endif
- (void)parseColors;
- (CGColorRef)colorWithNumber:(int)color_number;

- (NSArray *)createCacheFromIndex:(NSInteger)start upToButNotIncludingIndex:(NSInteger)stop step:(NSInteger)step;
- (void)createCache;

- (NSArray *)cachedDrawingInfoForPointObject:(struct ocad_element *)e;
- (NSDictionary *)cachedDrawingInfoForRectangleObject:(struct ocad_element *)e;
- (NSArray *)cacheSymbolElements:(struct ocad_symbol_element *)se atPoint:(CGPoint)origin withAngle:(float)angle totalDataSize:(uint16_t)data_size;
- (NSArray *)cacheSymbolElements:(struct ocad_symbol_element *)se atPoint:(CGPoint)origin withAngle:(float)angle totalDataSize:(uint16_t)data_size element:(struct ocad_element *)element;


@end
