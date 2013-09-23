//
//  Course.m
//  O-course
//
//  Created by Erik Aderstedt on 2013-06-05.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import "Course.h"
#import "OverprintObject.h"
#import "CourseObject.h"
#import "Layout.h"
#import "CoordinateTransverser.h"

@implementation Course

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    [self setValue:[Layout defaultLayoutInContext:[self managedObjectContext]] forKey:@"layout"];
    [self setPrimitiveValue:NSLocalizedString(@"New course", nil) forKey:@"name"];
}

- (void)appendOverprintObject:(OverprintObject *)object {
    [self insertOverprintObject:object atPosition:[[self valueForKey:@"courseObjects"] count]];
}

- (void)insertOverprintObject:(OverprintObject *)object atPosition:(NSUInteger)position {
    NSAssert(object != nil, @"Can't insert a nil object into the course!");

    NSManagedObject *courseObject = [NSEntityDescription insertNewObjectForEntityForName:@"CourseObject" inManagedObjectContext:self.managedObjectContext];
    [courseObject setValue:object forKey:@"overprintObject"];
    [[self mutableOrderedSetValueForKey:@"courseObjects"] insertObject:courseObject atIndex:position];
    [[self managedObjectContext] processPendingChanges];
    
    [self recalculateControlNumberPositions];
}

- (void)removeLastOccurrenceOfOverprintObject:(OverprintObject *)object {
    NSEnumerator *enumerator = [[self valueForKey:@"courseObjects"] reverseObjectEnumerator];
    CourseObject *co;
    NSInteger i = [[self valueForKey:@"courseObjects"] count]-1;
    while (co = [enumerator nextObject]) {
        if ([[co overprintObject] isEqual:object]) break;
        i--;
    }
    if (co != nil) {
        [[self mutableOrderedSetValueForKey:@"courseObjects"] removeObjectAtIndex:i];
        co.overprintObject = nil;
        [co.managedObjectContext deleteObject:co];
        [[self managedObjectContext] processPendingChanges];
        
        [self recalculateControlNumberPositions];
    }
}

+ (CGPoint)controlNumberPositionBasedOnObjectPosition:(CGPoint)position angle:(CGFloat)angle {
    CGPoint p = CGPointMake(position.x + 700.0*cos(angle), position.y + 700.0*sin(angle));
    return p;
}

+ (CGRect)controlNumberFrameBasedOnObjectPosition:(CGPoint)position angle:(CGFloat)angle {
    CGPoint p = [self controlNumberPositionBasedOnObjectPosition:position angle:angle];
    return CGRectMake(p.x-350.0, p.y-350.0, 700.0, 700.0);
}

- (void)recalculateControlNumberPositions {
    NSMutableArray *occupiedFrames = [NSMutableArray arrayWithCapacity:100];
    CGFloat oldAngleToNext, angleToNext, averageAngle;
    
    NSInteger courseObjectCount = [[self valueForKey:@"courseObjects"] count];
    NSInteger currentCourseObjectIndex = 0;
    
    for (CourseObject *courseObject in [self valueForKey:@"courseObjects"]) {
        OverprintObject *o = [courseObject valueForKey:@"overprintObject"];
        CGRect courseObjectFrame = [o frame];
        [occupiedFrames addObject:[NSValue valueWithRect:NSRectFromCGRect(courseObjectFrame)]];
        if (currentCourseObjectIndex != courseObjectCount - 1) {
            angleToNext = [courseObject angleToNextCourseObject];
        }
        
        if (![[courseObject valueForKey:@"manualPosition"] boolValue] && o.objectType == kASOverprintObjectControl) {
            // Adjust the position
            // Get the angle between this object and the previous object and the next object.
            if (currentCourseObjectIndex != courseObjectCount - 1) {
                if (currentCourseObjectIndex > 0) {
                    averageAngle = atan2(sin(angleToNext) + sin(oldAngleToNext), cos(angleToNext) + cos(oldAngleToNext));
                } else {
                    averageAngle = angleToNext;
                }
            } else {
                if (courseObjectCount == 0) {
                    // No other objects.
                    averageAngle = 1.75*M_PI;
                } else {
                    averageAngle = oldAngleToNext;
                }
            }
            
            // Start looking for a place opposite of average angle.
            BOOL found = NO;
            CGFloat angle;
            for (angle = 0; abs(angle) < M_PI_2; angle = -angle - 0.05*angle/abs(angle)) {
                CGRect r = [Course controlNumberFrameBasedOnObjectPosition:[o position] angle:averageAngle + M_PI + angle];
                for (NSValue *existingRectValue in occupiedFrames) {
                    if (NSIntersectsRect(NSRectFromCGRect(r), [existingRectValue rectValue])) {
                        continue;
                    }
                }
                found = YES;
                break;
            }
            if (!found) angle = 0.0;
            
            CGRect r = [Course controlNumberFrameBasedOnObjectPosition:[o position] angle:averageAngle + M_PI + angle];
            [courseObject setPosition_x:CGRectGetMidX(r)];
            [courseObject setPosition_y:CGRectGetMidY(r)];
            
            // Add the number frame to occupiedFrames
            [occupiedFrames addObject:[NSValue valueWithRect:NSRectFromCGRect(r)]];
        }
        
        currentCourseObjectIndex++;
        oldAngleToNext = angleToNext + M_PI;
    }
}

// Length, in kilometers.
- (CGFloat)length {
    NSOrderedSet *cos = [self valueForKey:@"courseObjects"];
    if ([cos count] < 2) return 0.0;
    
    // Find first start.
    NSInteger i;
    for (i = 0; i < [cos count] && [[(CourseObject *)(cos[i]) overprintObject] objectType] != kASOverprintObjectStart; i++);
    if (i == [cos count]) return 0.0;
    
    CGPoint position = [[(CourseObject *)(cos[i]) overprintObject] position], p2;
    CGFloat l = 0.0;
    
    for (++i; i < [cos count]; i++) {
        p2 = [[(CourseObject *)(cos[i]) overprintObject] position];
        l += regular_distance_between_points(position, p2);
        position = p2;
    }
    
    // Each point is 15 cm.
    return l * [[self valueForKeyPath:@"project.scale"] doubleValue]/100.0 / 1e6;
}

@end
