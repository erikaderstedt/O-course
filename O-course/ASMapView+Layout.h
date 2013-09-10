//
//  ASMapView+Layout.h
//  O-course
//
//  Created by Erik Aderstedt on 2013-08-30.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import "ASMapView.h"

#define LAYOUT_VIEW_WIDTH 273.0

@interface ASMapView (Layout)

- (CALayer *)printedMapLayer;
- (void)adjustPrintedMapLayerForBounds;
- (CIFilter *)backgroundMapFilter;
- (void)drawPaperFrameInContext:(CGContextRef)ctx;

- (void)dragPaperMapBasedOnEvent:(NSEvent *)event;
- (void)layoutChanged:(NSNotification *)notification;
- (void)visibleSymbolsChanged:(NSNotification *)notification;
- (void)printingScaleChanged:(NSNotification *)notification;
- (void)orientationChanged:(NSNotification *)notification;
- (void)frameColorChanged:(NSNotification *)notification;
- (void)layoutFrameChanged:(NSNotification *)notification;
- (void)decorChanged:(NSNotification *)notification;

- (void)setupLayoutNotificationObserving;
- (void)teardownLayoutNotificationObserving;
- (void)updatePaperMapButMaintainPositionWhileDoing:(void (^)(void))block animate:(BOOL)animate;
- (CGPoint)centerOfMap;
- (void)centerMapOnCoordinates:(CGPoint)p;
- (void)synchronizePaperWithBackground;
- (void)recordNewLayoutCenter;
- (void)handleScaleAndOrientation;

- (CGFloat)printingScale;

- (CGRect)mapFrame;
- (CGRect)paperFrame;
- (CGFloat)cornerRadius;

@end

CGPathRef CGPathCreateRoundRect( const CGRect r, const CGFloat cornerRadius);