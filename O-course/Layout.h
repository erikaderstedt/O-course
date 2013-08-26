//
//  Layout.h
//  O-course
//
//  Created by Erik Aderstedt on 2013-08-25.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


enum ASLayoutPaperSize {
    kASLayoutPaperSizeA4,
    kASLayoutPaperSizeA3
};

@class Course, Project;

@interface Layout : NSManagedObject

@property (nonatomic, retain) NSNumber * mapInset;
@property (nonatomic, retain) NSNumber * frameVisible;
@property (nonatomic, retain) id frameColor;
@property (nonatomic, retain) NSData * hiddenObjectTypes;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * paperSize;
@property (nonatomic, retain) NSNumber * scale;
@property (nonatomic, retain) NSSet *courses;
@property (nonatomic, retain) Project *project;

+ (instancetype)defaultLayoutInContext:(NSManagedObjectContext *)managedObjectContext;
- (NSString *)paperName;

@end

@interface Layout (CoreDataGeneratedAccessors)

- (void)addCoursesObject:(Course *)value;
- (void)removeCoursesObject:(Course *)value;
- (void)addCourses:(NSSet *)values;
- (void)removeCourses:(NSSet *)values;

@end
