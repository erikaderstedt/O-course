//
//  ASCourseObject.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-14.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>


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
    kASFeatureMiddle,
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

enum ASCourseObjectType {
    kASCourseObjectStart,
    kASCourseObjectControl,
    kASCourseObjectTapedRouteFromControl,		// Specify distance
	kASCourseObjectTapedRouteBetweenControls,	// Specify distance
	kASCourseObjectMandatoryCrossingPoint,
	kASCourseObjectMandatoryPassing,
	kASCourseObjectTapedRouteToMapExchange,		// Specify distance
	kASCourseObjectTapedRouteToFinish,			// Specify distance
	kASCourseObjectPartlyTapedRouteToFinish,	// Specify distance
	kASCourseObjectRouteToFinish,				// Specify distance
    kASCourseObjectFinish                       // The finish is not actually displayed on
};

@protocol ASCourseObject <NSObject>

- (enum ASCourseObjectType)courseObjectType;
- (CGPoint)position;
- (void)setPosition:(CGPoint)newPosition;

@end

@protocol ASCourseDataSource <NSObject>

- (BOOL)addCourseObject:(enum ASCourseObjectType)objectType atLocation:(CGPoint)location symbolNumber:(NSInteger)symbolNumber;
- (void)enumerateCourseObjectsUsingBlock:(void (^)(id <ASCourseObject> object, BOOL inSelectedCourse))handler;

- (BOOL)specificCourseSelected;

@end
