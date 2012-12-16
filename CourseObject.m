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

@dynamic distance;

// These properties are unavailable if this is not a subentity 'Control'.
@dynamic controlCode;
@dynamic whichOfAnySimilarFeature;
@dynamic controlFeature;
@dynamic appearanceOrSecondControlFeature;
@dynamic dimensions;
@dynamic combinationSymbol;
@dynamic locationOfTheControlFlag;
@dynamic otherInformation;

- (NSInteger)controlNumber {
    return -1;
}

- (CGPoint)position {
    return CGPointMake([[self valueForKey:@"position_x"] doubleValue], [[self valueForKey:@"position_y"] doubleValue]);
}

- (void)setPosition:(CGPoint)p {
    [self setPrimitiveValue:[NSNumber numberWithDouble:p.x] forKey:@"position_x"];
    [self setValue:[NSNumber numberWithDouble:p.y] forKey:@"position_y"];
}

@end
