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
    
    if (_overprintColor != NULL) CGColorRelease(_overprintColor);
    if (_transparentOverprintColor != NULL) CGColorRelease(_transparentOverprintColor);
    
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

- (CGColorRef)transparentOverprintColor {
    if (_transparentOverprintColor == NULL) {
        CGFloat comps[5] = {0.0, 1.0, 0.0, 0.0, 0.5};
        CGColorSpaceRef cmyk = CGColorSpaceCreateDeviceCMYK();
        _transparentOverprintColor = CGColorCreate(cmyk, comps);
        CGColorSpaceRelease(cmyk);
    }
    return _transparentOverprintColor;
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
        cacheArray = nil;
    }
    
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:100];

    //    NSInteger controlNumber = 1;
    drawConnectingLines = [self.dataSource specificCourseSelected];
    [self.dataSource enumerateCourseObjectsUsingBlock:^(id<ASCourseObject> object, BOOL inSelectedCourse) {
        [ma addObject:@{ @"position":[NSValue valueWithPoint:NSPointFromCGPoint(object.position)],
         @"type":@([object courseObjectType]), @"in_course":@(inSelectedCourse)}];
    }];
    
    @synchronized(self) {
        cacheArray = ma;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ASOverprintChanged" object:nil];
}

+ (CGFloat)angleBetweenCourseObjectInfos:(NSDictionary *)courseObjectInfo and:(NSDictionary *)secondCourseObjectInfo {
    CGFloat angle = 0.0;

    if (courseObjectInfo != nil || secondCourseObjectInfo != nil) {
        CGPoint p1 = NSPointToCGPoint([courseObjectInfo[@"position"] pointValue]);
        CGPoint p2 = NSPointToCGPoint([secondCourseObjectInfo[@"position"] pointValue]);
        angle = atan2( p2.y-p1.y,p2.x-p1.x);
    }
    return angle;
}

+ (CGFloat)angleBetweenStartAndFirstControlUsingCache:(NSArray *)cache {
    NSDictionary *start = nil, *firstControlAfter = nil;
    
    for (NSDictionary *courseObjectInfo in cache) {
        enum ASCourseObjectType type = (enum ASCourseObjectType)[courseObjectInfo[@"type"] integerValue];
        if (start == nil && type == kASCourseObjectStart && [courseObjectInfo[@"in_course"] boolValue]) {
            start = courseObjectInfo;
        }
        if (start != nil && type == kASCourseObjectControl && [courseObjectInfo[@"in_course"] boolValue]) {
            firstControlAfter = courseObjectInfo;
            break;
        }
    }
    return [self angleBetweenCourseObjectInfos:start and:firstControlAfter];
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
    CGFloat angle; // In radians.

//    NSInteger controlNumber = 1;
    NSDictionary *previousCourseObject = nil;
    
    for (NSDictionary *courseObjectInfo in cacheCopy) {

        enum ASCourseObjectType type = (enum ASCourseObjectType)[courseObjectInfo[@"type"] integerValue];
        CGPoint p = NSPointToCGPoint([courseObjectInfo[@"position"] pointValue]);
        BOOL inCourse = [courseObjectInfo[@"in_course"] boolValue];
        CGContextSetStrokeColorWithColor(ctx, (inCourse?[self overprintColor]:[self transparentOverprintColor]));
        
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
                if (drawConnectingLines && inCourse) {
                    angle = [[self class] angleBetweenStartAndFirstControlUsingCache:cacheCopy];
                } else {
                    angle = -M_PI/6.0;
                }
                z = 700.0/2.0/cos(M_PI/6);
                r = CGRectMake(p.x-400.0, p.y-400.0, 800.0, 800.0);
                if (CGRectIntersectsRect(r, clipBox)) {
                    CGContextBeginPath(ctx);
                    CGContextMoveToPoint(ctx, p.x + z*cos(angle), p.y + z*sin(angle));
                    angle += 2.0*M_PI/3.0; CGContextAddLineToPoint(ctx, p.x + z*cos(angle), p.y + z*sin(angle));
                    angle += 2.0*M_PI/3.0; CGContextAddLineToPoint(ctx, p.x + z*cos(angle), p.y + z*sin(angle));
                    
                    CGContextClosePath(ctx);
                    CGContextSetLineWidth(ctx, 35.0);
                    CGContextStrokePath(ctx);
                }
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
        
        if (drawConnectingLines && inCourse) {
            if (previousCourseObject) {
                enum ASCourseObjectType otype = (enum ASCourseObjectType)[previousCourseObject[@"type"] integerValue];
                angle = [[self class] angleBetweenCourseObjectInfos:previousCourseObject and:courseObjectInfo];
                CGFloat startSize = 0.5*((otype == kASCourseObjectControl)?600.0:(700.0/cos(M_PI/6)));
                CGFloat endSize = 0.5*((type == kASCourseObjectControl)?600.0:(700.0/cos(M_PI/6)));
                CGPoint op = NSPointToCGPoint([previousCourseObject[@"position"] pointValue]);
                CGPoint startPoint = CGPointMake(op.x + cos(angle)*startSize, op.y + sin(angle)*startSize);
                CGPoint endPoint = CGPointMake(p.x + cos(angle+M_PI)*endSize, p.y + sin(angle+M_PI)*endSize);
                CGContextBeginPath(ctx);
                CGContextMoveToPoint(ctx, startPoint.x, startPoint.y);
                CGContextAddLineToPoint(ctx, endPoint.x, endPoint.y);
                CGContextClosePath(ctx);
                CGContextSetLineWidth(ctx, 35.0);
                CGContextStrokePath(ctx);
            }
            previousCourseObject = courseObjectInfo;
        }

    }
    
}

@end
