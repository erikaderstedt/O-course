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
    
    if ([self.provider eventName] != nil) {
        NSTrackingArea *ta = [[NSTrackingArea alloc] initWithRect:NSRectFromCGRect(eventBounds) options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow owner:self userInfo:nil];
        [self addTrackingArea:ta];
    }
    
    // Add a tracking area for each element that can be changed.
    __block NSInteger topItem = [self numberOfItems] - [self.provider numberOfControlDescriptionItems];
    NSArray *regularColumns = @[@(kASControlCode), @(kASWhichOfAnySimilarFeature), @(kASFeature), @(kASAppearanceOrSecondaryFeature), @(kASDimensionsOrCombinations), @(kASLocationOfTheControlFlag), @(kASOtherInformation)];
    
    [self.provider enumerateControlDescriptionItemsUsingBlock:^(id<ASControlDescriptionItem> item) {
        if ([item objectType] == kASOverprintObjectControl) {
            
            for (NSNumber *columnIntegerValue in regularColumns) {
                enum ASControlDescriptionColumn column = (enum ASControlDescriptionColumn)[columnIntegerValue intValue];
                NSRect r = NSRectFromCGRect([self boundsForRow:topItem column:column]);
                NSTrackingArea *ta = [[NSTrackingArea alloc] initWithRect:NSIntegralRect(NSInsetRect(r, 1, 1))
                                                                  options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow
                                                                    owner:self
                                                                 userInfo:@{@"object":item, @"column":@(column)}];
                [self addTrackingArea:ta];
            }
        }
        topItem ++;
    }];
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
        enum ASControlDescriptionColumn column = (enum ASControlDescriptionColumn)[userInfo[@"column"] intValue];
        if (userInfo) {
            self.activeObject = userInfo[@"object"];
            if (column != kASControlCode) {
                self.selectionView.column = column;
            }
        } else {
            self.selectionView.column = kASAllColumns;
        }
        
        if (column != kASControlCode) {
            [self.popoverForCDEGH setContentSize:[[self selectionView] bounds].size];
            [self.popoverForCDEGH showRelativeToRect:[activeTrackingArea rect] ofView:self preferredEdge:NSMaxXEdge];
        } else {
            [[self.popoverForB contentViewController] setRepresentedObject:self.activeObject];
            self.popoverForB.delegate = self;
            [self.popoverForB showRelativeToRect:[activeTrackingArea rect] ofView:self preferredEdge:NSMaxXEdge];
        }
    } else {
        self.activeObject = nil;
    }
}

- (void)popoverDidClose:(NSNotification *)notification {
    [self setNeedsDisplay:YES];
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
        case kASDimensionsOrCombinations:
            [self.activeObject setCombinationSymbol:value];
            break;
        case kASLocationOfTheControlFlag:
            [self.activeObject setLocationOfTheControlFlag:value];
            break;
        case kASOtherInformation:
            [self.activeObject setOtherInformation:value];
            break;
        default:
            break;
    }
    [self.popoverForCDEGH close];
    [self setNeedsDisplay:YES];
}

@end
