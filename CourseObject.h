//
//  CourseObject.h
//  O-course
//
//  Created by Erik Aderstedt on 2012-05-24.
//  Copyright (c) 2012 Aderstedt Software AB. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ASControlDescriptionProvider.h"

@interface CourseObject : NSManagedObject <ASControlDescriptionItem>

@property (nonatomic,retain) NSNumber *distance;
@property (nonatomic,retain) NSNumber *controlCode;
@property (nonatomic,retain) NSNumber *whichOfAnySimilarFeature;
@property (nonatomic,retain) NSNumber *controlFeature;
@property (nonatomic,retain) NSNumber *appearanceOrSecondControlFeature;
@property (nonatomic,retain) NSString *dimensions;
@property (nonatomic,retain) NSNumber *combinationSymbol;
@property (nonatomic,retain) NSNumber *locationOfTheControlFlag;
@property (nonatomic,retain) NSNumber *otherInformation;
@property (nonatomic,assign) enum ControlDescriptionItemType controlDescriptionItemType;

- (CGPoint)position;
- (void)setPosition:(CGPoint)p;

@end
