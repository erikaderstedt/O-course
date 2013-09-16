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
#import "ASControlDescriptionView.h"

#define RESOLUTION (72.0/25.4)

@implementation ASMapPrintingView

- (id)initWithBaseView:(ASMapView *)_baseView
{
    CGSize psz = _baseView.paperSize;
    NSPrintingOrientation o = _baseView.orientation;
    NSRect r;
    if (o != NSLandscapeOrientation) {
        r = NSMakeRect(0.0, 0.0, psz.width, psz.height);
    } else {
        r = NSMakeRect(0.0, 0.0, psz.height, psz.width);
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
    
    if ([baseView controlDescriptionVisible]) {
        enum ASLayoutControlDescriptionLocation location = [baseView location];
        
        // Calculate the map frame in our own coordinate system.
        CGFloat scale = 1.0/(f2.size.width/[self frame].size.width);
        CGRect mapInOurCoordinates = CGRectApplyAffineTransform(f1, CGAffineTransformMakeScale(scale, scale));

        ASControlDescriptionView *cView = baseView.controlDescriptionView;
        NSRect r = [cView controlDescriptionBounds];
        CGFloat targetWidth = 7.0 * 8.0 * RESOLUTION;
        scale = targetWidth / r.size.width;
        NSAffineTransformStruct ats;
        ats.m11 = scale; ats.m22 = scale;
        ats.m21 = 0.0; ats.m12 = 0.0;
        
        CGPoint p1 = CGPointMake(0.0, 0.0), p2 = CGPointMake(0.0, 0.0);
        switch (location) {
            case kASControlDescriptionBottomLeft:
                p1 = CGPointMake(NSMinX(r),NSMinY(r));
                p2 = CGPointMake(NSMinX(mapInOurCoordinates), NSMinY(mapInOurCoordinates));
                break;
            case kASControlDescriptionBottomRight:
                p1 = CGPointMake(NSMaxX(r),NSMinY(r));
                p2 = CGPointMake(NSMaxX(mapInOurCoordinates), NSMinY(mapInOurCoordinates));
                break;
            case kASControlDescriptionTopLeft:
                p1 = CGPointMake(NSMinX(r),NSMaxY(r));
                p2 = CGPointMake(NSMinX(mapInOurCoordinates), NSMaxY(mapInOurCoordinates));
                break;
            case kASControlDescriptionTopRight:
                p1 = CGPointMake(NSMaxX(r),NSMaxY(r));
                p2 = CGPointMake(NSMaxX(mapInOurCoordinates), NSMaxY(mapInOurCoordinates));
                break;                
            default:
                break;
        }
        ats.tX = p2.x - p1.x*scale;
        ats.tY = p2.y - p1.y*scale;
        
        [NSGraphicsContext saveGraphicsState];
        NSAffineTransform *at3 = [NSAffineTransform transform];
        [at3 setTransformStruct:ats];
        [at3 concat];

        [[NSColor whiteColor] set];
        [NSBezierPath fillRect:NSInsetRect(r, -INSET_DIST, -INSET_DIST)];
        [cView drawActualControlDescription];
        [NSGraphicsContext restoreGraphicsState];
    }
}

@end
