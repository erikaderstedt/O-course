//
//  BackgroundMaps.m
//  O-course
//
//  Created by Erik Aderstedt on 2013-09-25.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import "BackgroundMap.h"
#import "Project.h"


@implementation BackgroundMap

@dynamic bookmark;
@dynamic filename;
@dynamic ignored;
@dynamic project;

- (NSURL *)resolvedURL {
    NSURL *u = [NSURL URLByResolvingBookmarkData:self.bookmark
                                         options:NSURLBookmarkResolutionWithSecurityScope
                                   relativeToURL:nil
                             bookmarkDataIsStale:NULL
                                           error:nil];
    return u;
}

- (void)setURL:(NSURL *)url {
    NSData *bookmarkData = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                         includingResourceValuesForKeys:nil
                                          relativeToURL:nil
                                                  error:nil];
    self.bookmark = bookmarkData;
}

+ (BackgroundMap *)topInManagedObjectContext:(NSManagedObjectContext *)moc {
    NSFetchRequest *f = [NSFetchRequest fetchRequestWithEntityName:@"BackgroundMap"];
    [f setPredicate:[NSPredicate predicateWithFormat:@"filename == nil"]];
    NSArray *a = [moc executeFetchRequest:f error:nil];
    if ([a count]) return a[0];
    return nil;
}

@end
