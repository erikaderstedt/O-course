//
//  ASCourseObjectSelectionView.m
//  O-course
//
//  Created by Erik Aderstedt on 2012-05-25.
//  Copyright (c) 2012 Aderstedt Software AB. All rights reserved.
//

#import "ASCourseObjectSelectionView.h"

#define COLUMNS (12)

@implementation ASCourseObjectSelectionView

@synthesize dataSource, delegate;
@synthesize column=_column;

- (void)awakeFromNib {
    [super awakeFromNib];
    
    NSMutableParagraphStyle *mps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [mps setLineBreakMode:NSLineBreakByTruncatingTail];
    [mps setAlignment:NSCenterTextAlignment];
    
    textAttributes = @{NSParagraphStyleAttributeName: mps,
                       NSFontAttributeName: [NSFont fontWithName:@"Helvetica-Light" size:13.0],
                       NSForegroundColorAttributeName: [NSColor darkGrayColor]};

    [mps release];
    [textAttributes retain];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    [self setFrameSize:[self recalculateWithSize:[self bounds].size]];
}

- (NSSize)recalculateWithSize:(NSSize)newSize {
    numberOfColumns = (self.column == kASAllColumns)?1:COLUMNS;

    viewSize = NSSizeToCGSize(newSize);
    blockSize.width = round(newSize.width / numberOfColumns);
    blockSize.height = round(((numberOfColumns == 1)?(blockSize.width/COLUMNS):blockSize.width));

    NSArray *a = [self.dataSource supportedValuesForColumn:self.column];
    numberOfRows = [a count]/numberOfColumns;
    if ([a count] % numberOfColumns) ++numberOfRows;
    
    numberOfRows++; // For the textual description.
    stringRect = NSMakeRect(0.0, -2.0, viewSize.width, blockSize.height);

    activeTrackingArea = nil;
    [self updateTrackingAreas];
    [self setNeedsDisplay:YES];
    
    return NSMakeSize(blockSize.width*numberOfColumns, blockSize.height*numberOfRows);
}
        
- (void)setFrameSize:(NSSize)newSize {
    NSSize sz = [self frame].size;
    
    if (sz.width != newSize.width || sz.height != newSize.height) {
        newSize = [self recalculateWithSize:newSize];
        [super setFrameSize:newSize];
    }
    
}

- (void)setColumn:(enum ASControlDescriptionColumn)column {
    _column = column;
    [self setFrameSize:[self recalculateWithSize:[self bounds].size]];
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
    
    int row = 0, column = 0;
    for (NSNumber *n in [self.dataSource supportedValuesForColumn:self.column]) {
        NSRect r = NSRectFromCGRect([self boundsForRow:row column:column]);
        NSTrackingArea *ta = [[NSTrackingArea alloc] initWithRect:NSIntegralRect(NSInsetRect(r, 1, 1))
                                                          options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow
                                                            owner:self
                                                         userInfo:@{@"value":n}];
        [self addTrackingArea:ta];

        if (++column == numberOfColumns) {
            row ++;
            column = 0;
        }
    }
}

- (void)mouseDown:(NSEvent *)theEvent {
    if (activeTrackingArea != nil && [activeTrackingArea userInfo]) {
        NSNumber *v = [[activeTrackingArea userInfo] objectForKey:@"value"];
        [self.dataSource setValue:v forColumn:self.column];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent {
    if (activeTrackingArea != nil) {
        [self setNeedsDisplayInRect:[activeTrackingArea rect]];
    }
    activeTrackingArea = [theEvent trackingArea];
    [self setNeedsDisplayInRect:[activeTrackingArea rect]];
    [self setNeedsDisplayInRect:stringRect];
}

- (void)mouseExited:(NSEvent *)theEvent {
    if (activeTrackingArea != nil) {
        [self setNeedsDisplayInRect:[activeTrackingArea rect]];
    }
    activeTrackingArea = nil;
    [self setNeedsDisplayInRect:stringRect];
}

- (CGRect)boundsForRow:(NSInteger)rowIndex column:(NSInteger)columnIndex {

    return CGRectMake(blockSize.width*columnIndex , viewSize.height - blockSize.height*(rowIndex
+1), blockSize.width, blockSize.height);
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:[self bounds]];
    [[NSColor blackColor] set];
    
    
    NSArray *supportedValues = [self.dataSource supportedValuesForColumn:self.column];
    NSInteger rowIndex = 0, columnIndex = 0;
//    NSInteger selectedValue = [self.delegate selectedValueForColumn:self.column];
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    for (NSNumber *aValue in supportedValues) {
        NSRect thisRect = NSRectFromCGRect([self boundsForRow:rowIndex column:columnIndex]);
        if (NSIntersectsRect(thisRect, dirtyRect)) {
            CGPoint midPoint = CGPointMake(((CGFloat)columnIndex + 0.5)*blockSize.width, viewSize.height - (0.5+ (CGFloat)rowIndex)*blockSize.height);
            [[NSColor blackColor] set];
            CFArrayRef paths = [self.dataSource createPathsForColumn:self.column
                                                           withValue:aValue
                                                          atPosition:midPoint
                                                            withSize:blockSize.height ];
            for (int i = 0; i < CFArrayGetCount(paths); i++) {
                CGContextBeginPath(ctx);
                CGContextAddPath(ctx, (CGPathRef)CFArrayGetValueAtIndex(paths, i));
                CGContextFillPath(ctx);
            }
            CFRelease(paths);
        }
        if (++columnIndex == numberOfColumns) {
            ++rowIndex;
            columnIndex = 0;
        }
    }
    if (NSIntersectsRect(stringRect, dirtyRect)) {
        NSString *string = nil;
        
        if (activeTrackingArea != nil && [activeTrackingArea userInfo]) {
            string = [self.dataSource localizedNameForValue:[[[activeTrackingArea userInfo] objectForKey:@"value"] intValue] inColumn:self.column];
        }
                      
        [string drawWithRect:stringRect options:NSStringDrawingUsesLineFragmentOrigin attributes:textAttributes];

    }
    
    if (activeTrackingArea) {
        NSColor *gray = [NSColor colorWithDeviceWhite:0.3 alpha:0.2];
        [gray set];
        [NSBezierPath fillRect:[activeTrackingArea rect]];
    }
}

@end
