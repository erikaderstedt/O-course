//
//  Project.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-09-23.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface Project : NSManagedObject
@property(nonatomic,retain) NSData *mapBookmark;

+ (Project *)projectInManagedObjectContext:(NSManagedObjectContext *)moc;

@end
