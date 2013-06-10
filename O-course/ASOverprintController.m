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

@synthesize document;

- (void)dealloc {
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

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(courseChanged:) name:@"ASCourseChanged" object:[self.document managedObjectContext]];
}

- (void)courseChanged:(NSNotification *)n {
    [self performSelectorOnMainThread:@selector(updateCache) withObject:nil waitUntilDone:NO];
}

- (void)updateCache {
    NSAssert([NSThread isMainThread], @"Not the main thread.");
    @synchronized(self) {
        [cacheArray release];
        cacheArray = nil;
    }
    
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:100];

    //    NSInteger controlNumber = 1;
    drawConnectingLines = ![self.courseProvider allObjectsSelected];
    for (CourseObject *object in [self.courseProvider courseObjectEnumerator]) {

        [ma addObject:@{ @"position":[NSValue valueWithPoint:NSPointFromCGPoint(object.position)],
         @"type":[object valueForKey:@"type"]}];
    }
    @synchronized(self) {
        cacheArray = [ma retain];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ASOverprintChanged" object:nil];
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
        CGRect r;
        CGFloat z;
        
        switch (type) {
            case kASCourseObjectControl:
                r = CGRectMake(p.x-300.0, p.y-300.0, 600.0, 600.0);
                if (CGRectIntersectsRect(CGRectInset(r, -50.0, -50.0), clipBox)) {
                    CGContextBeginPath(ctx);
                    CGContextAddEllipseInRect(ctx, r);
                    CGContextSetLineWidth(ctx, 35.0);
                    CGContextStrokePath(ctx);
                }
                break;
            case kASCourseObjectStart:
                z = 700.0/2.0/cos(pi/6);
                r = CGRectMake(p.x-400.0, p.y-400.0, 800.0, 800.0);
                CGContextBeginPath(ctx);
                CGContextMoveToPoint(ctx, p.x, p.y + z);
                CGContextAddLineToPoint(ctx, p.x + cos(pi/6)*z, p.y - sin(pi/6)*z);
                CGContextAddLineToPoint(ctx, p.x - cos(pi/6)*z, p.y - sin(pi/6)*z);
                CGContextClosePath(ctx);
                CGContextSetLineWidth(ctx, 35.0);
                CGContextStrokePath(ctx);
                break;
            case kASCourseObjectFinish:
                r = CGRectMake(p.x-350.0, p.y-350.0, 700.0, 700.0);
                if (CGRectIntersectsRect(CGRectInset(r, -50.0, -50.0), clipBox)) {
                    CGContextBeginPath(ctx);
                    CGContextSetLineWidth(ctx, 35.0);
                    CGContextAddEllipseInRect(ctx, r);
                    r = CGRectMake(p.x-250.0, p.y-250.0, 500.0, 500.0);
                    CGContextAddEllipseInRect(ctx, r);
                    CGContextStrokePath(ctx);
                    
                }
                break;
            default:
                break;
        }

    }
    
}

@end
