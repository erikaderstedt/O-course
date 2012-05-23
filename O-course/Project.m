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


+ (Project *)projectInManagedObjectContext:(NSManagedObjectContext *)moc {
    NSFetchRequest *r = [[[moc persistentStoreCoordinator] managedObjectModel] fetchRequestTemplateForName:@"THE_PROJECT"];
    
    NSArray *projects = [moc executeFetchRequest:r error:nil];
    if ([projects count] == 0) {
        NSLog(@"WTF?");
        return nil;
    }
    return [projects objectAtIndex:0];
}

@end
