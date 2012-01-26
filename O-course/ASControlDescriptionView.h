//
//  ASControlDescriptionView.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-14.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "ASControlDescriptionProvider.h"

@interface ASControlDescriptionView : NSView {
    id <ASControlDescriptionProvider> provider;
    id <NSObject> course;
    
    NSColor *overprintColor;
    
    NSMutableDictionary *boldAttributes;
    NSMutableDictionary *regularAttributes;
    NSMutableDictionary *dimensionsAttributes;    
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
    
@end
