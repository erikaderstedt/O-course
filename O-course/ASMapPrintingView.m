//
//  ASMapPrintingView.m
//  O-course
//
//  Created by Erik Aderstedt on 2013-09-09.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import "ASMapPrintingView.h"
#import "ASMapView.h"
#import "ASMapView+Layout.h"

#define RESOLUTION (72.0/25.4)

@implementation ASMapPrintingView

- (id)initWithBaseView:(ASMapView *)_baseView
{
    CGSize psz = _baseView.paperSize;
    NSPrintingOrientation o = _baseView.orientation;
    NSRect r;
    if (o != NSLandscapeOrientation) {
        r = NSMakeRect(0.0, 0.0, psz.width*RESOLUTION, psz.height*RESOLUTION);
    } else {
        r = NSMakeRect(0.0, 0.0, psz.height*RESOLUTION, psz.width * RESOLUTION);
    }
    r = NSIntegralRect(r);
    self = [super initWithFrame:r];
    if (self) {
        baseView = _baseView;
    }
    
    return self;
}

- (BOOL)knowsPageRange:(NSRangePointer)range {
    *range = NSMakeRange(1, 1);
    
    return YES;
}

- (NSRect)rectForPage:(NSInteger)page {
    return [self frame];
}

- (void)drawRect:(NSRect)dirtyRect {
    
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    
    // Set up an appropriate transform
    CGContextSaveGState(ctx);
    
    CGPoint p = [baseView centerOfMap];
    NSLog(@"Center of map %@", NSStringFromPoint(p));
    NSLog(@"This frame %@", NSStringFromRect([self frame]));
    CGAffineTransform at;
    CGFloat scale = [baseView printingScale];
    CGFloat mmAcross = [self frame].size.width/RESOLUTION;
    CGFloat mapPointsPerMm = 100.0; // At 15000
    CGFloat f = 1.0/(mmAcross * mapPointsPerMm * scale / 15000.0);
    f *= 100;
    at.a = f;
    at.b = 0.0;
    at.c = 0.0;
    at.d = f;
    at.tx = NSMidX([self frame]) - p.x*f;
    at.ty = NSMidY([self frame]) - p.y*f;
    
    p = CGPointApplyAffineTransform(p, at);
    NSLog(@"new point %@", NSStringFromPoint(p));
    
    CGContextConcatCTM(ctx, at);
    
    [baseView.mapProvider drawLayer:nil inContext:ctx];
    [baseView.overprintProvider drawLayer:nil inContext:ctx];
    /*
    if ([baseView frameVisible]) {
        [baseView drawPaperFrameInContext:ctx];
    }
    */
    CGContextRestoreGState(ctx);
}

@end
