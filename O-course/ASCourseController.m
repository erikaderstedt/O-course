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
#import "ASOcourseDocument.h"

@implementation ASCourseController

@synthesize managedObjectContext;
@synthesize courses;
@synthesize courseTable;
@synthesize controlDescription;

- (void)dealloc {
    [managedObjectContext release];
    [courses release];
    
    [super dealloc];
}

- (void)willAppear {
    [courses addObserver:self forKeyPath:@"arrangedObjects" options:0 context:self];
}

- (void)willDisappear {
    [courses removeObserver:self forKeyPath:@"arrangedObjects"];
    
    // Disconnect outlets to prevent retain loop.
    self.courses = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == self) {
        // Restock the table
        [self updateCoursePopup];
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
    } else if ([[aTableColumn identifier] isEqualToString:@"number_of_controls"]) {
        NSPredicate *controlsOnly = [NSPredicate predicateWithFormat:@"type == %@", @(kASCourseObjectControl)];
        if (rowIndex == 0) {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"CourseObject"];
            [request setPredicate:controlsOnly];
            return @([[self managedObjectContext] countForFetchRequest:request error:nil]);
        } else {
            if (rowIndex - 1 < [[self.courses arrangedObjects] count]) {
                NSManagedObject *thisCourse = [[self.courses arrangedObjects] objectAtIndex:(rowIndex - 1)];
                return @([[[[thisCourse valueForKey:@"controls"] allObjects] filteredArrayUsingPredicate:controlsOnly] count]);
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
        [self.courses setSelectedObjects:@[]];
    } else if (s == 0) {
        [self.courses setSelectedObjects:@[]];
    } else if (s - 1 < [[self.courses arrangedObjects] count]) {
        [self.courses setSelectionIndex:(s-1)];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ASCourseChanged" object:self.managedObjectContext];
}

#pragma mark ASControlDescriptionProvider

- (NSManagedObject *)selectedCourse {
    if ([[self.courses selectedObjects] count]) {
        NSManagedObject *course = [[self.courses arrangedObjects] objectAtIndex:0];
        return course;
    }
    return nil;
}

- (NSString *)eventName {
    Project *p = [Project projectInManagedObjectContext:[self managedObjectContext]];
    if (p == nil) return NSLocalizedString(@"Unknown", @"No event name");;
    return [p valueForKey:@"event"];
}

- (NSString *)classNames {
    return nil;
}

- (NSString *)number {
    return nil;
    
}

- (NSNumber *)length {
    return nil;
    
}

- (NSNumber *)heightClimb {
    return nil; // Not yet implemented.
}

// Each item returned by the course object enumerator conforms
// to <ASControlDescriptionItem>
- (NSEnumerator *)courseObjectEnumerator {
    if ([[self.courses selectedObjects] count]) {
        NSManagedObject *course = [[self.courses arrangedObjects] objectAtIndex:0];
        return [[course valueForKey:@"controls"] objectEnumerator];
    }

    NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"CourseObject"];
    [fr setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type" ascending:YES],
                             [NSSortDescriptor sortDescriptorWithKey:@"added" ascending:YES]]];
    
    return [[managedObjectContext executeFetchRequest:fr error:nil] objectEnumerator];
}

