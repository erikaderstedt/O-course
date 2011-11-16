//
//  ASCourseController.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-16.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASCourseController.h"

@implementation ASCourseController

@synthesize managedObjectContext;
@synthesize courses;
@synthesize courseTable;

- (void)dealloc {
    [managedObjectContext release];
    [courses release];
    [courseTable release];
    
    [super dealloc];
}

- (void)willAppear {
    NSLog(@"Course controller setup");
    [courses addObserver:self forKeyPath:@"arrangedObjects" options:0 context:self];
}

- (void)willDisappear {
    [courses removeObserver:self forKeyPath:@"arrangedObjects"];
    
    // Disconnect outlets to prevent retain loop.
    self.courseTable = nil;
    self.courses = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == self) {
        // Restock the table
        [self.courseTable reloadData];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark NSTableViewDataSource

// Vi visar alltid <alla objekt> överst i tabellen, oavsett sortering.
// Dels för att det blir enklast så, och dels för att den är "viktigast".

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return 1 + [[self.courses arrangedObjects] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if ([[aTableColumn identifier] isEqualToString:@"length"]) {
        if (rowIndex == 0) {
            return nil;
        } else {
            if (rowIndex - 1 < [[self.courses arrangedObjects] count]) {
                return [[[self.courses arrangedObjects] objectAtIndex:(rowIndex - 1)] valueForKey:@"length"];
            }
            return nil;
        }
    } else if ([[aTableColumn identifier] isEqualToString:@"course"]) {
        if (rowIndex == 0) {
            return NSLocalizedString(@"<all objects>", nil);
        } else {
            if (rowIndex - 1 < [[self.courses arrangedObjects] count]) {
                return [[[self.courses arrangedObjects] objectAtIndex:(rowIndex - 1)] valueForKey:@"name"];
            }
            return nil;
        }
    }
    return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if ([[aTableColumn identifier] isEqualToString:@"course"]) {
        if (rowIndex > 0 && (rowIndex - 1 < [[self.courses arrangedObjects] count])) {
            [[[self.courses arrangedObjects] objectAtIndex:(rowIndex - 1)] setValue:anObject forKey:@"name"];
        }
    }
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    [self.courses setSortDescriptors:[aTableView sortDescriptors]];
    [self.courses rearrangeObjects];
}

@end
