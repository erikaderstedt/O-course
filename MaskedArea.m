//
//  MaskedArea.m
//  O-course
//
//  Created by Erik Aderstedt on 2013-09-26.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import "MaskedArea.h"
#import "Layout.h"

#define HANDLE_SIZE 50.0

@implementation MaskedArea

@dynamic data;
@dynamic layout;

- (CGPoint)firstVertex {
    NSArray *array = [NSUnarchiver unarchiveObjectWithData:self.data];
    return [[array objectAtIndex:0] pointValue];
}

- (void)addVertex:(CGPoint)p {
    NSArray *array;
    if (self.data == nil) {
        array = @[];
    } else {
        array = [NSUnarchiver unarchiveObjectWithData:self.data];
    }
    array = [array arrayByAddingObject:[NSValue valueWithPoint:p]];
    self.data = [NSArchiver archivedDataWithRootObject:array];
}

- (CGPathRef)path {
    
    CGMutablePathRef path = CGPathCreateMutable();
    if (self.data == nil) return path;
    
    NSArray *array = [NSUnarchiver unarchiveObjectWithData:self.data];
    NSEnumerator *e = [array objectEnumerator];
    NSValue *v = [e nextObject];
    CGPoint p = [v pointValue];
    CGPathMoveToPoint(path, NULL, p.x, p.y);

    while ((v = [e nextObject]) != nil) {
        p = [v pointValue];
        CGPathAddLineToPoint(path, NULL, p.x, p.y);
    }
    return path;
}

- (CGPathRef)vertexPath {

    CGMutablePathRef path = CGPathCreateMutable();
    if (self.data == nil) return path;

    NSArray *array = [NSUnarchiver unarchiveObjectWithData:self.data];
    CGPoint p;

    for (NSValue *v in array) {
        p = [v pointValue];
        CGPathAddRect(path, NULL, CGRectMake(p.x-HANDLE_SIZE, p.y-HANDLE_SIZE, 2.0*HANDLE_SIZE, 2.0*HANDLE_SIZE));
    }
    return path;
}

- (NSArray *)vertices {
    if (self.data == nil) return @[];
    return [NSUnarchiver unarchiveObjectWithData:self.data];
}

@end
