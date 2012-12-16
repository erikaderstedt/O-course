//
//  ASControlDescriptionProvider.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-14.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>

enum ControlDescriptionItemType {
	kASStart,
	kASRegularControl,
	kASTapedRouteFromControl,		// Specify distance
	kASTapedRouteBetweenControls,	// Specify distance
	kASMandatoryCrossingPoint,
	kASMandatoryPassing,
	kASTapedRouteToMapExchange,		// Specify distance
	kASTapedRouteToFinish,			// Specify distance
	kASPartlyTapedRouteToFinish,	// Specify distance
	kASRouteToFinish,				// Specify distance
    kASFinish                       // The finish is not actually displayed on the control description.
                                    // This control type is never present.
};

enum ASControlDescriptionColumn {
    kASControlNumber,
    kASControlCode,
    kASWhichOfAnySimilarFeature,
    kASFeature,
    kASAppearanceOrSecondaryFeature,
    kASDimensionsOrCombinations,
    kASLocationOfTheControlFlag,
    kASOtherInformation,
    kASAllColumns
};

@protocol ASControlDescriptionItem  <NSObject>

- (enum ControlDescriptionItemType)controlDescriptionItemType;
- (NSNumber *)distance;
- (NSNumber *)controlCode;
- (NSNumber *)whichOfAnySimilarFeature;
- (NSNumber *)controlFeature;
- (NSNumber *)appearanceOrSecondControlFeature;
- (NSString *)dimensions;
- (NSNumber *)combinationSymbol;
- (NSNumber *)locationOfTheControlFlag;
- (NSNumber *)otherInformation;

@end

// Course is an opaque type for this.
@protocol ASControlDescriptionProvider <NSObject>

- (NSString *)eventName;
- (NSString *)classNamesForCourse:(id)course;
- (NSString *)numberForCourse:(id)course;
- (NSString *)lengthOfCourse:(id)course;
- (NSString *)heightClimbForCourse:(id)course;

// Each item returned by the course object enumerator conforms
// to <ASControlDescriptionItem>
- (NSEnumerator *)courseObjectEnumeratorForCourse:(id)course;

@end

@protocol ASEditableControlDescriptionItem <ASControlDescriptionItem, NSObject>

- (void)setControlCode:(NSNumber *)code;
- (void)setControlFeature:(NSNumber *)controlFeature;
- (void)setWhichOfAnySimilarFeature:(NSNumber *)whichOfAnySimilarFeature;
- (void)setAppearanceOrSecondControlFeature:(NSNumber *)appearanceOrSecondControlFeature;
- (void)setDimensions:(NSString *)dimensions;
- (void)setCombinationSymbol:(NSNumber *)combinationSymbol;
- (void)setLocationOfTheControlFlag:(NSNumber *)locationOfTheControlFlag;
- (void)setOtherInformation:(NSNumber *)otherInformation;

@end

@protocol ASCourseObjectSelectionViewDelegate <NSObject>

- (NSInteger)selectedValueForColumn:(enum ASControlDescriptionColumn)column;

@end

@protocol ASCourseObjectSelectionViewDataSource <NSObject>

- (NSArray *)supportedValuesForColumn:(enum ASControlDescriptionColumn)column;
- (CFArrayRef)createPathsForColumn:(enum ASControlDescriptionColumn)column withValue:(NSNumber *)value atPosition:(CGPoint)p withSize:(CGFloat)sz;
- (CFArrayRef)createPathsForWhichOfAnySimilarFeatureWithValue:(NSNumber *)value transform:(CGAffineTransform *)tran;
- (CFArrayRef)createPathsForFeatureOrAppearance:(NSNumber *)value transform:(CGAffineTransform *)tran;
- (NSString *)localizedNameForValue:(NSInteger)value inColumn:(enum ASControlDescriptionColumn)column;
- (NSString *)localizedDescriptionForValue:(NSInteger)value inColumn:(enum ASControlDescriptionColumn)column;

@end
