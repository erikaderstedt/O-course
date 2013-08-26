//
//  ASLayoutController.h
//  O-course
//
//  Created by Erik Aderstedt on 2013-08-26.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ASScaleFormatter;

@interface ASLayoutController : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, weak) IBOutlet NSArrayController *layouts;
@property (weak) IBOutlet NSTableView *layoutsTable;

- (void)willAppear;
- (void)willDisappear;

@end
