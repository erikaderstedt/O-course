//
//  ASLayoutController.m
//  O-course
//
//  Created by Erik Aderstedt on 2013-08-26.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import "ASLayoutController.h"
#import "Layout.h"

NSString *const ASLayoutChanged = @"_ASLayoutChanged";
NSString *const ASLayoutVisibleItemsChanged = @"_ASLayoutVisibleItemsChanged";
NSString *const ASLayoutScaleChanged = @"_ASLayoutScaleChanged";
NSString *const ASLayoutOrientationChanged = @"_ASLayoutOrientationChanged";
NSString *const ASLayoutFrameColorChanged = @"_ASLayoutFrameColorChanged";
NSString *const ASLayoutFrameChanged = @"_ASLayoutFrameDetailsChanged";
NSString *const ASLayoutEventDetailsChanged = @"_ASLayoutEventDetailsChanged";

@implementation ASLayoutController

@synthesize landForms, rocksAndCliffs, waterAndMarsh, vegetation, manMade, recognizesSymbols;

- (void)willAppear {
    if ([[self.layouts arrangedObjects] count] == 0) {
        [self.layouts fetch:nil];
    }
//    [self.layouts addObserver:self forKeyPath:@"arrangedObjects" options:0 context:(__bridge void *)(self)];
    [self.layouts addObserver:self forKeyPath:@"selection.scale" options:0 context:(__bridge void *)(self)];
    [self.layouts addObserver:self forKeyPath:@"selection.paperSize" options:0 context:(__bridge void *)(self)];
    [self.layouts addObserver:self forKeyPath:@"selection.orientation" options:0 context:(__bridge void *)(self)];
    [self.layouts addObserver:self forKeyPath:@"selection.frameColor" options:0 context:(__bridge void *)(self)];
    [self.layouts addObserver:self forKeyPath:@"selection.frameVisible" options:0 context:(__bridge void *)(self)];
    [self.layouts addObserver:self forKeyPath:@"selection.showEventName" options:0 context:(__bridge void *)(self)];
    [self.layouts addObserver:self forKeyPath:@"selection.showEventDate" options:0 context:(__bridge void *)(self)];
    
    [self.layouts addObserver:self forKeyPath:@"selection" options:0 context:NULL];
    [self.visibleSymbolsTable reloadData];
    self.observing = YES;
}

- (void)willDisappear {
    if (self.observing) {
//        [self.layouts removeObserver:self forKeyPath:@"arrangedObjects"];
        [self.layouts removeObserver:self forKeyPath:@"selection.scale"];
        [self.layouts removeObserver:self forKeyPath:@"selection.paperSize"];
        [self.layouts removeObserver:self forKeyPath:@"selection.orientation"];
        [self.layouts removeObserver:self forKeyPath:@"selection.frameColor"];
        [self.layouts removeObserver:self forKeyPath:@"selection.frameVisible"];
        [self.layouts removeObserver:self forKeyPath:@"selection.showEventName"];
        [self.layouts removeObserver:self forKeyPath:@"selection.showEventDate"];
        [self.layouts removeObserver:self forKeyPath:@"selection"];
        self.observing = NO;
    }
}

