//
//  ASCourseObjectSelectionView.h
//  O-course
//
//  Created by Erik Aderstedt on 2012-05-25.
//  Copyright (c) 2012 Aderstedt Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASControlDescriptionView+CourseObjects.h"

@interface ASCourseObjectSelectionView : NSView {
    NSTrackingArea *activeTrackingArea;
    
    NSInteger numberOfRows;
    NSInteger numberOfColumns;
    
    NSDictionary *textAttributes;
    
    NSRect stringRect;
    CGSize blockSize;
    CGSize viewSize;
}

@property (nonatomic, assign) enum ASControlDescriptionColumn column;
@property (nonatomic, retain) IBOutlet id <ASCourseObjectSelectionViewDelegate> delegate;
@property (nonatomic, retain) IBOutlet id <ASCourseObjectSelectionViewDataSource> dataSource;

- (CGRect)boundsForRow:(NSInteger)rowIndex column:(NSInteger)columnIndex;

@end
