//
//  ASCourseObject.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-14.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ASCourseObject <NSObject>

- (CGPoint)position;
- (void)setPosition:(CGPoint)newPosition;

@end
