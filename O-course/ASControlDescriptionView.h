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

@interface ASControlDescriptionView : NSView {
    id <ASCourseProvider> provider;
    
    NSColor *overprintColor;
    
    NSMutableDictionary *boldAttributes;
    NSMutableDictionary *regularAttributes;
    NSMutableDictionary *dimensionsAttributes;
    
    ASDistanceFormatter *distanceFormatter;
    
@protected
    CGFloat  blockSize;
    CGRect  paperBounds;
    CGRect  actualDescriptionBounds;
    CGRect  eventBounds;
    
    BOOL layoutNeedsUpdate;
}
@property (nonatomic,retain) IBOutlet id <ASCourseProvider> provider;

- (void)setup;

- (void)adjustFrameSizeForLayout;
- (void)recalculateLayout;

- (NSInteger)numberOfItems;
- (CGFloat)heightForWidth:(CGFloat)width;

- (void)setOverprintColor:(NSColor *)newColor;
+ (NSColor *)defaultOverprintColor;

- (void)drawThickGridAtOrigin:(NSPoint)origin;
- (void)drawThinGridAtOrigin:(NSPoint)origin;

- (CGRect)boundsForRow:(NSInteger)rowIndex column:(enum ASControlDescriptionColumn)column;

@end


#define MAX_NUMBER_OF_DASHES 100
@interface NSBezierPath (ASDashedBezierPaths)

- (NSBezierPath *)bezierPathByStrokingPath;

@end