//
//  CourseObject.h
//  O-course
//
//  Created by Erik Aderstedt on 2012-05-24.
//  Copyright (c) 2012 Aderstedt Software AB. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ASControlDescriptionProvider.h"

enum ASWhichOfAnySimilarFeature {
    kASFeatureNorth,
    kASFeatureNorthEast,
    kASFeatureEast,
    kASFeatureSouthEast,
    kASFeatureSouth,
    kASFeatureSouthWest,
    kASFeatureWest,
    kASFeatureNorthWest,
    kASFeatureUpper,
    kASFeatureLower,
    kASFeatureLeft,
    kASFeatureMiddle,
    kASFeatureRight
};

enum ASFeature {
    kASFeatureTerrace,
    kASFeatureSpur,
    kASFeatureRe_Entrant,
    kASFeatureEarthBank,
    kASFeatureQuarry,
    kASFeatureEarthWall,
    kASFeatureErosionGully,
    kASFeatureSmallErosionGully,
    kASFeatureHill,
    kASFeatureKnoll,
    kASFeatureSaddle,
    kASFeatureDepression,
    kASFeatureSmallDepression,
    kASFeaturePit,
    kASFeatureBrokenGround,
    kASFeatureAntHill,
    kASFeatureCliff,
    kASFeatureRockPillar,
    kASFeatureCave,
    kASFeatureBoulder,
    kASFeatureBoulderField,
    kASFeatureBoulderCluster,
    kASFeatureStonyGround,
    kASFeatureBareRock,
    kASFeatureNarrowPassage,
    kASFeatureLake,
    kASFeaturePond,
    kASFeatureWaterhole,
    kASFeatureStream,
    kASFeatureDitch,
    kASFeatureNarrowMarch,
    kASFeatureMarch,
    kASFeatureFirmGroundInMarch,
    kASFeatureWell,
    kASFeatureSpring,
    kASFeatureWaterTrough
};

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
