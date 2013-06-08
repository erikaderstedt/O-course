//
//  ASEditableControlDescriptionView.h
//  O-course
//
//  Created by Erik Aderstedt on 2012-05-25.
//  Copyright (c) 2012 Aderstedt Software AB. All rights reserved.
//

#import "ASControlDescriptionView.h"

@class ASCourseObjectSelectionView;

@interface ASEditableControlDescriptionView : ASControlDescriptionView {
    NSTrackingArea *activeTrackingArea;
}

@property (nonatomic,assign) IBOutlet ASCourseObjectSelectionView *selectionView;
@property (nonatomic,assign) IBOutlet NSPopover *popoverForCDEGH;
@property (nonatomic,retain) id <ASEditableControlDescriptionItem> activeObject;

@end
