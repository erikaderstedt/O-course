//
//  CourseObject.h
//  O-course
//
//  Created by Erik Aderstedt on 2013-07-20.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ASControlDescriptionProvider.h"

@class Course, OverprintObject;

@interface CourseObject : NSManagedObject <ASControlDescriptionItem, ASEditableControlDescriptionItem>

@property (nonatomic) double position_x;
@property (nonatomic) double position_y;
@property (nonatomic) BOOL manualPosition;
@property (nonatomic, retain) OverprintObject *overprintObject;
@property (nonatomic, retain) Course *course;

- (CGPoint)controlNumberPosition;
- (CGPoint)overprintObjectPosition;

- (CGFloat)angleToNextCourseObject;
- (CGRect)frame;

@end
