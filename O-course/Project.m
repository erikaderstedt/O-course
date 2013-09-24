//
//  Project.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-09-23.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "Project.h"

@implementation Project

@dynamic mapBookmark;

+ (instancetype)projectInManagedObjectContext:(NSManagedObjectContext *)moc {
    if (moc == nil) return nil;
    
    NSFetchRequest *r = [[[moc persistentStoreCoordinator] managedObjectModel] fetchRequestTemplateForName:@"THE_PROJECT"];
    NSArray *projects = [moc executeFetchRequest:r error:nil];
    
    if ([projects count] != 1) {
        return nil;
    }
    return projects[0];
}

- (CGPoint)centerPosition {
    return CGPointMake([[self valueForKey:@"position_x"] doubleValue], [[self valueForKey:@"position_y"] doubleValue]);
}

- (void)setCenterPosition:(CGPoint)p {
    [self setValue:@(p.x) forKey:@"position_x"];
    [self setValue:@(p.y) forKey:@"position_y"];
}

@end
