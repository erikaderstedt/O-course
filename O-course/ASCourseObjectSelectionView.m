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
    
    textAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                      mps, NSParagraphStyleAttributeName,
                      [NSFont fontWithName:@"Helvetica-Bold" size:11.0], NSFontAttributeName, 
                      [NSColor grayColor], NSForegroundColorAttributeName, nil];
    [mps release];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    self.column = kASFeature;
    
}

- (NSSize)recalculateWithSize:(NSSize)newSize {
    numberOfColumns = (self.column == kASAllColumns)?1:COLUMNS;
    CGSize blockSize;
    
    blockSize.width = newSize.width / numberOfColumns;
    blockSize.height = ((numberOfColumns == 1)?(blockSize.width/COLUMNS):blockSize.width);
    
    NSArray *a = [self.dataSource supportedValuesForColumn:self.column];
    numberOfRows = [a count]/numberOfColumns;
    if ([a count] % numberOfColumns) ++numberOfRows;
    
    numberOfRows++; // For the textual description.

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

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:[self bounds]];
    [[NSColor blackColor] set];
    
    CGSize blockSize;    
    NSRect bounds = [self bounds];
    
    blockSize.width = bounds.size.width / numberOfColumns;
    blockSize.height = bounds.size.height / numberOfRows;
        
    NSArray *supportedValues = [self.dataSource supportedValuesForColumn:self.column];
    NSInteger rowIndex = 0, columnIndex = 0;
//    NSInteger selectedValue = [self.delegate selectedValueForColumn:self.column];
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    for (NSNumber *aValue in supportedValues) {
        CGPoint midPoint = CGPointMake(((CGFloat)columnIndex + 0.5)*blockSize.width, bounds.size.height - (0.5+ (CGFloat)rowIndex)*blockSize.height);
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
        if (++columnIndex == numberOfColumns) {
            ++rowIndex;
            columnIndex = 0;
        }
    }
}

@end
