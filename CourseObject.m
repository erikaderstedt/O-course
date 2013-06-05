//
//  CourseObject.m
//  O-course
//
//  Created by Erik Aderstedt on 2012-05-24.
//  Copyright (c) 2012 Aderstedt Software AB. All rights reserved.
//

#import "CourseObject.h"

@implementation CourseObject

- (enum ControlDescriptionItemType)controlDescriptionItemType {
    return (enum ControlDescriptionItemType)[[self valueForKey:@"type"] intValue];
}

- (void)setControlDescriptionItemType:(enum ControlDescriptionItemType)_type {
    [self setValue:[NSNumber numberWithInt:_type] forKey:@"type"];
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    [self setPrimitiveValue:[NSDate date] forKey:@"added"];
    if ([[[self entity] name] isEqualToString:@"Control"]) {
        [self setPrimitiveValue:[NSNumber numberWithInt:kASFeatureNone] forKey:@"controlFeature"];
        [self setPrimitiveValue:[NSNumber numberWithInt:kASFeatureNotSpecified] forKey:@"whichOfAnySimilarFeature"];
    }
}

- (enum ASCourseObjectType)objectType {
    return (enum ASCourseObjectType)[[self valueForKey:@"type"] integerValue];
}

- (void)setObjectType:(enum ASCourseObjectType)objectType {
    [self setValue:@((NSInteger)objectType) forKey:@"type"];
}

@dynamic added;
@dynamic position_x;
@dynamic position_y;
@dynamic angle;
@dynamic distance;
@dynamic data;

- (CGPoint)position {
    return CGPointMake([[self valueForKey:@"position_x"] doubleValue], [[self valueForKey:@"position_y"] doubleValue]);
}

- (void)setPosition:(CGPoint)p {
    [self setPrimitiveValue:[NSNumber numberWithDouble:p.x] forKey:@"position_x"];
    [self setValue:[NSNumber numberWithDouble:p.y] forKey:@"position_y"];
}

- (NSInteger)controlNumber {
    return -1;
}

@dynamic controlCode;
@dynamic whichOfAnySimilarFeature;
@dynamic controlFeature;
@dynamic appearanceOrSecondControlFeature;
@dynamic dimensions;
@dynamic combinationSymbol;
@dynamic locationOfTheControlFlag;
@dynamic otherInformation;

- (void)assignNextFreeControlCode {
    // Excluded numbers : 66, 68, 89, 99,
    // Don't do this in awakeFromInsert.
    NSAssert([self objectType] == kASCourseObjectControl, @"Assigning control code to something that is not a control");
    
    self.controlCode = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"CourseObject"];
    [request setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"controlCode" ascending:YES]]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"controlCode != nil"]];
    
    NSArray *otherControls = [[self managedObjectContext] executeFetchRequest:request error:nil];
    NSInteger freeCode = 31;
    for (CourseObject *control in otherControls) {
        if ([control.controlCode integerValue] != freeCode) {
            self.controlCode = @(freeCode);
        } else {
            freeCode = [control.controlCode integerValue] + 1;
        }
        if (freeCode == 66 ||
            freeCode == 68 ||
            freeCode == 89 ||
            freeCode == 99) {
            freeCode ++;
        }
    }
}


@end
