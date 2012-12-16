//
//  ASCourseObjectSelectionView.h
//  O-course
//
//  Created by Erik Aderstedt on 2012-05-25.
//  Copyright (c) 2012 Aderstedt Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASControlDescriptionView.h"



@interface ASCourseObjectSelectionView : NSView {
    NSTrackingArea *activeTrackingArea;
    
    NSInteger numberOfRows;
    NSInteger numberOfColumns;
    
    NSDictionary *textAttributes;
}

@property (nonatomic, assign) enum ASControlDescriptionColumn column;
@property (nonatomic, retain) id <ASCourseObjectSelectionViewDelegate> delegate;
@property (nonatomic, retain) id <ASCourseObjectSelectionViewDataSource> dataSource;

@end
