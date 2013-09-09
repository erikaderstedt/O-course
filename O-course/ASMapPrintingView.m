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
    r.size.width = round(r.size.width);
    r.size.height = round(r.size.height);
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

- (NSString *)printJobTitle {
    return @"Test";
}

- (void)drawRect:(NSRect)dirtyRect {

    [NSBezierPath strokeLineFromPoint:NSMakePoint(0.0,0.0) toPoint:NSMakePoint(842.0, 595.0)];

    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    // Set up an appropriate transform

    CGPoint p = [baseView centerOfMap];
    CGFloat scale = [baseView printingScale];
    CGFloat mapPointsPerMm = 100.0; // At 15000
    CGFloat pointsAcross = [self frame].size.width;
    CGFloat mmAcross = pointsAcross/RESOLUTION;
    CGFloat desiredMapPointsAcross = scale/15000.0 * mmAcross * mapPointsPerMm;
    CGFloat f = pointsAcross/desiredMapPointsAcross;
    
    CGAffineTransform at;
    at.a = f;
    at.b = 0.0;
    at.c = 0.0;
    at.d = f;
    at.tx = NSMidX([self frame]) - p.x*f;
    at.ty = NSMidY([self frame]) - p.y*f;

    CGContextSaveGState(ctx);
    CGContextConcatCTM(ctx, at);
    [baseView.mapProvider drawLayer:nil inContext:ctx];
//    [baseView.overprintProvider drawLayer:nil inContext:ctx];
    /*
    if ([baseView frameVisible]) {
        [baseView drawPaperFrameInContext:ctx];
    }
    */
    CGContextRestoreGState(ctx);
    
}

@end
