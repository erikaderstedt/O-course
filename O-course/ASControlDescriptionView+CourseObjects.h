//
//  ASControlDescriptionView+CourseObjects.h
//  O-course
//
//  Created by Erik Aderstedt on 2012-05-25.
//  Copyright (c) 2012 Aderstedt Software AB. All rights reserved.
//

#import "ASControlDescriptionView.h"

@interface ASControlDescriptionView (CourseObjects) <ASCourseObjectSelectionViewDataSource>

- (NSArray *)createPathsForWhichOfAnySimilarFeatureWithValue:(NSNumber *)value transform:(CGAffineTransform *)tran;
- (NSArray *)createPathsForFeatureOrAppearance:(NSNumber *)value transform:(CGAffineTransform *)tran;
- (NSArray *)createPathsForDimensionsOrCombination:(NSNumber *)value transform:(CGAffineTransform *)tran;
- (NSArray *)createPathsForLocationOfControlFlag:(NSNumber *)value transform:(CGAffineTransform *)tran;
- (NSArray *)createPathsForOtherInformation:(NSNumber *)value transform:(CGAffineTransform *)tran;

@end
