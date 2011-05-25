//
//  ASOCADController.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-02.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASMapProvider.h"
#import "ocdimport.h"

@interface ASOCADController : NSObject <ASMapProvider> {
@private
  	NSMutableArray *cachedDrawingInformation;

    NSString *ocd_path;
    struct ocad_file *ocdf;
    
    struct LRect *boundingBox;
    struct LRect currentBox;
    
    NSArray *colors;
    NSMutableDictionary *areaSymbolColors;
	
	NSOperationQueue *renderingQueue;
}
- (id)initWithOCADFile:(NSString *)path;

- (NSImage *)patternImageForSymbolNumber:(int)symbol;
- (void)createAreaSymbolColors;
- (NSColor *)colorWithNumber:(int)color_number;

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
