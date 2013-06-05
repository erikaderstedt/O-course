//
//  ASOverprintController.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-14.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASOverprintController.h"
#import "CourseObject.h"
#import "ASOcourseDocument.h"

@implementation ASOverprintController

@synthesize course, document;

- (void)dealloc {
    [course release];
    [cacheArray release];
    [cachedCuts release];
    
    if (_overprintColor != NULL) CGColorRelease(_overprintColor);
    
    [super dealloc];
}

- (CGColorRef)overprintColor {
    if (_overprintColor == NULL) {
        CGFloat comps[5] = {0.0, 1.0, 0.0, 0.0, 1.0};
        CGColorSpaceRef cmyk = CGColorSpaceCreateDeviceCMYK();
        _overprintColor = CGColorCreate(cmyk, comps);
        CGColorSpaceRelease(cmyk);
    }
    return _overprintColor;
}

- (void)updateCache {
    [cacheArray release];
    
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:100];
    NSArray *courseObjects;
    
    if (course == nil) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"CourseObject"];
        courseObjects = [[self.document managedObjectContext] executeFetchRequest:request error:nil];
    } else {
        courseObjects = [self.course valueForKey:@"controls"];
    }
    
//    NSInteger controlNumber = 1;
    for (CourseObject *object in courseObjects) {

        [ma addObject:@{ @"position":[NSValue valueWithPoint:NSPointFromCGPoint(object.position)],
         @"type":[object valueForKey:@"type"]}];
    }
    cacheArray = [ma retain];
}

#pragma mark ASOverprintProvider

// This is called on several different background threads. It isn't practical to use different managed object context for this.
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {

    if (cacheArray == nil) return;
    
    NSArray *cacheCopy;
    @synchronized(self) {
        cacheCopy = [NSArray arrayWithArray:cacheArray];
    }
    
    // Draw the actual course.
    CGRect clipBox = CGContextGetClipBoundingBox(ctx);

    CGContextSetStrokeColorWithColor(ctx, [self overprintColor]);

    NSInteger controlNumber = 1;
    for (NSDictionary *courseObjectInfo in cacheCopy) {

        enum ASCourseObjectType type = (enum ASCourseObjectType)[[courseObjectInfo objectForKey:@"type"] integerValue];
        CGPoint p = NSPointToCGPoint([[courseObjectInfo objectForKey:@"position"] pointValue]);
        
        if (type == kASCourseObjectControl) {
            CGRect r = CGRectMake(p.x-300.0, p.y-300.0, 600.0, 600.0);
            if (CGRectIntersectsRect(CGRectInset(r, -50.0, -50.0), clipBox)) {
                CGContextBeginPath(ctx);
                CGContextAddEllipseInRect(ctx, r);
                CGContextSetLineWidth(ctx, 35.0);
                CGContextStrokePath(ctx);
            }
        }
    }
    
}

- (BOOL)addCourseObject:(enum ASCourseObjectType)objectType atLocation:(CGPoint)location symbolNumber:(NSInteger)symbolNumber {
    
    NSAssert([NSThread isMainThread], @"Not the main thread!");
    
    @synchronized(self) {
        CourseObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"CourseObject" inManagedObjectContext:[self.document managedObjectContext]];
        object.added = [NSDate date];
        [object setPosition:location];
        
        if (objectType == kASCourseObjectControl) {
            [object assignNextFreeControlCode];
        }
        
        [self updateCache];
    }
    
    return YES;
}

@end