- (BOOL)allObjectsSelected {
    return ![[self.courses selectedObjects] count];
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
    
    NSManagedObject *selectedCourse = [self selectedCourse];
    if (selectedCourse != nil) {
        [[selectedCourse valueForKey:@"controls"] addObject:object];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ASCourseChanged" object:self.managedObjectContext];
    
    return YES;
}

- (IBAction)showCoursePanel:(id)sender {
    [[[self managedObjectContext] undoManager] beginUndoGrouping];
    
    [NSApp beginSheet:self.coursePanel
       modalForWindow:[ASOcourseDocument windowForManagedObjectContext:self.managedObjectContext]
        modalDelegate:self
       didEndSelector:@selector(coursePanelDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (IBAction)okCoursePanel:(id)sender {
    [NSApp endSheet:self.coursePanel returnCode:0];
}

- (IBAction)cancelCoursePanel:(id)sender {
    [NSApp endSheet:self.coursePanel returnCode:1];
}

- (void)coursePanelDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet close];
    [[[self managedObjectContext] undoManager] endUndoGrouping];
    if (returnCode == 1) {
        [[self managedObjectContext] undo];
    }
    [self updateCoursePopup];    
}

- (void)updateCoursePopup {
    // Go through all courses and make sure that there is an item for each one, and remove excessive items.
    NSMenu *menu = [self.courseSelectionPopup menu];
    NSInteger numberOfMenuItems = [[menu itemArray] count];
    NSMutableIndexSet *unusedIndices = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numberOfMenuItems)];
    [unusedIndices removeIndex:0];
    [unusedIndices removeIndex:numberOfMenuItems-1];
    [unusedIndices removeIndex:numberOfMenuItems-2];
    NSMutableArray *coursesWithoutMenuItems = [NSMutableArray arrayWithCapacity:5];
    for (NSManagedObject *course in [self.courses arrangedObjects]) {
        NSString *title = [course valueForKey:@"name"];
        if (title == nil) title = NSLocalizedString(@"New course", nil);
        NSInteger i = [menu indexOfItemWithTitle:title];
        if (i != -1 && [unusedIndices containsIndex:i]) {
            [unusedIndices removeIndex:i];
        } else {
            [coursesWithoutMenuItems addObject:course];
        }
    }
    [unusedIndices enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
        [menu removeItemAtIndex:idx];
    }];
    for (NSManagedObject *course in coursesWithoutMenuItems) {
        NSString *title = [course valueForKey:@"name"];
        if (title == nil) title = NSLocalizedString(@"New course", nil);
        [[menu insertItemWithTitle:title action:@selector(chooseCourse:) keyEquivalent:@"" atIndex:1] setTarget:self];
    }
    
    // Select one in the popup.
    NSManagedObject *course = [self selectedCourse];
    NSInteger index = 0;
    if (course != nil) {
        NSString *title = [course valueForKey:@"name"];
        if (title == nil) title = NSLocalizedString(@"New course", nil);
        index = [menu indexOfItemWithTitle:[course valueForKey:@"name"]];
    }
    [self.courseSelectionPopup selectItemAtIndex:index];
}

- (IBAction)chooseCourse:(id)sender {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Course"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"name == %@", [sender title]]];
    [request setFetchLimit:1];
    NSArray *matchingCourses = [self.managedObjectContext executeFetchRequest:request error:nil];
    [self.courses setSelectedObjects:matchingCourses];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ASCourseChanged" object:self.managedObjectContext];
}

- (IBAction)addCourse:(id)sender {
    [self.courses add:sender];
}

- (IBAction)removeCourse:(id)sender {
    [self.courses remove:sender];
}

- (IBAction)duplicateCourse:(id)sender {
    NSArray *s = [self.courses selectedObjects];
    if ([s count] == 1) {
        NSManagedObject *orign = [s objectAtIndex:0];
        NSManagedObject *dup = [NSEntityDescription insertNewObjectForEntityForName:@"Course" inManagedObjectContext:self.managedObjectContext];
        [dup setValue:[orign valueForKey:@"name"] forKey:@"name"];
        [dup setValue:[orign valueForKey:@"length"] forKey:@"length"];
        [dup setValue:[orign valueForKey:@"cuts"] forKey:@"cuts"];
        for (NSManagedObject *c in [orign valueForKey:@"classes"]) {
            [[dup valueForKey:@"classes"] addObject:c];
        }
        for (NSManagedObject *c in [orign valueForKey:@"courses"]) {
            [[dup valueForKey:@"courses"] addObject:c];
        }
        
        [self.courseTable reloadData];
    }
}

@end

