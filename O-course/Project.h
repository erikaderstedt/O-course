//
//  Project.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-09-23.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface Project : NSManagedObject
@property(nonatomic,strong) NSData *mapBookmark;

+ (Project *)projectInManagedObjectContext:(NSManagedObjectContext *)moc;

- (BOOL)setMapURL:(NSURL *)url error:(NSError **)error;
- (NSURL *)mapURL;

@end
