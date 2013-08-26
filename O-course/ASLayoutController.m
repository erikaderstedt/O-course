//
//  ASLayoutController.m
//  O-course
//
//  Created by Erik Aderstedt on 2013-08-26.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import "ASLayoutController.h"

@implementation ASLayoutController

- (void)willAppear {
    [self.layouts addObserver:self forKeyPath:@"arrangedObjects" options:NSKeyValueObservingOptionInitial context:(__bridge void *)(self)];
    [self.layouts addObserver:self forKeyPath:@"arrangedObjects.scale" options:0 context:(__bridge void *)(self)];
    [self.layouts addObserver:self forKeyPath:@"arrangedObjects.paperSize" options:0 context:(__bridge void *)(self)];
}

- (void)willDisappear {
    [self.layouts removeObserver:self forKeyPath:@"arrangedObjects"];
    [self.layouts removeObserver:self forKeyPath:@"arrangedObjects.scale"];
    [self.layouts removeObserver:self forKeyPath:@"arrangedObjects.paperSize"];
    
    // Disconnect outlets to prevent retain loop.
    self.layouts = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void *)(self)) {
        // Restock the table
        [self.layoutsTable reloadData];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[self.layouts arrangedObjects] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if ([[aTableColumn identifier] isEqualToString:@"name"]) {
        if (rowIndex < [[self.layouts arrangedObjects] count]) {
            return [[self.layouts arrangedObjects][rowIndex] valueForKey:@"name"];
        }
    } else if ([[aTableColumn identifier] isEqualToString:@"scale"]) {
        if (rowIndex < [[self.layouts arrangedObjects] count]) {
            return [[self.layouts arrangedObjects][rowIndex] valueForKey:@"scale"];
        }
    } else if ([[aTableColumn identifier] isEqualToString:@"paper"]) {
        if (rowIndex < [[self.layouts arrangedObjects] count]) {
            return [[self.layouts arrangedObjects][rowIndex] valueForKey:@"paperName"];
        }
    }
    return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if ([[aTableColumn identifier] isEqualToString:@"name"]) {
        if (rowIndex < [[self.layouts arrangedObjects] count]) {
            [[self.layouts arrangedObjects][rowIndex - 1] setValue:anObject forKey:@"name"];
        }
    }
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    [self.layouts setSortDescriptors:[aTableView sortDescriptors]];
    [self.layouts rearrangeObjects];
}

#pragma mark NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    NSInteger s = [self.layoutsTable selectedRow];
    if (s == -1) {
        [self.layouts setSelectedObjects:@[]];
    } else if (s < [[self.layouts arrangedObjects] count]) {
        [self.layouts setSelectionIndex:s];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ASLayoutChanged" object:self.layouts.managedObjectContext];
}

@end
