//
//  ASOverprintProvider.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-14.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASCourseObject.h"

@protocol ASOverprintProvider <NSObject>

- (id <ASCourseObject>)courseObjectAtPosition:(CGPoint)position;
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx;

@end
