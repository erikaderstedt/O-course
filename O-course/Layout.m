//
//  Layout.m
//  O-course
//
//  Created by Erik Aderstedt on 2013-08-25.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import "Layout.h"
#import "Course.h"
#import "Project.h"


@implementation Layout

@dynamic mapInset;
@dynamic frameVisible;
@dynamic frameColor;
@dynamic hiddenObjectTypes;
@dynamic name;
@dynamic paperSize;
@dynamic scale;
@dynamic courses;
@dynamic project;

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    self.frameColor = [NSColor colorWithDeviceRed:0.875 green:0.649 blue:0.223 alpha:1.000];
}

+ (instancetype)defaultLayoutInContext:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Layout"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name == %@", NSLocalizedString(@"layout.name.default", nil)]];
    [fetchRequest setFetchLimit:1];
    
    NSArray *objs = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if ([objs count] > 0) {
        return objs[0];
    }
    
    return nil;
}

- (NSString *)paperName {
    enum ASLayoutPaperSize sz = (enum ASLayoutPaperSize)[self.paperSize integerValue];
    if (sz == kASLayoutPaperSizeA3) return @"A3";
    return @"A4";
}

@end
