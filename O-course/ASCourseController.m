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
#import "CourseObject.h"

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

- (void)awakeFromNib {
    [super awakeFromNib];
    _selectedInterstitialIndex = NSNotFound;
    _selectedItemIndex = NSNotFound;
    
    self.managedObjectContext = [self.courses managedObjectContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void *)(self)) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ASCourseChanged" object:self.managedObjectContext userInfo:nil];;

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
    } else if ([[aTableColumn identifier] isEqualToString:@"layout"]) {
        if (rowIndex == 0) {
            return @(0);
        } else {
            Course *thisCourse = [self.courses arrangedObjects][(rowIndex - 1)];
            
            NSMenu *theMenu = [(NSPopUpButtonCell *)[aTableColumn dataCell] menu];
            
            for (NSInteger index = 0; index < [[theMenu itemArray] count]; index++) {
                if ([[[theMenu itemAtIndex:index] representedObject] isEqual:[[thisCourse valueForKey:@"layout"] objectID]]) {
                    return @(index);
                }
            }

            return @(NSNotFound);
        }
    }
    return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if ([[aTableColumn identifier] isEqualToString:@"course"]) {
        if (rowIndex > 0 && (rowIndex - 1 < [[self.courses arrangedObjects] count])) {
            [[self.courses arrangedObjects][(rowIndex - 1)] setValue:anObject forKey:@"name"];
        }
    } else if ([[aTableColumn identifier] isEqualToString:@"layout"]) {
        if (rowIndex > 0 && (rowIndex - 1 < [[self.courses arrangedObjects] count])) {
            Course *thisCourse = [self.courses arrangedObjects][(rowIndex - 1)];
            
            if ([anObject integerValue] != NSNotFound) {
                NSMenu *theMenu = [(NSPopUpButtonCell *)[aTableColumn dataCell] menu];
                NSMenuItem *theMenuItem = [theMenu itemAtIndex:[anObject intValue]];
            
                [thisCourse setValue:[[self managedObjectContext] objectWithID:[theMenuItem representedObject]] forKey:@"layout"];
            } else {
                [thisCourse setValue:nil forKey:@"layout"];
            }
        }
    }
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([[tableColumn identifier] isEqualToString:@"layout"]) {
        // Make sure that the cell menu is correct.
        NSMenu *menu = [(NSPopUpButtonCell *)cell menu];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Layout"];
        [request setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"default" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
        NSArray *layouts = [[self managedObjectContext] executeFetchRequest:request error:nil];
        NSMutableArray *itemsToKeep = [NSMutableArray arrayWithCapacity:10];
        for (NSManagedObject *layout in layouts) {
            BOOL inMenu = NO;
            for (NSMenuItem *item in [menu itemArray]) {
                if ([item representedObject] == [layout objectID]) {
                    [itemsToKeep addObject:item];
                    inMenu = YES;
                    break;
                }
            }
            if (!inMenu) {
                NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[layout valueForKey:@"name"] action:nil keyEquivalent:@""];
                [item setRepresentedObject:[layout objectID]];
                [menu addItem:item];
                [itemsToKeep addObject:item];
            }
        }
        NSMutableSet *removeThese = [NSMutableSet setWithArray:[menu itemArray]];
        [removeThese minusSet:[NSSet setWithArray:itemsToKeep]];
        for (NSMenuItem *item in removeThese) {
            [menu removeItem:item];
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
    self.selectedItemIndex = NSNotFound;
    self.selectedInterstitialIndex = NSNotFound;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ASCourseChanged" object:self.managedObjectContext];
}

#pragma mark ASControlDescriptionDataSource

- (Course *)selectedCourse {
    if ([[self.courses selectedObjects] count]) {
        Course *course = [self.courses selectedObjects][0];
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
    if ([[self.courses selectedObjects] count]) {
        Course *course = [self.courses selectedObjects][0];
        return [course valueForKey:@"name"];
    }
    return nil;
}

- (NSString *)number {
    return nil;
    
}

- (NSNumber *)length {
    if ([[self.courses selectedObjects] count]) {
        Course *course = [self.courses selectedObjects][0];
        return @([course length]);
    }
    return nil;
}

- (id)project {
    return self.managedObjectContext;
}

- (NSNumber *)heightClimb {
    return nil; // Not yet implemented.
}

- (NSInteger)numberOfControlDescriptionItems {
    Course *selectedCourse = [self selectedCourse];
    if (selectedCourse != nil) {
        return [[selectedCourse valueForKey:@"courseObjects"] count];
    }

    NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"OverprintObject"];
    return [[self managedObjectContext] countForFetchRequest:fr error:nil];
}

- (void)enumerateControlDescriptionItemsUsingBlock:(void (^)(id<ASControlDescriptionItem>))handler {
    Course *selectedCourse = [self selectedCourse];
    if (selectedCourse != nil) {
        NSOrderedSet *courseObjects = [selectedCourse valueForKey:@"courseObjects"];
        for (id <ASControlDescriptionItem> courseObject in courseObjects) {
            handler(courseObject);
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

- (NSInteger)numberOfItemsPrecedingActualCourseObjects {
    NSInteger numberOfPreItems = 0;
    if ([self eventName]) numberOfPreItems++;
    if ([self classNames]) numberOfPreItems ++;
    if ([self number] || [self length]) numberOfPreItems ++;
    return numberOfPreItems;
}

- (void)moveSelectedItemInDirection:(enum ASControlDescriptionItemMovementDirection)direction {
    Course *selectedCourse = [self selectedCourse];
    if (selectedCourse == nil || self.selectedItemIndex == NSNotFound) return;
    
    NSMutableOrderedSet *mos = [selectedCourse mutableOrderedSetValueForKey:@"courseObjects"];
    
    if (direction == kASMovementUp) {
        if (self.selectedItemIndex > 0) {
            [mos exchangeObjectAtIndex:self.selectedItemIndex withObjectAtIndex:self.selectedItemIndex-1];
            self.selectedItemIndex --;
        }
    } else if (direction == kASMovementDown) {
        if (self.selectedItemIndex + 1 < [mos count]) {
            [mos exchangeObjectAtIndex:self.selectedItemIndex withObjectAtIndex:self.selectedItemIndex+1];
            self.selectedItemIndex ++;
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ASCourseChanged" object:self.managedObjectContext];
}

- (void)moveInterstitialSelectionInDirection:(enum ASControlDescriptionItemMovementDirection)direction {
    Course *selectedCourse = [self selectedCourse];
    if (selectedCourse == nil || self.selectedInterstitialIndex == NSNotFound) return;
    if (direction == kASMovementUp && self.selectedInterstitialIndex > 0) {
        self.selectedInterstitialIndex --;
    } else if (direction == kASMovementDown && self.selectedInterstitialIndex + 1 < [[selectedCourse valueForKey:@"courseObjects"] count]) {
        self.selectedInterstitialIndex ++;
    }
}

- (void)deleteSelectedItem {
    Course *selectedCourse = [self selectedCourse];
    if (selectedCourse == nil) {
        // Remove it altogether
        NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"OverprintObject"];
        [fr setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type" ascending:YES],
                                 [NSSortDescriptor sortDescriptorWithKey:@"added" ascending:YES]]];
        [fr setFetchOffset:self.selectedItemIndex];
        [fr setFetchLimit:1];
        
        self.selectedItemIndex = NSNotFound;
        NSArray *a = [[self managedObjectContext] executeFetchRequest:fr error:nil];
        if ([a count] != 1) {
            NSLog(@"Bad course object selection when deleting!");
        } else {
            [[self managedObjectContext] deleteObject:a[0]];
        }
    } else {
        // Remove it from the course
        NSMutableOrderedSet *mos = [selectedCourse mutableOrderedSetValueForKey:@"courseObjects"];
        CourseObject *courseObject = [mos objectAtIndex:self.selectedItemIndex];
        [mos removeObjectAtIndex:self.selectedItemIndex];
        courseObject.overprintObject = nil;
        [self.managedObjectContext deleteObject:courseObject];
        [[self managedObjectContext] processPendingChanges];
        
        self.selectedItemIndex = NSNotFound;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ASCourseChanged" object:self.managedObjectContext];
}

- (NSInteger)selectedInterstitialIndex {
    return _selectedInterstitialIndex;
}

- (void)setSelectedInterstitialIndex:(NSInteger)selectedInterstitialIndex {
    [self willChangeValueForKey:@"selectedItemIndex"];
    _selectedItemIndex = NSNotFound;
    [self didChangeValueForKey:@"selectedItemIndex"];
    _selectedInterstitialIndex = selectedInterstitialIndex;
}

- (NSInteger)selectedItemIndex {
    return _selectedItemIndex;
}

- (void)setSelectedItemIndex:(NSInteger)selectedItemIndex {
    [self willChangeValueForKey:@"selectedInterstitialIndex"];
    _selectedInterstitialIndex = NSNotFound;
    [self didChangeValueForKey:@"selectedInterstitialIndex"];
    
    _selectedItemIndex = selectedItemIndex;
}

+ (NSSet *)keyPathsForValuesAffectingSelectedCourseObject { return [NSSet setWithObject:@"selectedItemIndex"]; }
- (void)setSelectedCourseObject:(id<ASControlDescriptionItem>)selectedCourseObject {
    Course *selectedCourse = [self selectedCourse];
    if (selectedCourse != nil) {
        NSOrderedSet *courseObjects = [selectedCourse valueForKey:@"courseObjects"];
        self.selectedItemIndex = [courseObjects indexOfObject:selectedCourseObject];
    } else {
        NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"OverprintObject"];
        [fr setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type" ascending:YES],
                                 [NSSortDescriptor sortDescriptorWithKey:@"added" ascending:YES]]];
        NSArray *a = [[self managedObjectContext] executeFetchRequest:fr error:nil];
        self.selectedItemIndex = [a indexOfObject:selectedCourseObject];
    }
}

- (id <ASControlDescriptionItem>)selectedCourseObject {
    Course *selectedCourse = [self selectedCourse];
    if (selectedCourse != nil) {
        NSOrderedSet *courseObjects = [selectedCourse valueForKey:@"courseObjects"];
        return [courseObjects objectAtIndex:self.selectedItemIndex];
    } else {
        NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"OverprintObject"];
        [fr setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type" ascending:YES],
                                 [NSSortDescriptor sortDescriptorWithKey:@"added" ascending:YES]]];
        NSArray *a = [[self managedObjectContext] executeFetchRequest:fr error:nil];
        return [a objectAtIndex:self.selectedItemIndex];
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

- (void)removeLastOccurrenceOfOverprintObjectFromSelectedCourse:(id <ASOverprintObject>)object {
    NSAssert([self specificCourseSelected], @"No specific course selected");
    Course *selectedCourse = (Course *)[self selectedCourse];
    if (selectedCourse != nil) {
        [selectedCourse removeLastOccurrenceOfOverprintObject:(OverprintObject *)object];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ASCourseChanged" object:self.managedObjectContext];
    }
}

- (void)removeOverprintObject:(id<ASOverprintObject>)object {
    // The model should be set up correctly to cascade this to course objects.
    [self.managedObjectContext deleteObject:object];
    [self.managedObjectContext processPendingChanges];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ASCourseChanged" object:self.managedObjectContext];
}

- (BOOL)specificCourseSelected {
    return [[self.courses selectedObjects] count];
}

- (void)enumerateOverprintObjectsInSelectedCourseUsingBlock:(void (^)(id <ASOverprintObject> object, NSInteger index, CGPoint controlNumberPosition))handler {
    __block NSInteger reg = 1;
    Course *selectedCourse = [self selectedCourse];
    if (selectedCourse == nil) return;
    for (NSManagedObject *courseObject in [selectedCourse valueForKey:@"courseObjects"]) {
        OverprintObject *o = [courseObject valueForKey:@"overprintObject"];
        NSAssert(o != nil, @"No overprint object!");
        CGPoint numberPosition = CGPointMake([[courseObject valueForKey:@"position_x"] doubleValue], [[courseObject valueForKey:@"position_y"] doubleValue]);
        handler(o, ([o objectType] == kASOverprintObjectControl)?(reg++):(NSNotFound), numberPosition);
    }
}

- (void)enumerateOtherOverprintObjectsUsingBlock:(void (^)(id <ASOverprintObject> object, NSInteger index, CGPoint controlNumberPosition))handler {
    NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"OverprintObject"];
    NSArray *allCourseObjects = [[self managedObjectContext] executeFetchRequest:fr error:nil];

    NSOrderedSet *objectsInSelected = [[self selectedCourse] valueForKeyPath:@"courseObjects.overprintObject"];
    NSMutableSet *notSelected = [NSMutableSet setWithArray:allCourseObjects];
    [notSelected minusSet:[objectsInSelected set]];
    for (OverprintObject *courseObject in notSelected) {
        handler(courseObject, [[courseObject controlCode] integerValue], [courseObject controlCodePosition]);
    }
}

- (void)enumerateAllOverprintObjectsUsingBlock:(void (^)(id <ASOverprintObject> object))handler {
    NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"OverprintObject"];
    NSArray *allCourseObjects = [[self managedObjectContext] executeFetchRequest:fr error:nil];
    
    for (OverprintObject *courseObject in allCourseObjects) {
        handler(courseObject);
    }
}

- (void)addOverprintObjectToSelectedCourse:(id<ASOverprintObject>)object {
    NSAssert([self specificCourseSelected], @"No specific course selected");
    
    // Get the actual NSManagedObject from the id <ASOverprintObject>
    OverprintObject *o = (OverprintObject *)object;
    Course *s = [self selectedCourse];
    NSInteger i = self.selectedInterstitialIndex;
    NSInteger c = [[s valueForKey:@"courseObjects"] count];
    if (i == NSNotFound) i = c; else i++;
    [[self selectedCourse] insertOverprintObject:o atPosition:i];

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
        [[[self managedObjectContext] undoManager] undo];
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
    
    self.selectedInterstitialIndex = NSNotFound;
    self.selectedItemIndex = NSNotFound;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ASCourseChanged" object:self.managedObjectContext];
}

- (IBAction)addCourse:(id)sender {
    NSManagedObject *dup = [NSEntityDescription insertNewObjectForEntityForName:@"Course" inManagedObjectContext:self.managedObjectContext];
    [dup setValue:[Project projectInManagedObjectContext:self.managedObjectContext] forKey:@"project"];
    [self.courses addObject:dup];
    [self.courseTable reloadData];
}

- (IBAction)removeCourse:(id)sender {
    [self.courses remove:sender];
}

- (IBAction)duplicateCourse:(id)sender {
    NSArray *s = [self.courses selectedObjects];
    if ([s count] == 1) {
        NSManagedObject *orign = s[0];
        NSManagedObject *dup = [NSEntityDescription insertNewObjectForEntityForName:@"Course" inManagedObjectContext:self.managedObjectContext];
        [dup setValue:[orign valueForKey:@"project"] forKey:@"project"];
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

