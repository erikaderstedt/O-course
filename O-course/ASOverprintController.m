//
//  ASOverprintController.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-14.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASOverprintController.h"
#import "OverprintObject.h"
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

- (void)teardown {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ASCourseChanged" object:[self.document managedObjectContext]];
}

- (void)courseChanged:(NSNotification *)n {
    [self performSelectorOnMainThread:@selector(updateOverprint) withObject:nil waitUntilDone:NO];
}

- (void)updateOverprint {

    NSAssert([NSThread isMainThread], @"Not the main thread.");
    @synchronized(self) {
        self.cacheArray = nil;
    }
    
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:100];

    //    NSInteger controlNumber = 1;
    drawConnectingLines = [self.dataSource specificCourseSelected];
    NSMutableArray *drawnObjects = [NSMutableArray arrayWithCapacity:100];
    [self.dataSource enumerateOverprintObjectsInSelectedCourseUsingBlock:^(id<ASOverprintObject> object, NSInteger index) {
        
        [ma addObject:@{
         @"position":[NSValue valueWithPoint:NSPointFromCGPoint(object.position)],
         @"type":@([object objectType]),
         @"in_course":@(YES),
         @"hidden":@NO,
         @"draw":@(![drawnObjects containsObject:object])}];
        [drawnObjects addObject:object];
    }];
    BOOL singleCourse = [self.dataSource specificCourseSelected];
    [self.dataSource enumerateOtherOverprintObjectsUsingBlock:^(id<ASOverprintObject> object) {
        [ma addObject:@{
         @"position":[NSValue valueWithPoint:NSPointFromCGPoint(object.position)],
         @"type":@([object objectType]),
         @"in_course":@(singleCourse?NO:YES),
         @"hidden":@NO,
         @"draw":@(YES)}];
    }];
    
    @synchronized(self) {
        self.cacheArray = ma;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ASOverprintChanged" object:nil];
}

- (void)updateOverprintObject:(id <ASOverprintObject>)courseObject withNewPosition:(CGPoint)p inLayer:(CATiledLayer *)layer {
    @synchronized(self) {
        NSMutableArray *ma = [NSMutableArray arrayWithArray:self.cacheArray];
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
            [layer setNeedsDisplayInRect:[self frameForOverprintObject:courseObject]];
            courseObject.position = p;
            [ma replaceObjectAtIndex:modifyIndex withObject:@{ @"position":[NSValue valueWithPoint:NSPointFromCGPoint(p)],
             @"type":@([courseObject objectType]), @"in_course":[[ma objectAtIndex:modifyIndex] valueForKey:@"in_course"], @"hidden":[[ma objectAtIndex:modifyIndex] valueForKey:@"hidden"]}];
            [layer setNeedsDisplayInRect:[self frameForOverprintObject:courseObject]];
            self.cacheArray = ma;
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
        enum ASOverprintObjectType type = (enum ASOverprintObjectType)[courseObjectInfo[@"type"] integerValue];
        if (start == nil && type == kASOverprintObjectStart && [courseObjectInfo[@"in_course"] boolValue]) {
            start = courseObjectInfo;
        }
        if (start != nil && type == kASOverprintObjectControl && [courseObjectInfo[@"in_course"] boolValue]) {
            firstControlAfter = courseObjectInfo;
            break;
        }
    }
    return [self angleBetweenCourseObjectInfos:start and:firstControlAfter];
}

- (CGRect)frameForOverprintObject:(id <ASOverprintObject>)object {
    enum ASOverprintObjectType type = [object objectType];
    if (type == kASOverprintObjectControl || type == kASOverprintObjectFinish ||
        type == kASOverprintObjectMandatoryCrossingPoint || type == kASOverprintObjectMandatoryPassing || type == kASOverprintObjectStart) {
        CGSize sz = [self frameSizeForOverprintObjectType:type];
        CGPoint p = [object position];
        return CGRectIntegral(CGRectMake(p.x - sz.width*0.5, p.y - sz.height*0.5, sz.width, sz.height));
    }
    
    NSAssert(NO, @"Unsupported course object type.");
    return CGRectZero;
}

