//
//  Course.h
//  O-course
//
//  Created by Erik Aderstedt on 2013-06-05.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import <CoreData/CoreData.h>

@class OverprintObject;
@class CourseObject;

@interface Course : NSManagedObject
@property (nonatomic, retain) NSString * name;

- (void)appendOverprintObject:(OverprintObject *)object;
- (void)insertOverprintObject:(OverprintObject *)object atPosition:(NSUInteger)position;
- (void)removeLastOccurrenceOfOverprintObject:(OverprintObject *)object;

+ (CGPoint)controlNumberPositionBasedOnObjectPosition:(CGPoint)position angle:(CGFloat)angle;
+ (CGRect)controlNumberFrameBasedOnObjectPosition:(CGPoint)position angle:(CGFloat)angle;
- (void)recalculateControlNumberPositions;

// Length, in km.
- (CGFloat)length;
@property (nonatomic, retain) NSOrderedSet *courseObjects;
@end
