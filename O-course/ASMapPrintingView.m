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

- (CGAffineTransform)patternTransform {

    
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
    
    return at;
}

- (void)drawRect:(NSRect)dirtyRect {

    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGRect f1 = [baseView mapFrame];
    CGRect f2 = [baseView paperFrame];
    CGAffineTransform at = [self patternTransform];

    CGContextSaveGState(ctx);
    CGContextConcatCTM(ctx, at);

    CGContextBeginPath(ctx);
    CGRect n1 = CGRectApplyAffineTransform([self frame],CGAffineTransformInvert(at));
    n1.origin.x = CGRectGetMinX(n1) + CGRectGetWidth(n1)*CGRectGetMinX(f1)/CGRectGetWidth(f2);
    n1.origin.y = CGRectGetMinY(n1) + CGRectGetHeight(n1)*CGRectGetMinY(f1)/CGRectGetHeight(f2);
    n1.size.width = CGRectGetWidth(n1)*CGRectGetWidth(f1)/CGRectGetWidth(f2);
    n1.size.height = CGRectGetHeight(n1)*CGRectGetHeight(f1)/CGRectGetHeight(f2);
    
    n1 = CGRectIntegral(n1);
    CGFloat cRad = [baseView cornerRadius] * CGRectGetWidth(n1)/CGRectGetWidth(f2);
    CGPathRef roundClipRect = CGPathCreateRoundRect(n1 , cRad);
    CGContextAddPath(ctx, roundClipRect);
    CGContextClip(ctx);

    [self.mapProvider drawLayer:nil inContext:ctx useSecondaryTransform:YES];
    
    // Simulated overprint
    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
    [baseView.overprintProvider drawLayer:nil inContext:ctx];
    
    // The paper frame is drawn in the paperFrame coordinate space.
    CGContextRestoreGState(ctx);
    
    if ([baseView frameVisible]) {
        CGContextSaveGState(ctx);
        n1 = [self bounds];
        CGFloat scale = CGRectGetWidth(n1)/CGRectGetWidth(f2);
        at.a = scale;
        at.b = 0.0; at.c = 0.0;
        at.d = scale;
        at.tx = NSMidX(n1) - NSMidX(f2)*scale;
        at.ty = NSMidY(n1) - NSMidY(f2)*scale;
        
        CGContextConcatCTM(ctx, at);
        [baseView drawPaperFrameInContext:ctx];
        
        CGContextRestoreGState(ctx);
    }
    
}

@end
