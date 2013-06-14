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

enum ASOverprintObjectType {
    kASOverprintObjectStart,
    kASOverprintObjectControl,
    kASOverprintObjectTapedRouteFromControl,		// Specify distance
	kASOverprintObjectTapedRouteBetweenControls,	// Specify distance
	kASOverprintObjectMandatoryCrossingPoint,
	kASOverprintObjectMandatoryPassing,
	kASOverprintObjectTapedRouteToMapExchange,		// Specify distance
	kASOverprintObjectTapedRouteToFinish,			// Specify distance
	kASOverprintObjectPartlyTapedRouteToFinish,	// Specify distance
	kASOverprintObjectRouteToFinish,				// Specify distance
    kASOverprintObjectFinish,                       // The finish is not actually displayed on
    kASOverprintObjectMedical,
    kASOverprintObjectRefreshments,
    kASOverprintObjectForbiddenRoute,
    kASOverprintObjectForbiddenArea,
    kASOverprintObjectCrossingPoint
};

@protocol ASOverprintObject <NSObject>

- (enum ASOverprintObjectType)objectType;
- (CGPoint)position;
- (void)setPosition:(CGPoint)newPosition;

- (void)setSymbolNumber:(NSInteger)number;
- (NSInteger)symbolNumber;

@end

@protocol ASCourseDataSource <NSObject>

- (BOOL)addOverprintObject:(enum ASOverprintObjectType)objectType atLocation:(CGPoint)location symbolNumber:(NSInteger)symbolNumber;
- (void)enumerateOverprintObjectsInSelectedCourseUsingBlock:(void (^)(id <ASOverprintObject> object, NSInteger index))handler;
- (void)enumerateOtherOverprintObjectsUsingBlock:(void (^)(id <ASOverprintObject> object))handler;
- (void)enumerateAllOverprintObjectsUsingBlock:(void (^)(id <ASOverprintObject> object))handler;
- (void)appendOverprintObjectToSelectedCourse:(id <ASOverprintObject>)object;
- (BOOL)specificCourseSelected;

@end
