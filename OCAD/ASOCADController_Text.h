//
//  ASOCADController_Text.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-06-26.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASOCADController.h"

@interface ASOCADController (ASOCADController_Text)

- (NSDictionary *)cachedDrawingInfoForTextObject:(struct ocad_element *)e;

@end
