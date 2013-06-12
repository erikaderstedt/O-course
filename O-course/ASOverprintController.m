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
#import "CoordinateTransverser.h"

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
    [self performSelectorOnMainThread:@selector(updateOverprint) withObject:nil waitUntilDone:NO];
}

- (void)updateOverprint {

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

- (void)updateCourseObject:(id <ASCourseObject>)courseObject withNewPosition:(CGPoint)p inLayer:(CATiledLayer *)layer {
    @synchronized(self) {
        NSMutableArray *ma = [NSMutableArray arrayWithArray:cacheArray];
        NSPoint p_orig = NSPointFromCGPoint([courseObject position]);
        __block NSUInteger modifyIndex = NSNotFound;
        [ma enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *d = (NSDictionary *)obj;
            NSPoint p_this = [[d objectForKey:@"position"] pointValue];
            if (p_orig.x == p_this.x && p_orig.y == p_this.y) {
                modifyIndex = idx;
                *stop = YES;
            }
        }];
        if (modifyIndex != NSNotFound) {
            [layer setNeedsDisplayInRect:[self frameForCourseObject:courseObject]];
            courseObject.position = p;
            [ma replaceObjectAtIndex:modifyIndex withObject:@{ @"position":[NSValue valueWithPoint:NSPointFromCGPoint(p)],
             @"type":@([courseObject courseObjectType]), @"in_course":[[ma objectAtIndex:modifyIndex] valueForKey:@"in_course"]}];
            [layer setNeedsDisplayInRect:[self frameForCourseObject:courseObject]];
            cacheArray = ma;
        }
    }
}

+ (CGFloat)angleBetweenCourseObjectInfos:(NSDictionary *)courseObjectInfo and:(NSDictionary *)secondCourseObjectInfo {
    CGFloat angle = 0.0;

    if (courseObjectInfo != nil || secondCourseObjectInfo != nil) {
        CGPoint p1 = NSPointToCGPoint([courseObjectInfo[@"position"] pointValue]);
        CGPoint p2 = NSPointToCGPoint([secondCourseObjectInfo[@"position"] pointValue]);
        angle = angle_between_points(p1, p2);
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

- (CGRect)frameForCourseObject:(id <ASCourseObject>)object {
    enum ASCourseObjectType type = [object courseObjectType];
    if (type == kASCourseObjectControl || type == kASCourseObjectFinish ||
        type == kASCourseObjectMandatoryCrossingPoint || type == kASCourseObjectMandatoryPassing) {
        CGSize sz = [self frameSizeForCourseObjectType:type];
        CGPoint p = [object position];
        return CGRectIntegral(CGRectMake(p.x - sz.width*0.5, p.y - sz.height*0.5, sz.width, sz.height));
    }
    
    NSAssert(NO, @"Unsupported course object type.");
    return CGRectZero;
}

- (CGSize)frameSizeForCourseObjectType:(enum ASCourseObjectType)type {
    if (type == kASCourseObjectStart) {
        return CGSizeMake(700.0/cos(M_PI/6), 700.0/cos(M_PI/6));
    }
    return CGSizeMake(600.0, 600.0);
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
                CGPoint startPoint = translatePoint(NSPointToCGPoint([previousCourseObject[@"position"] pointValue]),
                                                    0.5*((otype == kASCourseObjectControl)?600.0:(700.0/cos(M_PI/6))),
                                                    angle);
                CGPoint endPoint = translatePoint(p,
                                                  0.5*((type == kASCourseObjectControl)?600.0:(700.0/cos(M_PI/6))),
                                                  angle+M_PI);
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
