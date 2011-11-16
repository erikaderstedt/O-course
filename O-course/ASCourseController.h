//
//  ASCourseController.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-16.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ASCourseController : NSObject <NSTableViewDataSource, NSTableViewDelegate> {
    NSManagedObjectContext *managedObjectContext;
    NSArrayController *courses;
    NSTableView *courseTable;
}
@property (nonatomic, retain) IBOutlet NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) IBOutlet NSArrayController *courses;
@property (nonatomic, retain) IBOutlet NSTableView *courseTable;

- (void)willAppear;
- (void)willDisappear;

@end
