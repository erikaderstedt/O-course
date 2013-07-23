//
//  CourseObject.m
//  O-course
//
//  Created by Erik Aderstedt on 2013-07-20.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import "CourseObject.h"
#import "Course.h"
#import "OverprintObject.h"

#import "CoordinateTransverser.h"

@implementation CourseObject

@dynamic position_x;
@dynamic position_y;
@dynamic manualPosition;
@dynamic overprintObject;
@dynamic course;

- (CGPoint)controlNumberPosition {
    return CGPointMake([[self valueForKey:@"position_x"] doubleValue], [[self valueForKey:@"position_y"] doubleValue]);
}

- (CGPoint)courseObjectPosition {
    return [self.overprintObject position];
}

- (CGFloat)angleToNextCourseObject {
    CGPoint p1 = [self courseObjectPosition], p2;

    NSOrderedSet *courseObjects = [self.course valueForKey:@"courseObjects"];
    NSInteger i = [courseObjects indexOfObject:self] + 1;
    p2 = [[courseObjects objectAtIndex:i] courseObjectPosition];
    
    return angle_between_points(p1, p2);
}

- (CGRect)frame {
    CGPoint p = [self controlNumberPosition];
    return CGRectMake(p.x - 400.0, p.y - 300.0, 800.0, 600.0);
}

@end
