//
//  ASOCADController_Area.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-06-26.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASOCADController.h"

void drawHatched (void * info, CGContextRef context);
void drawStructured(void *info, CGContextRef context);
void releaseInfoStructure(void *info);

@interface ASOCADController (ASOCADController_Area)

- (NSArray *)cachedDrawingInfoForAreaObject:(struct ocad_element *)e;
- (void)createAreaSymbolColors;
- (void)createStructureColors;
- (void)createHatchColors;
- (void)createSecondaryHatchColors;

- (NSArray *)hatchColorsForSymbol:(struct ocad_area_symbol *)a index:(int)index;
- (NSArray *)structureColorsForSymbol:(struct ocad_area_symbol *)a;

@end