- (void)dealloc {
    self.layoutsTable = nil;
    self.visibleSymbolsTable = nil;
    self.landForms = nil;
    self.waterAndMarsh = nil;
    self.rocksAndCliffs = nil;
    self.vegetation = nil;
    self.manMade = nil;
}
/*
- (void)awakeFromNib {
    if ([super respondsToSelector:@selector(awakeFromNib)]) [super awakeFromNib];
    
    NSView *v1 = [self.layoutsTable enclosingScrollView];
    NSView *v2 = [self.visibleSymbolsTable enclosingScrollView];
    NSView *v3 = [v1 superview];
    
    [v3 addConstraint:[NSLayoutConstraint constraintWithItem:v1 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:v2 attribute:NSLayoutAttributeHeight multiplier:0.35 constant:0.0]];
}
*/
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void *)(self)) {
        // Restock the table
            [self.layoutsTable reloadData];
            [self.visibleSymbolsTable reloadData];
        /*if ([keyPath isEqualToString:@"arrangedObjects"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ASLayoutChanged object:self.layouts.managedObjectContext];
        } else*/ if ([keyPath isEqualToString:@"selection.scale"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ASLayoutScaleChanged object:self.layouts.managedObjectContext];
        } else if ([keyPath isEqualToString:@"selection.paperSize"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ASLayoutOrientationChanged object:self.layouts.managedObjectContext];
        } else if ([keyPath isEqualToString:@"selection.orientation"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ASLayoutOrientationChanged object:self.layouts.managedObjectContext];
        } else if ([keyPath isEqualToString:@"selection.frameColor"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ASLayoutFrameColorChanged object:self.layouts.managedObjectContext];
        } else if ([keyPath isEqualToString:@"selection.frameVisible"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ASLayoutFrameChanged object:self.layouts.managedObjectContext];
        } else if ([keyPath isEqualToString:@"selection.showEventName"] || [keyPath isEqualToString:@"selection.showEventDate"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ASLayoutEventDetailsChanged object:self.layouts.managedObjectContext];
        }
    } else if (object == self.layouts && [keyPath isEqualToString:@"selection"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ASLayoutChanged object:self.layouts.managedObjectContext];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setSymbolList:(NSArray *)symbolList {
    if ([symbolList count] > 0) {
        self.recognizesSymbols = YES;
        NSMutableArray *m100 = [NSMutableArray arrayWithCapacity:20];
        NSMutableArray *m200 = [NSMutableArray arrayWithCapacity:20];
        NSMutableArray *m300 = [NSMutableArray arrayWithCapacity:20];
        NSMutableArray *m400 = [NSMutableArray arrayWithCapacity:20];
        NSMutableArray *m500 = [NSMutableArray arrayWithCapacity:20];
        
        for (NSDictionary *symbol in symbolList) {
            NSInteger grp = [[symbol valueForKey:@"number"] integerValue] / 100;
            switch (grp) {
                case 1:
                    [m100 addObject:symbol];
                    break;
                case 2:
                    [m200 addObject:symbol];
                    break;
                case 3:
                    [m300 addObject:symbol];
                    break;
                case 4:
                    [m400 addObject:symbol];
                    break;
                case 5:
                    [m500 addObject:symbol];
                    break;
                default:
                    break;
            }
        }
        NSComparisonResult (^comparator)(id, id) = ^(id obj1, id obj2) {
            return [[(NSDictionary *)obj1 valueForKey:@"number"] compare:[(NSDictionary *)obj2 valueForKey:@"number"]];
        };
        [m100 sortUsingComparator:comparator];
        [m200 sortUsingComparator:comparator];
        [m300 sortUsingComparator:comparator];
        [m400 sortUsingComparator:comparator];
        [m500 sortUsingComparator:comparator];
        
        self.landForms = m100;
        self.rocksAndCliffs = m200;
        self.waterAndMarsh = m300;
        self.vegetation = m400;
        self.manMade = m500;
    } else {
        self.landForms = nil;
        self.rocksAndCliffs = nil;
        self.waterAndMarsh = nil;
        self.vegetation = nil;
        self.manMade = nil;
        self.recognizesSymbols = NO;
    }
}

- (NSArray *)symbolList {
    NSAssert(NO, @"Why are you here?");
    return nil;
}

#pragma mark Getting information on the current layout

- (Layout *)selectedLayout {
    NSArray *selectedLayouts = [self.layouts selectedObjects];
    if ([selectedLayouts count] != 1) {
        return nil;
    }
    return selectedLayouts[0];
}

- (const int32_t *)hiddenObjects:(size_t *)count {
    Layout *selectedLayout = [self selectedLayout];
    if (selectedLayout == nil) {
        *count = 0;
        return NULL;
    };
    
    return [selectedLayout hiddenObjects:count];
}

- (NSInteger)scale {
    Layout *selectedLayout = [self selectedLayout];
    if (selectedLayout == nil) return 10000;
    return [[selectedLayout scale] integerValue];
}

- (NSPrintingOrientation)orientation {
    Layout *selectedLayout = [self selectedLayout];
    if (selectedLayout == nil) return NSLandscapeOrientation;
    return [[selectedLayout valueForKey:@"orientation"] integerValue];
}

- (NSSize)paperSize {
    Layout *selectedLayout = [self selectedLayout];
    if (selectedLayout == nil) return NSMakeSize(210, 297);
    
    return [selectedLayout paperSize];
}

- (CGColorRef)frameColor {
    Layout *selectedLayout = [self selectedLayout];
    if (selectedLayout == nil) return NULL;
    
    BOOL frameVisible = [[selectedLayout frameVisible] boolValue];
    if (!frameVisible) return NULL;
    
    return [(NSColor *)[selectedLayout frameColor] CGColor];
}

- (BOOL)frameVisible {
    Layout *selectedLayout = [self selectedLayout];
    if (selectedLayout == nil) return NO;
    
    return [[selectedLayout frameVisible] boolValue];
}

- (CGPoint)layoutCenterPosition {
    Layout *selectedLayout = [self selectedLayout];
    if (selectedLayout == nil) {
        selectedLayout = [Layout defaultLayoutInContext:self.layouts.managedObjectContext];
    }
    
    return [selectedLayout position];
}

- (void)writeLayoutCenterPosition:(CGPoint)centerPosition {
    Layout *selectedLayout = [self selectedLayout];
    if (selectedLayout == nil) {
        return;
    }
    
    selectedLayout.position = centerPosition;
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
            [[self.layouts arrangedObjects][rowIndex] setValue:anObject forKey:@"name"];
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
}

#pragma mark NSOutlineViewDataSource 

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (self.recognizesSymbols) {
        if (item == nil) {
            return 5;
        } else if ([item isKindOfClass:[NSArray class]]) {
            return [(NSArray *)item count];
        }
    }
    return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if (self.recognizesSymbols && ([item isKindOfClass:[NSArray class]])) {
        return YES;
    }
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        switch (index) {
            case 0:
                return self.landForms;
                break;
            case 1:
                return self.rocksAndCliffs;
                break;
            case 2:
                return self.waterAndMarsh;
                break;
            case 3:
                return self.vegetation;
                break;
            case 4:
                return self.manMade;
                break;
            default:
                break;
        }
    } else {
        if (index >= 0 && index < [(NSArray *)item count]) {
            return [(NSArray *)item objectAtIndex:index];
        }
    }
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if ([[tableColumn identifier] isEqualToString:@"name"]) {
        if ([item isKindOfClass:[NSArray class]]) {
            if (item == self.landForms) return NSLocalizedString(@"landforms", nil);
            if (item == self.rocksAndCliffs) return NSLocalizedString(@"rocksandcliffs", nil);
            if (item == self.waterAndMarsh) return NSLocalizedString(@"waterandmarsh", nil);
            if (item == self.vegetation) return NSLocalizedString(@"vegetation", nil);
            if (item == self.manMade) return NSLocalizedString(@"manmade", nil);
        } else if ([item isKindOfClass:[NSDictionary class]]) {
            NSDictionary *d = (NSDictionary *)item;
            return [NSString stringWithFormat:@"%@ %@", [d valueForKey:@"number"], [d valueForKey:@"name"]];
        }
        return nil;
    } else if ([[tableColumn identifier] isEqualToString:@"visible"]) {
        NSArray *selectedLayouts = [self.layouts selectedObjects];
        if ([selectedLayouts count] != 1) return @(NSOffState);
        
        Layout *selectedLayout = selectedLayouts[0];
        
        if ([item isKindOfClass:[NSDictionary class]]) {
            return @([selectedLayout symbolNumberIsVisible:[[(NSDictionary *)item valueForKey:@"number"] integerValue]]);
        }
        if ([item isKindOfClass:[NSArray class]]) {
            return @([selectedLayout allSymbolNumbersVisibleIn:(NSArray *)item]);
        }
    }
    
    return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if ([[tableColumn identifier] isEqualToString:@"visible"]) {
        NSArray *selectedLayouts = [self.layouts selectedObjects];
        if ([selectedLayouts count] != 1) return;
        
        Layout *selectedLayout = selectedLayouts[0];
        NSInteger state = [object integerValue]; BOOL refresh = NO;
        if (state == NSMixedState) {
            refresh = YES;
            state = NSOnState;
        }
        if ([item isKindOfClass:[NSDictionary class]]) {
            [selectedLayout modifySymbolNumber:[[item valueForKey:@"number"] integerValue] toBeVisible:(state != NSOffState)];
        } else if ([item isKindOfClass:[NSArray class]]) {
            [selectedLayout modifySymbolList:(NSArray *)item toBeVisible:(state != NSOffState)];
            refresh = YES;
        }
        if (refresh) [outlineView reloadItem:item reloadChildren:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:ASLayoutVisibleItemsChanged object:self.layouts.managedObjectContext];

    }

}




@end
