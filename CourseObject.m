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
}

@dynamic distance;
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

@end
