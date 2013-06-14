//
//  Course.m
//  O-course
//
//  Created by Erik Aderstedt on 2013-06-05.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import "Course.h"
#import "OverprintObject.h"

@implementation Course

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    [self setPrimitiveValue:NSLocalizedString(@"New course", nil) forKey:@"name"];
}

- (void)appendOverprintObject:(OverprintObject *)object {
    [self insertOverprintObject:object atPosition:[[self valueForKey:@"courseObjects"] count]];
}

- (void)insertOverprintObject:(OverprintObject *)object atPosition:(NSUInteger)position {
    NSManagedObject *courseObject = [NSEntityDescription insertNewObjectForEntityForName:@"CourseObject" inManagedObjectContext:self.managedObjectContext];
    
    [courseObject setValue:object forKey:@"overprintObject"];
    [(NSMutableOrderedSet *)[self valueForKey:@"courseObjects"] insertObject:courseObject atIndex:position];
}

@end
