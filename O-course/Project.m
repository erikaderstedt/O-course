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

- (BOOL)setMapURL:(NSURL *)url error:(NSError **)error {
    
    NSData *bookmarkData = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                       includingResourceValuesForKeys:nil
                                        relativeToURL:nil
                                                error:error];
    if (bookmarkData == nil) {
        NSLog(@"Could not set map %@. Error: %@", url, *error);
        self.mapBookmark = nil;
        return NO;
    }
    
    self.mapBookmark = bookmarkData;
    return YES;
}

- (NSURL *)mapURL {
    if (self.mapBookmark == nil) return nil;
    
    NSError *error = nil;
    NSURL *u = [NSURL URLByResolvingBookmarkData:self.mapBookmark options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:NULL error:&error];
    if (u == nil) {
        NSLog(@"Error: %@. Data %@.", error, self.mapBookmark);
    }
    
    return u;
}

- (CGPoint)centerPosition {
    return CGPointMake([[self valueForKey:@"position_x"] doubleValue], [[self valueForKey:@"position_y"] doubleValue]);
}

- (void)setCenterPosition:(CGPoint)p {
    [self setValue:@(p.x) forKey:@"position_x"];
    [self setValue:@(p.y) forKey:@"position_y"];
}

@end
