//
//  ASCourseObject.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-14.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>

enum ASCourseObjectType {
    kASCourseObjectStart,
    kASCourseObjectControl,
    kASCourseObjectFinish,
};

@protocol ASCourseObject <NSObject>

- (CGPoint)position;
- (void)setPosition:(CGPoint)newPosition;

@end

@protocol ASCourseDelegate <NSObject>

- (BOOL)addCourseObject:(enum ASCourseObjectType)objectType atLocation:(CGPoint)location symbolNumber:(NSInteger)symbolNumber;

@end
