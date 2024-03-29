//
//  ASOCADController_Line.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-06-26.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASOCADController.h"

@class CoordinateTransverser;

@interface ASOCADController (ASOCADController_Line)

- (NSArray *)cachedDrawingInfoForLineObject:(struct ocad_element *)e;
- (void)traverse:(CoordinateTransverser *)ct distance:(float)length withSecondaryGapLength:(float)sec_gap;

@end

