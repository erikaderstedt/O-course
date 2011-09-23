//
//  ASOCADController_Area.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-06-26.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASOCADController.h"

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
void drawHatched (void * info, CGContextRef context);


@interface ASOCADController (ASOCADController_Area)

- (NSArray *)cachedDrawingInfoForAreaObject:(struct ocad_element *)e;
- (void)createAreaSymbolColors;
- (CGColorRef)areaColorForSymbol:(struct ocad_area_symbol *)a transform:(CGAffineTransform)transform;
- (CGColorRef)hatchColorForSymbol:(struct ocad_area_symbol *)a index:(int)index;
@end
