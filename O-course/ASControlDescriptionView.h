//
//  ASControlDescriptionView.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-14.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "ASControlDescriptionProvider.h"

@class ASDistanceFormatter;

enum ASControlDescriptionColumn {
    kASControlNumber,
    kASControlCode,
    kASWhichOfAnySimilarFeature,
    kASFeature,
    kASAppearanceOrSecondaryFeature,
    kASDimensionsOrCombinations,
    kASLocationOfTheControlFlag,
    kASOtherInformation
};


#define SYMBOL_SIZE 64
#define SQRT2   0.7

@interface ASControlDescriptionView : NSView {
    id <ASControlDescriptionProvider> provider;
    id <NSObject> course;
    
    NSColor *overprintColor;
    
    NSMutableDictionary *boldAttributes;
    NSMutableDictionary *regularAttributes;
    NSMutableDictionary *dimensionsAttributes;
    
    ASDistanceFormatter *distanceFormatter;
}
@property (nonatomic,retain) IBOutlet id <ASControlDescriptionProvider> provider;
@property (nonatomic,retain) id <NSObject> course;

- (void)setup;

- (NSInteger)numberOfItems;
- (CGFloat)heightForWidth:(CGFloat)width;

- (void)setOverprintColor:(NSColor *)newColor;
+ (NSColor *)defaultOverprintColor;

- (void)drawThickGridAtOrigin:(NSPoint)origin blockSize:(CGFloat)blockSize;
- (void)drawThinGridAtOrigin:(NSPoint)origin blockSize:(CGFloat)blockSize;

- (void)drawWhichOfAnySimilarFeatureAtOrigin:(NSPoint)p usingBlockSize:(CGFloat)blockSize;

- (CFArrayRef)createPathsForColumn:(enum ASControlDescriptionColumn)column withValue:(NSNumber *)value atPosition:(CGPoint)p withSize:(CGFloat)sz;
- (CFArrayRef)createPathsForWhichOfAnySimilarFeatureWithValue:(NSNumber *)value transform:(CGAffineTransform *)tran;
- (CFArrayRef)createPathsForFeatureOrAppearance:(NSNumber *)value transform:(CGAffineTransform *)tran;
@end


#define MAX_NUMBER_OF_DASHES 100
@interface NSBezierPath (ASDashedBezierPaths)

- (NSBezierPath *)bezierPathByStrokingPath;

@end