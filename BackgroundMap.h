//
//  BackgroundMaps.h
//  O-course
//
//  Created by Erik Aderstedt on 2013-09-25.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Project;

@interface BackgroundMap : NSManagedObject

@property (nonatomic, retain) NSData * bookmark;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic) BOOL ignored;
@property (nonatomic, retain) Project *project;

- (NSURL *)resolvedURL;
- (void)setURL:(NSURL *)url;
+ (BackgroundMap *)topInManagedObjectContext:(NSManagedObjectContext *)moc;

@end
