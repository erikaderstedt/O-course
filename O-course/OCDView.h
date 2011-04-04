//
//  OCDView.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-02-13.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ocdimport.h"


@interface OCDView : NSView {
@private
    NSString *ocd_path;
    struct ocad_file *ocdf;
    
    struct LRect *boundingBox;
    struct LRect currentBox;
    
    NSPoint mouseDownPoint;
    
    NSArray *colors;
    
    NSMutableDictionary *areaSymbolColors;
}
@property(nonatomic,retain) NSString *ocdPath;

- (NSImage *)patternImageForSymbolNumber:(int)symbol;
- (void)createAreaSymbolColors;

- (void)setColorWithNumber:(int)color_number;

+ (float)angleBetweenPoint:(NSPoint)p1 andPoint:(NSPoint)p2;
+ (float)angleForCoords:(struct TDPoly *)coords ofLength:(int)total atIndex:(int)i;
+ (NSPoint)translatePoint:(NSPoint)p distance:(float)distance angle:(float)angle;

- (void)drawSymbolElements:(struct ocad_symbol_element *)coords atPoint:(NSPoint)p withAngle:(float)angle totalDataSize:(uint16_t)data_size;

- (NSAffineTransform *)currentTransform;

- (void)drawOcadPointObject:(struct ocad_element *)e;
- (void)drawOcadRectangleObject:(struct ocad_element *)e;
- (void)drawOcadLineObject:(struct ocad_element *)e;
- (void)drawOcadAreaObject:(struct ocad_element *)e;
@end
