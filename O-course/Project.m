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

- (BOOL)addMapURL:(NSURL *)url error:(NSError **)error {
    
    NSData *bookmarkData = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                       includingResourceValuesForKeys:nil
                                        relativeToURL:nil
                                                error:error];
    if (bookmarkData == nil) {
        NSLog(@"Could not add map %@. Error: %@", url, *error);
        return NO;
    }
    
    NSMutableArray *x;
    if (self.mapBookmark == nil) {
        x = [NSMutableArray arrayWithCapacity:4];
    } else {
        x = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:self.mapBookmark]];
    }
    [x addObject:bookmarkData];
    self.mapBookmark = [NSKeyedArchiver archivedDataWithRootObject:x];
    
    return YES;
}

- (NSArray *)mapURLs {
    if (self.mapBookmark == nil) return @[];
    
    NSMutableArray *x = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:self.mapBookmark]];
    NSMutableArray *y = [NSMutableArray arrayWithCapacity:[x count]];
    
    for (NSData *bookmark in x) {
        NSError *error = nil;
        NSURL *u = [NSURL URLByResolvingBookmarkData:bookmark options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:NULL error:&error];
        if (u == nil) {
            NSLog(@"Error: %@. Data %@.", error, bookmark);
        } else {
            [y addObject:u];
        }
    }
    
    return y;
}

- (void)clearMapURLs {
    self.mapBookmark = nil;
}

- (CGPoint)centerPosition {
    return CGPointMake([[self valueForKey:@"position_x"] doubleValue], [[self valueForKey:@"position_y"] doubleValue]);
}

- (void)setCenterPosition:(CGPoint)p {
    [self setValue:@(p.x) forKey:@"position_x"];
    [self setValue:@(p.y) forKey:@"position_y"];
}

@end
