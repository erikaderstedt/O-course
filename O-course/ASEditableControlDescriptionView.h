//
//  ASEditableControlDescriptionView.h
//  O-course
//
//  Created by Erik Aderstedt on 2012-05-25.
//  Copyright (c) 2012 Aderstedt Software AB. All rights reserved.
//

#import "ASControlDescriptionView.h"

@interface ASEditableControlDescriptionView : ASControlDescriptionView {
    NSTrackingArea *activeTrackingArea;
}

@property (nonatomic,assign) IBOutlet NSPopover *popoverForCDEGH;

@end
