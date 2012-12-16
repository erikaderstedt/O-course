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
    id <ASControlDescriptionProvider> provider;
    id <NSObject> course;
    
    NSColor *overprintColor;
    
    NSMutableDictionary *boldAttributes;
    NSMutableDictionary *regularAttributes;
    NSMutableDictionary *dimensionsAttributes;
    
    ASDistanceFormatter *distanceFormatter;
    
    NSColor *linenTextureColor;
    NSShadow *dropShadow;
    
    // Layout
@protected
    CGFloat  blockSize;
    CGRect  paperBounds;
    CGRect  actualDescriptionBounds;
    CGRect  eventBounds;
}
@property (nonatomic,retain) IBOutlet id <ASControlDescriptionProvider> provider;
@property (nonatomic,retain) id <NSObject> course;

- (void)setup;

- (NSInteger)numberOfItems;
- (CGFloat)heightForWidth:(CGFloat)width;

- (void)setOverprintColor:(NSColor *)newColor;
+ (NSColor *)defaultOverprintColor;

- (void)drawThickGridAtOrigin:(NSPoint)origin;
- (void)drawThinGridAtOrigin:(NSPoint)origin;

@end


#define MAX_NUMBER_OF_DASHES 100
@interface NSBezierPath (ASDashedBezierPaths)

- (NSBezierPath *)bezierPathByStrokingPath;

@end