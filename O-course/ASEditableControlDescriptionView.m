//
//  ASEditableControlDescriptionView.m
//  O-course
//
//  Created by Erik Aderstedt on 2012-05-25.
//  Copyright (c) 2012 Aderstedt Software AB. All rights reserved.
//

#import "ASEditableControlDescriptionView.h"
#import "ASControlDescriptionProvider.h"
#import "ASCourseObjectSelectionView.h"

@implementation ASEditableControlDescriptionView

@synthesize popoverForCDEGH;
@synthesize selectionView;

- (void)updateTrackingAreas {
    if (activeTrackingArea != nil) {
        [self setNeedsDisplayInRect:[activeTrackingArea rect]];
        activeTrackingArea = nil;
    }
    
    [super updateTrackingAreas];
    
    NSArray *tas = [self trackingAreas];
    for (NSTrackingArea *ta in tas) {
        [self removeTrackingArea:ta];
    }
    
    if ([provider eventName] != nil) {
        NSTrackingArea *ta = [[NSTrackingArea alloc] initWithRect:NSRectFromCGRect(eventBounds) options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow owner:self userInfo:nil];
        [self addTrackingArea:[ta autorelease]];
    }
    
    // Add a tracking area for each element that can be changed.
    // Event (1st row)
    //
    NSInteger topItem = [self numberOfItems] - [[[provider courseObjectEnumeratorForCourse:self.course] allObjects] count];
    NSArray *regularColumns = @[@(kASWhichOfAnySimilarFeature), @(kASFeature), @(kASAppearanceOrSecondaryFeature), @(kASDimensionsOrCombinations), @(kASLocationOfTheControlFlag), @(kASOtherInformation)];
    
    for (id <ASControlDescriptionItem> object in [provider courseObjectEnumeratorForCourse:self.course]) {
        if ([object controlDescriptionItemType] == kASRegularControl) {
            
            for (NSNumber *columnIntegerValue in regularColumns) {
                enum ASControlDescriptionColumn column = (enum ASControlDescriptionColumn)[columnIntegerValue intValue];
                NSRect r = NSRectFromCGRect([self boundsForRow:topItem column:column]);
                NSTrackingArea *ta = [[NSTrackingArea alloc] initWithRect:NSIntegralRect(NSInsetRect(r, 1, 1))
                                                                  options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow
                                                                    owner:self
                                                                 userInfo:@{@"object":object, @"column":@(column)}];
                [self addTrackingArea:ta];
            }
            topItem ++;
        }
    }
    
    // The control number is special
}

- (void)mouseEntered:(NSEvent *)theEvent {
    if (activeTrackingArea != nil) {
        [self setNeedsDisplayInRect:[activeTrackingArea rect]];
    }
    activeTrackingArea = [theEvent trackingArea];
    [self setNeedsDisplayInRect:[activeTrackingArea rect]];
    
}

- (void)mouseExited:(NSEvent *)theEvent {
    if (activeTrackingArea != nil) {
        [self setNeedsDisplayInRect:[activeTrackingArea rect]];
    }
    activeTrackingArea = nil;
}

- (void)mouseDown:(NSEvent *)theEvent {
    if (activeTrackingArea != nil) {
        NSDictionary *userInfo = [activeTrackingArea userInfo];
        if (userInfo) {
            self.selectionView.column = (enum ASControlDescriptionColumn)[[userInfo objectForKey:@"column"] intValue];
            
            [self.popoverForCDEGH showRelativeToRect:[activeTrackingArea rect] ofView:self preferredEdge:NSMaxXEdge];
        }
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    if (activeTrackingArea) {
        NSColor *gray = [NSColor colorWithDeviceWhite:0.3 alpha:0.2];
        [gray set];
        [NSBezierPath fillRect:[activeTrackingArea rect]];
    }
}
     

@end
