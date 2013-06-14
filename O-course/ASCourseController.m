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
#import "OverprintObject.h"
#import "ASCourseObjectSelectionView.h"
#import "ASOcourseDocument.h"
#import "Course.h"

@implementation ASCourseController

@synthesize managedObjectContext;
@synthesize courses;
@synthesize courseTable;
@synthesize controlDescription;

- (void)willAppear {
    [courses addObserver:self forKeyPath:@"arrangedObjects" options:0 context:(__bridge void *)(self)];
}

- (void)willDisappear {
    [courses removeObserver:self forKeyPath:@"arrangedObjects"];
    
    // Disconnect outlets to prevent retain loop.
    self.courses = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void *)(self)) {
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
                return [[self.courses arrangedObjects][(rowIndex - 1)] valueForKey:@"length"];
            }
            return nil;
        }
    } else if ([[aTableColumn identifier] isEqualToString:@"number_of_controls"]) {
        NSPredicate *controlsOnly = [NSPredicate predicateWithFormat:@"overprintObject.type == %@", @(kASOverprintObjectControl)];
        if (rowIndex == 0) {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"CourseObject"];
            [request setPredicate:controlsOnly];
            return @([[self managedObjectContext] countForFetchRequest:request error:nil]);
        } else {
            if (rowIndex - 1 < [[self.courses arrangedObjects] count]) {
                NSManagedObject *thisCourse = [self.courses arrangedObjects][(rowIndex - 1)];
                return @([[[[thisCourse valueForKey:@"courseObjects"] allObjects] filteredArrayUsingPredicate:controlsOnly] count]);
            }
            return nil;
        }
    } else if ([[aTableColumn identifier] isEqualToString:@"course"]) {
        if (rowIndex == 0) {
            return NSLocalizedString(@"<all objects>", nil);
        } else {
            if (rowIndex - 1 < [[self.courses arrangedObjects] count]) {
                return [[self.courses arrangedObjects][(rowIndex - 1)] valueForKey:@"name"];
            }
            return nil;
        }
    }
    return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if ([[aTableColumn identifier] isEqualToString:@"course"]) {
        if (rowIndex > 0 && (rowIndex - 1 < [[self.courses arrangedObjects] count])) {
            [[self.courses arrangedObjects][(rowIndex - 1)] setValue:anObject forKey:@"name"];
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

#pragma mark ASControlDescriptionDataSource

- (Course *)selectedCourse {
    if ([[self.courses selectedObjects] count]) {
        Course *course = [self.courses arrangedObjects][0];
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

- (NSInteger)numberOfControlDescriptionItems {
    if ([[self.courses selectedObjects] count]) {
        NSManagedObject *course = [self.courses arrangedObjects][0];
        return [[course valueForKeyPath:@"courseObjects.@count"] integerValue];
    }
    NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"OverprintObject"];
    return [[self managedObjectContext] countForFetchRequest:fr error:nil];
}

- (void)enumerateControlDescriptionItemsUsingBlock:(void (^)(id<ASControlDescriptionItem>))handler {
    if ([[self.courses selectedObjects] count]) {
        NSManagedObject *course = [self.courses arrangedObjects][0];
        for (NSManagedObject *courseObject in [course valueForKey:@"courseObjects"]) {
            handler([courseObject valueForKey:@"overprintObject"]);
        }
    } else {
        NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"OverprintObject"];
        [fr setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type" ascending:YES],
         [NSSortDescriptor sortDescriptorWithKey:@"added" ascending:YES]]];
        for (OverprintObject *object in [[self managedObjectContext] executeFetchRequest:fr error:nil]) {
            handler(object);
        }
    }
    
}

// Each item returned by the course object enumerator conforms
// to <ASControlDescriptionItem>

#pragma mark ASCourseDataSource

- (BOOL)addOverprintObject:(enum ASOverprintObjectType)objectType atLocation:(CGPoint)location symbolNumber:(NSInteger)symbolNumber {
    
    NSAssert([NSThread isMainThread], @"Not the main thread!");
    
    OverprintObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"OverprintObject" inManagedObjectContext:[self managedObjectContext]];
    object.added = [NSDate date];
    [object setPosition:location];
    
    object.objectType = objectType;
    if (objectType == kASOverprintObjectControl) {
        [object assignNextFreeControlCode];
    }
    [object setSymbolNumber:symbolNumber];
    
    Course *selectedCourse = (Course *)[self selectedCourse];
    if (selectedCourse != nil) {
        [selectedCourse appendOverprintObject:object];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ASCourseChanged" object:self.managedObjectContext];
    
    return YES;
}

- (BOOL)specificCourseSelected {
    return [[self.courses selectedObjects] count];
}

- (void)enumerateOverprintObjectsInSelectedCourseUsingBlock:(void (^)(id <ASOverprintObject> object, NSInteger index))handler {
    __block NSInteger reg = 1;
    Course *selectedCourse = [self selectedCourse];
    if (selectedCourse == nil) return;
    for (NSManagedObject *courseObject in [selectedCourse valueForKey:@"courseObjects"]) {
        OverprintObject *o = [courseObject valueForKey:@"overprintObject"];
        NSAssert(o != nil, @"No overprint object!");
        handler(o, ([o objectType] == kASOverprintObjectControl)?(reg++):(NSNotFound));
    }
}

- (void)enumerateOtherOverprintObjectsUsingBlock:(void (^)(id <ASOverprintObject> object))handler {
    NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"OverprintObject"];
    NSArray *allCourseObjects = [[self managedObjectContext] executeFetchRequest:fr error:nil];

    NSOrderedSet *objectsInSelected = [[self selectedCourse] valueForKeyPath:@"courseObjects.overprintObject"];
    NSMutableSet *notSelected = [NSMutableSet setWithArray:allCourseObjects];
    [notSelected minusSet:[objectsInSelected set]];
    for (OverprintObject *courseObject in notSelected) {
            handler(courseObject);
    }
}

- (void)enumerateAllOverprintObjectsUsingBlock:(void (^)(id <ASOverprintObject> object))handler {
    NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"OverprintObject"];
    NSArray *allCourseObjects = [[self managedObjectContext] executeFetchRequest:fr error:nil];
    
    for (OverprintObject *courseObject in allCourseObjects) {
        handler(courseObject);
    }
}

- (void)appendOverprintObjectToSelectedCourse:(id<ASOverprintObject>)object {
    NSAssert([self specificCourseSelected], @"No specific course selected");
    
    // Get the actual NSManagedObject from the id <ASOverprintObject>
    OverprintObject *o = (OverprintObject *)object;
    [[self selectedCourse] appendOverprintObject:o];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ASCourseChanged" object:self.managedObjectContext];

}

#pragma mark -
#pragma mark Other

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
        NSManagedObject *orign = s[0];
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

