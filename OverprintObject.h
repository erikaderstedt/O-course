//
//  CourseObject.h
//  O-course
//
//  Created by Erik Aderstedt on 2012-05-24.
//  Copyright (c) 2012 Aderstedt Software AB. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ASCourseObject.h"
#import "ASControlDescriptionProvider.h"


@interface OverprintObject : NSManagedObject <ASControlDescriptionItem, ASOverprintObject>

@property (nonatomic,strong) NSDate *added;
@property (nonatomic,strong) NSNumber *position_x;
@property (nonatomic,strong) NSNumber *position_y;
@property (nonatomic,strong) NSNumber *distance;
@property (nonatomic,strong) NSNumber *angle;
@property (nonatomic,assign) enum ASOverprintObjectType objectType;
@property (nonatomic,strong) NSData *data;

@property (nonatomic,strong) NSNumber *controlCode;
@property (nonatomic,strong) NSNumber *whichOfAnySimilarFeature;
@property (nonatomic,strong) NSNumber *controlFeature;
@property (nonatomic,strong) NSNumber *appearanceOrSecondControlFeature;
@property (nonatomic,strong) NSString *dimensions;
@property (nonatomic,strong) NSNumber *combinationSymbol;
@property (nonatomic,strong) NSNumber *locationOfTheControlFlag;
@property (nonatomic,strong) NSNumber *otherInformation;

- (void)assignNextFreeControlCode;
- (void)setSymbolNumber:(NSInteger)symbolNumber;

@end