- (CGSize)frameSizeForOverprintObjectType:(enum ASOverprintObjectType)type {
    if (type == kASOverprintObjectStart) {
        return CGSizeMake(700.0/cos(M_PI/6), 700.0/cos(M_PI/6));
    }
    return CGSizeMake(600.0, 600.0);
}

- (void)alterCourseObject:(id<ASOverprintObject>)courseObject informLayer:(CATiledLayer *)layer hidden:(BOOL)hide {
    @synchronized(self) {
        NSMutableArray *ma = [NSMutableArray arrayWithArray:self.cacheArray];
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
            NSMutableDictionary *values = [NSMutableDictionary dictionaryWithDictionary:[ma objectAtIndex:modifyIndex]];
            [values setObject:@(hide) forKey:@"hidden"];
            [ma replaceObjectAtIndex:modifyIndex withObject:values];
            [layer setNeedsDisplayInRect:[layer bounds]];
            self.cacheArray = ma;
        }
    }
}

- (void)showOverprintObject:(id<ASOverprintObject>)courseObject informLayer:(CATiledLayer *)layer {
    [self alterCourseObject:courseObject informLayer:layer hidden:NO];
}

- (void)hideOverprintObject:(id<ASOverprintObject>)courseObject informLayer:(CATiledLayer *)layer {
    [self alterCourseObject:courseObject informLayer:layer hidden:YES];
}

#pragma mark ASOverprintProvider

// This is called on several different background threads. It isn't practical to use different managed object context for this.
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {

    if (self.cacheArray == nil) return;
    
    NSArray *cacheCopy;
    @synchronized(self) {
        cacheCopy = [NSArray arrayWithArray:self.cacheArray];
    }
    
    // Draw the actual course.
    CGRect clipBox = CGContextGetClipBoundingBox(ctx);
    CGFloat angle; // In radians.

//    NSInteger controlNumber = 1;
    NSDictionary *previousCourseObject = nil;
    
    for (NSDictionary *courseObjectInfo in cacheCopy) {
        
        enum ASOverprintObjectType type = (enum ASOverprintObjectType)[courseObjectInfo[@"type"] integerValue];
        CGPoint p = NSPointToCGPoint([courseObjectInfo[@"position"] pointValue]);
        BOOL inCourse = [courseObjectInfo[@"in_course"] boolValue];
        CGContextSetStrokeColorWithColor(ctx, (inCourse?[self overprintColor]:[self transparentOverprintColor]));
        
        CGRect r;
        CGFloat z;
        if ([[courseObjectInfo objectForKey:@"hidden"] boolValue] == NO &&
            [[courseObjectInfo objectForKey:@"draw"] boolValue] == YES) {
            switch (type) {
                case kASOverprintObjectControl:
                    r = CGRectMake(p.x-300.0, p.y-300.0, 600.0, 600.0);
                    if (CGRectIntersectsRect(CGRectInset(r, -50.0, -50.0), clipBox)) {
                        CGContextBeginPath(ctx);
                        CGContextAddEllipseInRect(ctx, r);
                        CGContextSetLineWidth(ctx, 35.0);
                        CGContextStrokePath(ctx);
                    }
                    break;
                case kASOverprintObjectStart:
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
                case kASOverprintObjectFinish:
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
        
        if (drawConnectingLines && inCourse) {
            if (previousCourseObject && (![courseObjectInfo[@"hidden"] boolValue] && ![previousCourseObject[@"hidden"] boolValue])) {
                enum ASOverprintObjectType otype = (enum ASOverprintObjectType)[previousCourseObject[@"type"] integerValue];
                angle = [[self class] angleBetweenCourseObjectInfos:previousCourseObject and:courseObjectInfo];
                CGPoint startPoint = translatePoint(NSPointToCGPoint([previousCourseObject[@"position"] pointValue]),
                                                    0.5*((otype == kASOverprintObjectControl)?600.0:(700.0/cos(M_PI/6))),
                                                    angle);
                CGPoint endPoint = translatePoint(p,
                                                  0.5*((type == kASOverprintObjectControl)?600.0:(700.0/cos(M_PI/6))),
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
