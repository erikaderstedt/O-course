//
//  ASMapViewDelegate.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-02.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "ASCourseObject.h"

@protocol ASBackgroundImageLoaderDelegate <NSObject>

- (NSWindow *)modalWindow;
- (void)addMapURL:(NSURL *)url filename:(NSString *)filename;
- (BOOL)isIgnoringFilename:(NSString *)path;
- (NSURL *)resolvedURLBookmarkForFilename:(NSString *)path;
- (void)ignoreFurtherRequestsForFile:(NSString *)file;

- (dispatch_semaphore_t)imageLoaderSequentializer;
- (dispatch_queue_t)imageLoaderQueue;

@end

@protocol ASOverprintProvider <NSObject>

- (CGRect)frameForOverprintObject:(id <ASOverprintObject>)object;
- (CGSize)frameSizeForOverprintObjectType:(enum ASOverprintObjectType)type;
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx;
- (void)updateOverprint;
- (void)hideOverprintObject:(id <ASOverprintObject>)courseObject informLayer:(CATiledLayer *)layer;
- (void)showOverprintObject:(id <ASOverprintObject>)courseObject informLayer:(CATiledLayer *)layer;

- (id <ASOverprintProvider>)layoutProxy;

- (CGPoint)suggestedCenterPosition;

@end

@protocol ASMapProvider <NSObject>

- (NSInteger)symbolNumberAtPosition:(CGPoint)p;
- (CGRect)mapBounds; // In native coordinates.
- (CGFloat)nativeScale;
- (void)loadOverprintObjects:(id (^)(CGFloat position_x, CGFloat position_y, enum ASOverprintObjectType otp, NSInteger controlCode, enum ASWhichOfAnySimilarFeature which, enum ASFeature feature, enum ASAppearance appearance,  enum ASDimensionsOrCombination dim, enum ASLocationOfTheControlFlag flag, enum ASOtherInformation other))objectHandler courses:(void (^)(NSString *name, NSArray *overprintObjects))courseHandler;
- (BOOL)hasCourseInformation;

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx;
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx useSecondaryTransform:(BOOL)useSecondaryTransform;

- (NSArray *)symbolList;

- (BOOL)supportsHiddenSymbolNumbers;
- (void)setHiddenSymbolNumbers:(const int32_t *)symbols count:(size_t)count;
- (const int32_t *)hiddenSymbolNumbers:(size_t *)count;

- (id <ASMapProvider>)layoutProxy;

@end
