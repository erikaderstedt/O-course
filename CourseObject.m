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

- (CGFloat)angleToNextCourseObject {
    CGPoint p1 = [self overprintObjectPosition], p2;

    NSOrderedSet *courseObjects = [self.course valueForKey:@"courseObjects"];
    NSInteger i = [courseObjects indexOfObject:self] + 1;
    p2 = [[courseObjects objectAtIndex:i] overprintObjectPosition];
    
    return angle_between_points(p1, p2);
}

- (CGRect)frame {
    CGPoint p = [self controlNumberPosition];
    return CGRectMake(p.x - 400.0, p.y - 300.0, 800.0, 600.0);
}

- (CGPoint)overprintObjectPosition {
    return [self.overprintObject position];
}

- (NSArray *)objectsInCourseWithTheSameOverprintObject {
    return [[[self.course mutableOrderedSetValueForKey:@"courseObjects"] array] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"overprintObject == %@", self.overprintObject]];
}

- (NSInteger)controlNumber {
    NSInteger j = 1;
    for (CourseObject *co in [self.course valueForKey:@"courseObjects"]) {
        if (co == self) return j;
        if (co.overprintObject.objectType == kASOverprintObjectControl) j++;
    }
    NSAssert(0, @"Object not in course!");
    return NSNotFound;
}

#pragma mark ASControlDescriptionItem

- (enum ASOverprintObjectType)objectType {
    return [self.overprintObject objectType];
}

// In km.
- (NSNumber *)distance {
    enum ASOverprintObjectType oType = [self.overprintObject objectType];
    if (oType == kASOverprintObjectFinish) {
        // Calculate distance to previous.
        NSOrderedSet *courseObjects = [self.course valueForKey:@"courseObjects"];
        NSInteger i = [courseObjects indexOfObject:self] - 1;
        if (i < 0) return @(0.0);
        return @(regular_distance_between_points([self overprintObjectPosition], [[courseObjects objectAtIndex:i] overprintObjectPosition]) * 15.0 / 100.0 / 1000.0);
    }
    NSAssert(NO, @"Not yet implemented");
    return @(0.0);
}

- (NSNumber *)controlCode { return [self.overprintObject controlCode]; }
- (NSNumber *)whichOfAnySimilarFeature { return [self.overprintObject whichOfAnySimilarFeature]; }
- (NSNumber *)controlFeature { return [self.overprintObject controlFeature]; }
- (NSNumber *)appearanceOrSecondControlFeature { return [self.overprintObject appearanceOrSecondControlFeature]; }
- (NSString *)dimensions { return [self.overprintObject dimensions]; }
- (NSNumber *)combinationSymbol { return [self.overprintObject combinationSymbol]; }
- (NSNumber *)locationOfTheControlFlag { return [self.overprintObject locationOfTheControlFlag]; }
- (NSNumber *)otherInformation { return [self.overprintObject otherInformation]; }

- (void)setControlCode:(NSNumber *)code { [self.overprintObject setControlCode:code]; }
- (void)setWhichOfAnySimilarFeature:(NSNumber *)whichOfAnySimilarFeature { [self.overprintObject setWhichOfAnySimilarFeature:whichOfAnySimilarFeature]; }
- (void)setControlFeature:(NSNumber *)controlFeature { [self.overprintObject setControlFeature:controlFeature]; }
- (void)setAppearanceOrSecondControlFeature:(NSNumber *)appearanceOrSecondControlFeature { [self.overprintObject setAppearanceOrSecondControlFeature:appearanceOrSecondControlFeature]; }
- (void)setDimensions:(NSString *)dimensions { [self.overprintObject setDimensions:dimensions]; }
- (void)setCombinationSymbol:(NSNumber *)combinationSymbol { [self.overprintObject setCombinationSymbol:combinationSymbol]; }
- (void)setLocationOfTheControlFlag:(NSNumber *)locationOfTheControlFlag { [self.overprintObject setLocationOfTheControlFlag:locationOfTheControlFlag]; }
- (void)setOtherInformation:(NSNumber *)otherInformation { [self.overprintObject setOtherInformation:otherInformation]; }

@end
