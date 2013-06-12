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
@synthesize activeObject;

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.selectionView setDataSource:self];
}

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
        [self addTrackingArea:ta];
    }
    
    // Add a tracking area for each element that can be changed.
    NSInteger topItem = [self numberOfItems] - [[[provider courseObjectEnumerator] allObjects] count];
    NSArray *regularColumns = @[@(kASWhichOfAnySimilarFeature), @(kASFeature), @(kASAppearanceOrSecondaryFeature), @(kASDimensionsOrCombinations), @(kASLocationOfTheControlFlag), @(kASOtherInformation)];
    
    for (id <ASControlDescriptionItem> object in [provider courseObjectEnumerator]) {
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
            self.selectionView.column = (enum ASControlDescriptionColumn)[userInfo[@"column"] intValue];
            self.activeObject = userInfo[@"object"];
        } else {
            self.selectionView.column = kASAllColumns;
        }
        [self.popoverForCDEGH setContentSize:[[self selectionView] bounds].size];
        [self.popoverForCDEGH showRelativeToRect:[activeTrackingArea rect] ofView:self preferredEdge:NSMaxXEdge];
    } else {
        self.activeObject = nil;
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

- (void)setValue:(NSNumber *)value forColumn:(enum ASControlDescriptionColumn)column {
    switch (column) {
        case kASFeature:
            [self.activeObject setControlFeature:value];
            break;
        case kASAppearanceOrSecondaryFeature:
            [self.activeObject setAppearanceOrSecondControlFeature:value];
            break;
        case kASWhichOfAnySimilarFeature:
            [self.activeObject setWhichOfAnySimilarFeature:value];
            break;
        default:
            break;
    }
    [self.popoverForCDEGH close];
    [self setNeedsDisplay:YES];
}

@end
