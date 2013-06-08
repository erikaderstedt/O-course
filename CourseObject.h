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

enum ASWhichOfAnySimilarFeature {
    kASFeatureNotSpecified,
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
    kASFeatureNone,
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
    kASFeatureWaterTrough,
    kASFeatureOpenLand,
    kASFeatureSemiOpenLand,
    kASFeatureForestCorner,
    kASFeatureClearing,
    kASFeatureThicket,
    kASFeatureLinearThicket,
    kASFeatureVegetationBoundary,
    kASFeatureCopse,
    kASFeatureDistinctiveTree,
    kASFeatureTreeStumpOrRootStock,
    kASFeatureRoad,
    kASFeatureTrack,
    kASFeatureRide,
    kASFeatureBridge,
    kASFeaturePowerLine,
    kASFeaturePowerLinePylon,
    kASFeatureTunnel,
    kASFeatureStoneWall,
    kASFeatureFence,
    kASFeatureCrossingPoint,
    kASFeatureBuilding,
    kASFeaturePavedArea,
    kASFeatureRuin,
    kASFeaturePipeline,
    kASFeatureTower,
    kASFeatureShootingPlatform,
    kASFeatureCairn,
    kASFeatureFodderRack,
    kASFeatureCharcoalBurningGround,
    kASFeatureMonument,
    kASFeatureBuildingPassThrough,
    kASFeatureStairway,
    kASFeatureSpecialItem1,
    kASFeatureSpecialItem2
};

@interface CourseObject : NSManagedObject <ASControlDescriptionItem, ASCourseObject>

@property (nonatomic,retain) NSDate *added;
@property (nonatomic,retain) NSNumber *position_x;
@property (nonatomic,retain) NSNumber *position_y;
@property (nonatomic,retain) NSNumber *distance;
@property (nonatomic,retain) NSNumber *angle;
@property (nonatomic,assign) enum ASCourseObjectType objectType;
@property (nonatomic,retain) NSData *data;

@property (nonatomic,assign) enum ControlDescriptionItemType controlDescriptionItemType;

@property (nonatomic,retain) NSNumber *controlCode;
@property (nonatomic,retain) NSNumber *whichOfAnySimilarFeature;
@property (nonatomic,retain) NSNumber *controlFeature;
@property (nonatomic,retain) NSNumber *appearanceOrSecondControlFeature;
@property (nonatomic,retain) NSString *dimensions;
@property (nonatomic,retain) NSNumber *combinationSymbol;
@property (nonatomic,retain) NSNumber *locationOfTheControlFlag;
@property (nonatomic,retain) NSNumber *otherInformation;

- (void)assignNextFreeControlCode;
- (void)setSymbolNumber:(NSInteger)symbolNumber;

@end
