//
//  ASControlDescriptionProvider.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-14.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASCourseObject.h"

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

- (enum ASOverprintObjectType)objectType;
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
@protocol ASControlDescriptionDataSource <NSObject>

- (id)project;
- (NSString *)eventName;
- (NSString *)classNames;
- (NSString *)number;
- (NSNumber *)length;
- (NSString *)heightClimb;

// Each item returned by the course object enumerator conforms
// to <ASControlDescriptionItem>
- (void)enumerateControlDescriptionItemsUsingBlock:(void (^)(id <ASControlDescriptionItem> item))handler;
- (NSInteger)numberOfControlDescriptionItems;

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

@protocol ASCourseObjectSelectionViewDataSource <NSObject>

- (NSArray *)supportedValuesForColumn:(enum ASControlDescriptionColumn)column;
- (NSArray *)createPathsForColumn:(enum ASControlDescriptionColumn)column withValue:(NSNumber *)value atPosition:(CGPoint)p withSize:(CGFloat)sz;
- (NSArray *)createPathsForWhichOfAnySimilarFeatureWithValue:(NSNumber *)value transform:(CGAffineTransform *)tran;
- (NSArray *)createPathsForFeatureOrAppearance:(NSNumber *)value transform:(CGAffineTransform *)tran;
- (NSString *)localizedNameForValue:(NSInteger)value inColumn:(enum ASControlDescriptionColumn)column;

- (void)setValue:(NSNumber *)value forColumn:(enum ASControlDescriptionColumn)column;

@end
