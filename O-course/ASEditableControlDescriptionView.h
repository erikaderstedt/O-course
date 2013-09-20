//
//  ASEditableControlDescriptionView.h
//  O-course
//
//  Created by Erik Aderstedt on 2012-05-25.
//  Copyright (c) 2012 Aderstedt Software AB. All rights reserved.
//

#import "ASControlDescriptionView.h"

@class ASCourseObjectSelectionView;

@interface ASEditableControlDescriptionView : ASControlDescriptionView  <NSPopoverDelegate> {
    NSTrackingArea *activeTrackingArea;
    
    NSInteger selectedControlDescriptionIndex; // Start through finish
    NSInteger selectedControlDescriptionInterstitialIndex;
}

@property (nonatomic,weak) IBOutlet ASCourseObjectSelectionView *selectionView;
@property (nonatomic,weak) IBOutlet NSPopover *popoverForCDEGH;
@property (nonatomic,strong) id <ASEditableControlDescriptionItem> activeObject;
@property (nonatomic,weak) IBOutlet NSPopover *popoverForB;


@end
