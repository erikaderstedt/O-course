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
    __block NSInteger index = 0;
    NSInteger start = [self.provider numberOfItemsPrecedingActualCourseObjects];

    NSArray *regularColumns = @[@(kASControlCode), @(kASWhichOfAnySimilarFeature), @(kASFeature), @(kASAppearanceOrSecondaryFeature), @(kASDimensionsOrCombinations), @(kASLocationOfTheControlFlag), @(kASOtherInformation)];
    
    [self.provider enumerateControlDescriptionItemsUsingBlock:^(id<ASControlDescriptionItem> item) {
        NSRect r;
        NSTrackingArea *ta;
        if ([item objectType] == kASOverprintObjectControl) {
            for (NSNumber *columnIntegerValue in regularColumns) {
                enum ASControlDescriptionColumn column = (enum ASControlDescriptionColumn)[columnIntegerValue intValue];
                r = NSRectFromCGRect([self boundsForRow:index+start column:column]);
                ta = [[NSTrackingArea alloc] initWithRect:NSIntegralRect(NSInsetRect(r, 1, 3))
                                                  options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow
                                                    owner:self
                                                 userInfo:@{@"object":item, @"column":@(column)}];
                [self addTrackingArea:ta];
            }
        }
        r = NSRectFromCGRect([self boundsForRow:index+start column:kASControlNumber]);
        
        ta = [[NSTrackingArea alloc] initWithRect:NSIntegralRect(NSInsetRect(r, 1, 3))
                                          options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow
                                            owner:self
                                         userInfo:@{@"column":@(kASControlNumber), @"index":@(index)}];
        [self addTrackingArea:ta];
        
        // Add interstitial rect.
        r.origin.y -= 3.0;
        r.size.height = 6.0;
        r.size.width *= 8.0;
        ta = [[NSTrackingArea alloc] initWithRect:NSIntegralRect(r)
                                          options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow
                                            owner:self
                                         userInfo:@{@"index":@(index), @"column":@(kASAllColumns)}];
        [self addTrackingArea:ta];
        index ++;
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
            if (column == kASControlNumber) {
                self.activeObject = nil;
                NSInteger i = [userInfo[@"index"] integerValue];
                [self.provider setSelectedItemIndex:(i == [self.provider selectedItemIndex])?NSNotFound:i];
            } else if (column == kASAllColumns) {
                self.activeObject = nil;
                NSInteger i = [userInfo[@"index"] integerValue];
                [self.provider setSelectedInterstitialIndex:(i == [self.provider selectedItemIndex])?NSNotFound:i];
            } else {
                [self.provider setSelectedInterstitialIndex:NSNotFound];
                [self.provider setSelectedItemIndex:NSNotFound];
                [self setNeedsDisplay:YES];
                
                self.activeObject = userInfo[@"object"];
                if (column != kASControlCode) {
                    self.selectionView.column = column;
                }
            }
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ASEditEventName" object:[self.provider project] userInfo:@{ @"rect":[NSValue valueWithRect:[activeTrackingArea rect]], @"view":self}];
             return;
        }
        
        if (column == kASControlCode) {
            [[self.popoverForB contentViewController] setRepresentedObject:self.activeObject];
            self.popoverForB.delegate = self;
            [self.popoverForB showRelativeToRect:[activeTrackingArea rect] ofView:self preferredEdge:NSMaxXEdge];
        } else if (column != kASControlNumber && column != kASAllColumns) {
            [self.popoverForCDEGH setContentSize:[[self selectionView] bounds].size];
            [self.popoverForCDEGH showRelativeToRect:[activeTrackingArea rect] ofView:self preferredEdge:NSMaxXEdge];
        } else {
            // Show selection
            [self setNeedsDisplay:YES];
        }
    } else {
        self.activeObject = nil;
    }
}

- (void)popoverDidClose:(NSNotification *)notification {
    [self setNeedsDisplay:YES];
}

- (void)drawSelectionUnderneath {
    NSColor *blue = [NSColor colorWithDeviceRed:0.21 green:0.47 blue:0.84 alpha:0.6];
    [blue set];
    NSInteger i;
    if ((i = [self.provider selectedItemIndex]) != NSNotFound) {
        
        CGRect r = [self boundsForRow:i + [self.provider numberOfItemsPrecedingActualCourseObjects] column:kASControlNumber];
        r.size.width *= 8.0;
        [NSBezierPath fillRect:r];
    } else if ((i = [self.provider selectedInterstitialIndex]) != NSNotFound) {
        
        CGRect r = [self boundsForRow:i + [self.provider numberOfItemsPrecedingActualCourseObjects] column:kASControlNumber];
        r.origin.y -= 3.0;
        r.size.height = 6.0;
        r.size.width *= 8.0;
        [NSBezierPath fillRect:r];
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

- (void)keyDown:(NSEvent *)theEvent {
    if ([theEvent keyCode] == 126 || [theEvent keyCode] == 125) {
        enum ASControlDescriptionItemMovementDirection direction = ([theEvent keyCode] == 126)?kASMovementUp:kASMovementDown;
        if ([self.provider selectedItemIndex] != NSNotFound) {
            [self.provider moveSelectedItemInDirection:direction];
        } else if ([self.provider selectedInterstitialIndex] != NSNotFound) {
            [self.provider moveInterstitialSelectionInDirection:direction];
            [self setNeedsDisplay:YES];
        }
    }
}

@end
