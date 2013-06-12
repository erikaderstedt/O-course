//
//  ASCourseController.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-16.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASControlDescriptionProvider.h"
#import "ASCourseObject.h"

@class ASControlDescriptionView;
@class ASCourseObjectSelectionView;

@interface ASCourseController : NSObject <NSTableViewDataSource, NSTableViewDelegate, ASCourseProvider, ASCourseDelegate> {
    NSManagedObjectContext *managedObjectContext;
    NSArrayController *courses;
    NSTableView *__weak courseTable;
}
@property (nonatomic, strong) IBOutlet NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) IBOutlet NSArrayController *courses;
@property (nonatomic, weak) IBOutlet NSTableView *courseTable;
@property (nonatomic, weak) IBOutlet ASControlDescriptionView *controlDescription;
@property (nonatomic, weak) IBOutlet NSPanel *coursePanel;
@property (nonatomic, weak) IBOutlet NSPopUpButton *courseSelectionPopup;

- (IBAction)showCoursePanel:(id)sender;
- (IBAction)okCoursePanel:(id)sender;
- (IBAction)cancelCoursePanel:(id)sender;
- (IBAction)addCourse:(id)sender;
- (IBAction)removeCourse:(id)sender;
- (IBAction)duplicateCourse:(id)sender;

- (void)willAppear;
- (void)willDisappear;

@end
