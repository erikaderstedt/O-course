//
//  ASControlDescriptionView.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-14.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "ASControlDescriptionProvider.h"

#define INSET_DIST (8.0)
@class ASDistanceFormatter;

@interface ASControlDescriptionView : NSView {
    
    NSColor *overprintColor;
    
    NSMutableDictionary *boldAttributes;
    NSMutableDictionary *regularAttributes;
    NSMutableDictionary *dimensionsAttributes;
    
    ASDistanceFormatter *distanceFormatter;
    
@protected
    CGFloat  blockSize;
    CGRect  paperBounds;
    CGRect  controlDescriptionBounds;
    CGRect  eventBounds;
    
    BOOL layoutNeedsUpdate;
}
@property (nonatomic,weak) IBOutlet id <ASControlDescriptionDataSource> provider;
@property (strong) NSColor *linenColor;
@property (strong) NSShadow *paperShadow;

- (void)setup;

//- (void)adjustFrameSizeForLayout;
- (void)recalculateLayout;

- (NSInteger)numberOfItems;
- (CGFloat)heightForWidth:(CGFloat)width;

- (void)setOverprintColor:(NSColor *)newColor;
+ (NSColor *)defaultOverprintColor;

- (void)drawThickGridAtOrigin:(NSPoint)origin;
- (void)drawThinGridAtOrigin:(NSPoint)origin;

- (CGRect)boundsForRow:(NSInteger)rowIndex column:(enum ASControlDescriptionColumn)column;

- (CGFloat)insetDistanceForLayer:(CALayer *)layer;
- (void)drawControlDescriptionInLayer:(CALayer *)layer inContext:(CGContextRef)ctx;
- (CGRect)controlDescriptionBounds;
- (void)drawActualControlDescription;
- (void)drawSelectionUnderneath;

@end


#define MAX_NUMBER_OF_DASHES 100
@interface NSBezierPath (ASDashedBezierPaths)

- (NSBezierPath *)bezierPathByStrokingPath;

@end