//
//  ASCourseController.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-16.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASCourseController.h"
#import "ASControlDescriptionView.h"
#import "ASControlDescriptionView+CourseObjects.h"
#import "Project.h"
#import "CourseObject.h"
#import "ASCourseObjectSelectionView.h"

@implementation ASCourseController

@synthesize managedObjectContext;
@synthesize courses;
@synthesize courseTable;
@synthesize mainControlDescription;
@synthesize courseObjectSelectionView;

- (void)dealloc {
    [managedObjectContext release];
    [courses release];
    [courseTable release];
    [mainControlDescription release];
    
    [super dealloc];
}

- (void)willAppear {
    courseObjectSelectionView.dataSource = mainControlDescription;
    courseObjectSelectionView.column = kASFeature;
    [courses addObserver:self forKeyPath:@"arrangedObjects" options:0 context:self];
}

- (void)willDisappear {
    [courses removeObserver:self forKeyPath:@"arrangedObjects"];
    
    // Disconnect outlets to prevent retain loop.
    self.courseTable = nil;
    self.courses = nil;
    self.mainControlDescription = nil;
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

#pragma mark NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    NSInteger s = [self.courseTable selectedRow];
    if (s == -1) {
        [self.mainControlDescription setCourse:nil];
    } else if (s == 0) {
        [self.mainControlDescription setCourse:self]; // "Special" object
    } else if (s - 1 < [[self.courses arrangedObjects] count]) {
        [self.mainControlDescription setCourse:[[self.courses arrangedObjects] objectAtIndex:(s-1)]];
        [self.courses setSelectionIndex:(s-1)];
    }
}


#pragma mark ASControlDescriptionProvider

- (NSString *)eventName {
    Project *p = [Project projectInManagedObjectContext:[self managedObjectContext]];
    if (p == nil) return NSLocalizedString(@"Unknown", @"No event name");;
    return [p valueForKey:@"event"];
}

- (NSString *)classNamesForCourse:(id)course {
    return nil;
}

- (NSString *)numberForCourse:(id)course {
    return nil;
    
}

- (NSNumber *)lengthOfCourse:(id)course {
    return nil;
    
}

- (NSNumber *)heightClimbForCourse:(id)course {
    return nil; // Not yet implemented.
}

// Each item returned by the course object enumerator conforms
// to <ASControlDescriptionItem>
- (NSEnumerator *)courseObjectEnumeratorForCourse:(id)course {
    if ([course isKindOfClass:[NSManagedObject class]])
        return [[course valueForKey:@"controls"] objectEnumerator];
        
    NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"CourseObject"];
    [fr setSortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"type" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"added" ascending:YES], nil]];
    
    return [[managedObjectContext executeFetchRequest:fr error:nil] objectEnumerator];
}


- (BOOL)addCourseObject:(enum ASCourseObjectType)objectType atLocation:(CGPoint)location symbolNumber:(NSInteger)symbolNumber {
    
    NSAssert([NSThread isMainThread], @"Not the main thread!");
    
    CourseObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"CourseObject" inManagedObjectContext:[self managedObjectContext]];
    object.added = [NSDate date];
    [object setPosition:location];
    
    object.objectType = objectType;
    if (objectType == kASCourseObjectControl) {
        [object assignNextFreeControlCode];
    }
    [object setSymbolNumber:symbolNumber];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ASCourseChanged" object:self.managedObjectContext];
    
    return YES;
}

@end

