//
//  ASCourseController.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-16.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASControlDescriptionProvider.h"

@class ASControlDescriptionView;

@interface ASCourseController : NSObject <NSTableViewDataSource, NSTableViewDelegate, ASControlDescriptionProvider> {
    NSManagedObjectContext *managedObjectContext;
    NSArrayController *courses;
    NSTableView *courseTable;
    
    ASControlDescriptionView *mainControlDescription;
}
@property (nonatomic, retain) IBOutlet NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) IBOutlet NSArrayController *courses;
@property (nonatomic, retain) IBOutlet NSTableView *courseTable;
@property (nonatomic, retain) IBOutlet ASControlDescriptionView *mainControlDescription;

- (void)willAppear;
- (void)willDisappear;

@end
