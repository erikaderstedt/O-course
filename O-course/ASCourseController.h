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

@interface ASCourseController : NSObject <NSTableViewDataSource, NSTableViewDelegate, ASControlDescriptionProvider, ASCourseDelegate> {
    NSManagedObjectContext *managedObjectContext;
    NSArrayController *courses;
    NSTableView *courseTable;
    
    ASControlDescriptionView *mainControlDescription;
    ASCourseObjectSelectionView *courseObjectSelectionView;
}
@property (nonatomic, retain) IBOutlet NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) IBOutlet NSArrayController *courses;
@property (nonatomic, retain) IBOutlet NSTableView *courseTable;
@property (nonatomic, retain) IBOutlet ASControlDescriptionView *mainControlDescription;
@property (nonatomic, retain) IBOutlet ASCourseObjectSelectionView *courseObjectSelectionView;

- (void)willAppear;
- (void)willDisappear;

@end
