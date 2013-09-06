//
//  ASMapView+Layout.m
//  O-course
//
//  Created by Erik Aderstedt on 2013-08-30.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import "ASMapView+Layout.h"
#import "ASLayoutController.h"

#define DEFAULT_PRINTING_SCALE 10000.0
#define FRAME_INSET 10.0
#define FRAME_CORNER_RADIUS 12.0
#define FRAME_WIDTH 6.0


CGPathRef CGPathCreateRoundRect( const CGRect r, const CGFloat cornerRadius )
{
	CGMutablePathRef p = CGPathCreateMutable() ;
	
	CGPathMoveToPoint( p, NULL, r.origin.x + cornerRadius, r.origin.y ) ;
	
	CGFloat maxX = CGRectGetMaxX( r ) ;
	CGFloat maxY = CGRectGetMaxY( r ) ;
	
	CGPathAddArcToPoint( p, NULL, maxX, r.origin.y, maxX, r.origin.y + cornerRadius, cornerRadius ) ;
	CGPathAddArcToPoint( p, NULL, maxX, maxY, maxX - cornerRadius, maxY, cornerRadius ) ;
	
	CGPathAddArcToPoint( p, NULL, r.origin.x, maxY, r.origin.x, maxY - cornerRadius, cornerRadius ) ;
	CGPathAddArcToPoint( p, NULL, r.origin.x, r.origin.y, r.origin.x + cornerRadius, r.origin.y, cornerRadius ) ;
	
	return p ;
}

@implementation ASMapView (Layout)

#pragma mark -
#pragma mark Printed map layer

- (CALayer *)printedMapLayer {
    if (_printedMapLayer == nil) {
        // The map layer consists of
        // 1. A custom layer with a white background and a drop shadow
        //    This layer is placed in [self layer]
        // 2. A local map CATiledLayer, placed within the custom layer.
        _printedMapLayer = [CALayer layer];
        CGColorRef white = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
        CGColorRef black = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
        _printedMapLayer.backgroundColor = white;
        _printedMapLayer.shadowColor = black;
        _printedMapLayer.shadowOpacity = 0.6;
        _printedMapLayer.shadowOffset = CGSizeMake(8.0, -8.0);
        _printedMapLayer.shadowRadius = 8.0;
        _printedMapLayer.hidden = YES;
        _printedMapLayer.name = @"paper";
        _printedMapLayer.delegate = self;
        _printedMapLayer.anchorPoint = CGPointMake(0.5,0.5);
        
        _printedMapScrollLayer = [CAScrollLayer layer];
        _printedMapScrollLayer.anchorPoint = CGPointMake(0.5,0.5);
        _printedMapScrollLayer.name = @"mapScroller";
        _printedMapScrollLayer.backgroundColor = white;
        [_printedMapLayer addSublayer:_printedMapScrollLayer];
        
        _innerMapLayer = [CATiledLayer layer];
        _innerMapLayer.name = @"innerMap";
        _innerMapLayer.needsDisplayOnBoundsChange = YES;
        _innerMapLayer.backgroundColor = white;
        _innerMapLayer.tileSize = tiledLayer.tileSize;
        _innerMapLayer.levelsOfDetail = tiledLayer.levelsOfDetail;
        _innerMapLayer.levelsOfDetailBias = tiledLayer.levelsOfDetailBias;
        _innerMapLayer.position = tiledLayer.position;
        _innerMapLayer.anchorPoint = tiledLayer.anchorPoint;
        _innerMapLayer.bounds = [self.mapProvider mapBounds];
        _innerMapLayer.delegate = self;
        
        _innerOverprintLayer = [CATiledLayer layer];
        _innerOverprintLayer.name = @"innerOverprint";
        _innerOverprintLayer.needsDisplayOnBoundsChange = YES;
        _innerOverprintLayer.tileSize = tiledLayer.tileSize;
        _innerOverprintLayer.levelsOfDetail = tiledLayer.levelsOfDetail;
        _innerOverprintLayer.levelsOfDetailBias = tiledLayer.levelsOfDetailBias;
        _innerOverprintLayer.bounds = _innerMapLayer.bounds;
        _innerOverprintLayer.anchorPoint = _innerMapLayer.anchorPoint;
        _innerOverprintLayer.position = _innerMapLayer.position;
        _innerOverprintLayer.delegate = self.overprintProvider;
        /*
         CIFilter *mulBlend = [CIFilter filterWithName:@"CIMultiplyCompositing"];
         _innerOverprintLayer.compositingFilter = mulBlend;
         */
        CGColorRelease(white);
        CGColorRelease(black);
        
        [_printedMapScrollLayer addSublayer:_innerMapLayer];
        [_printedMapScrollLayer addSublayer:_innerOverprintLayer];
        
        [_innerMapLayer addObserver:self forKeyPath:@"transform" options:0 context:(__bridge void *)(_innerMapLayer)];
        
    }
    return _printedMapLayer;
}

- (void)drawPaperFrameInContext:(CGContextRef)ctx {
    CGContextBeginPath(ctx);
    CGRect r = CGRectInset(_printedMapScrollLayer.frame, -FRAME_INSET,- FRAME_INSET);
    
    CGPathRef p = CGPathCreateRoundRect(r, 12.0);
    CGContextAddPath(ctx, p);
    CGPathRelease(p);
    CGContextSetStrokeColorWithColor(ctx, frameColor);
    CGContextSetLineWidth(ctx, 4.0);
    
    CGContextStrokePath(ctx);
}

- (CIFilter *)backgroundMapFilter {
    if (_backgroundMapFilter == nil) {
        _backgroundMapFilter = [CIFilter filterWithName:@"CIColorControls"];
        [_backgroundMapFilter setDefaults];
        _backgroundMapFilter.name = @"skuggkarta";
        /*        [_backgroundMapFilter setValue:@(0.2) forKey:@"inputSaturation"];
         [_backgroundMapFilter setValue:@(-0.32) forKey:@"inputBrightness"];
         [_backgroundMapFilter setValue:@(0.62) forKey:@"inputContrast"];
         */    }
    return _backgroundMapFilter;
}

- (void)adjustPrintedMapLayerForBounds {
    NSAssert(_printedMapLayer != nil, @"No printed map layer!");
    
    // Set the outer bounds. These are determined
    CGRect r = [[[self enclosingScrollView] superview] bounds], page;
    r.size.width -= LAYOUT_VIEW_WIDTH;
    CGFloat a4ratio = paperSize.height/paperSize.width;
    CGFloat fraction = 0.8;
    if (orientation == NSLandscapeOrientation) {
        if (r.size.width / r.size.height > a4ratio) {
            // There will be extra space to the left and right.
            page.size.height = fraction*r.size.height;
            page.size.width = a4ratio*page.size.height;
        } else {
            // There will be extra space top and bottom.
            page.size.width = fraction*r.size.width;
            page.size.height = page.size.width/a4ratio;
        }
    } else {
        if (r.size.height / r.size.width < a4ratio) {
            // There will be extra space to the left and right.
            page.size.height = fraction*r.size.height;
            page.size.width = page.size.height/a4ratio;
        } else {
            // There will be extra space top and bottom.
            page.size.width = fraction*r.size.width;
            page.size.height = a4ratio * page.size.width;
        }
    }
    page.origin.x = 0.5*(r.size.width - page.size.width);
    page.origin.y = 0.5*(r.size.height - page.size.height);
    page = CGRectIntegral(page);
    page.origin.x += paperOffset.width;
    page.origin.y += paperOffset.height;
    [_printedMapLayer setFrame:page];
    [_printedMapLayer setPosition:CGPointMake(CGRectGetMidX(r), CGRectGetMidY(r))];
    
    r = _printedMapLayer.bounds;
    if (orientation == NSLandscapeOrientation) {
        // The landscape version is rotated counter-clockwise.
        r.size.height -= leftMargin + rightMargin;
        r.size.width -= topMargin + bottomMargin;
        r.origin.x += topMargin;
        r.origin.y += leftMargin;
    } else {
        r.size.width -= leftMargin + rightMargin;
        r.size.height -= topMargin + bottomMargin;
        r.origin.x += leftMargin;
        r.origin.y += bottomMargin;
    }
    if (frameColor != NULL) {
        r = CGRectInset(r, FRAME_INSET, FRAME_INSET);
    }
    [_printedMapScrollLayer setFrame:r];
}

- (void)setPrintingScale:(CGFloat)printingScale {
    /* First check that we're on screen. */
    CGFloat visibleWidth = _printedMapScrollLayer.visibleRect.size.width;
    if (visibleWidth == 0.0) return;
    NSLog(@"old visible width: %f", visibleWidth);

    /*
     * We want to 1) set the frame of the inner map layers
     * and 2) set the transform of those layers so that just the right
     * amount of map (and at the correct location) is drawn within the map
     * layer.
     * The frame has to be set after the transform is calculated.
     */
    _printingScale = printingScale;
    if (_printingScale == 0.0) {
        NSLog(@"Yikes! Bad scale!");
        _printingScale = 5000.0;
    }

    // Calculate the number of map points that fit in the paper width.
    //
    CGFloat pointsInWidth = ((orientation == NSLandscapeOrientation)?paperSize.height:paperSize.width) * 100.0 * printingScale / 15000.0;
    // Kastellegården har 38000 pts in x. 380 mm i 15000-del. Låter mycket men kartan har mycket extra så det kan nog stämma.
    // 297 mm * 100 = 297000 * 10000/15000
    // visibleWidth is the number of points that are visible with the current transform.
    // We then adjust the zoom by the quotient visibleWidth/pointsInWidth.
    // If more are visible than we should have, the zoom is increased.
    NSLog(@"about to set the zoom to %f", _zoom*visibleWidth/pointsInWidth);
    [self setPrimitiveZoom:_zoom*visibleWidth/pointsInWidth];
    visibleWidth = _printedMapScrollLayer.visibleRect.size.width;
    NSLog(@"new visible width: %f", visibleWidth);
}

- (CGFloat)printingScale {
    if (_printingScale == 0.0) return DEFAULT_PRINTING_SCALE;
    return _printingScale;
}

- (void)dragPaperMapBasedOnEvent:(NSEvent *)event {
    CGFloat dX, dY;
    dX = round([event deltaX]);
    dY = -round([event deltaY]);
    paperOffset.width += dX;
    paperOffset.height += dY;
    
    CGRect r = _printedMapLayer.frame;
    r.origin.x += dX;
    r.origin.y += dY;
    [_printedMapLayer setFrame:r];
}

#pragma mark Responding to layout change notifications

- (void)recordNewLayoutCenter {
    CGRect visibleRect = [_innerMapLayer visibleRect];
    CGPoint newCenterPosition = CGPointMake(CGRectGetMidX(visibleRect), CGRectGetMidY(visibleRect));
    NSLog(@"Storing new center: %@", NSStringFromPoint(newCenterPosition));
    [self.layoutController writeLayoutCenterPosition:newCenterPosition];
}

- (void)layoutChanged:(NSNotification *)n {
    NSLog(@"layout changes");
    // Perform the same actions as when showing the printed map.
    [self setPrintingScale:(CGFloat)[self.layoutController scale]];
    
    [self centerMapOnCoordinates:[self.layoutController layoutCenterPosition]];
    [self synchronizePaperWithBackground];
    
    /*
    [self recordNewLayoutCenter];
    
    BOOL frameChanged = NO, orientationChanged = NO;
    
    CGColorRef nColor = [self.layoutController frameColor];
    if (nColor != frameColor) {
        if (frameColor != NULL) CGColorRelease(frameColor);
        frameColor = nColor;
        if (frameColor != NULL) {
            CGColorRetain(frameColor);
            _printedMapScrollLayer.cornerRadius = 12.0;
        } else {
            _printedMapScrollLayer.cornerRadius = 0.0;
        }
        
        frameChanged = YES;
    }
    
    NSPrintingOrientation t = [self.layoutController orientation];
    if (t != orientation) {
        orientation = t;
        orientationChanged = YES;
    }
    
    if (frameChanged || orientationChanged) {
        [self adjustPrintedMapLayerForBounds];
    }
    
    NSSize pSize = [self.layoutController paperSize];
    paperSize = NSSizeToCGSize(pSize);
    

    
    // Convert the layout position to view coordinates.
    CGPoint desiredCenter = [tiledLayer convertPoint:[self.layoutController layoutCenterPosition] toLayer:[self layer]];
    NSClipView *cv = [[self enclosingScrollView] contentView];
    CGRect visibleRect = NSRectToCGRect([cv documentVisibleRect]);
    [cv scrollToPoint:NSMakePoint(desiredCenter.x-0.5*CGRectGetWidth(visibleRect)+ 0.5*LAYOUT_VIEW_WIDTH, desiredCenter.y-0.5*CGRectGetHeight(visibleRect))];
    
    // Sync paper with background.
    
    if (frameColor != NULL) {
        
    } else {
        
    } */
    
    [_printedMapLayer setNeedsDisplay];
}

- (void)visibleSymbolsChanged:(NSNotification *)n {
    if (self.state == kASMapViewLayout && [self.mapProvider supportsHiddenSymbolNumbers]) {
        size_t c;
        const int32_t *hidden = [self.layoutController hiddenObjects:&c];
        [self.mapProvider setHiddenSymbolNumbers:hidden count:c];
        [tiledLayer setNeedsDisplayInRect:[tiledLayer bounds]];
        [_innerMapLayer setNeedsDisplayInRect:[_innerMapLayer bounds]];
    }
}

- (void)frameColorChanged:(NSNotification *)notification {
    // Received when the color changes.
    CGColorRef nColor = [self.layoutController frameColor];
    if (nColor != frameColor) {
        if (frameColor != NULL) CGColorRelease(frameColor);
        if ([self.layoutController frameVisible]) {
            frameColor = nColor;
            if (frameColor != NULL) {
                CGColorRetain(frameColor);
            }
        } else {
            frameColor = NULL;
        }
    }

    [_printedMapLayer setNeedsDisplay];
}

- (void)ensureCorrectScaleAndLocation {
    // Set the primitive zoom so that the effective width of the paper contains exactly the right number of points.
    /* First check that we're on screen. */
    CGFloat visibleWidth = _printedMapScrollLayer.visibleRect.size.width;
    CGFloat p = [self printingScale];
    if (visibleWidth == 0.0 || p == 0.0) {
        NSLog(@"Unable to ensure correct scale at this time.");
        return;
    }

    
    /*
     * We want to 1) set the frame of the inner map layers
     * and 2) set the transform of those layers so that just the right
     * amount of map (and at the correct location) is drawn within the map
     * layer.
     * The frame has to be set after the transform is calculated.
     */
    
    // Calculate the number of map points that fit in the paper width.
    //
    CGFloat pointsInWidth = ((orientation == NSLandscapeOrientation)?paperSize.height:paperSize.width) * 100.0 * p / 15000.0;
    // Kastellegården har 38000 pts in x. 380 mm i 15000-del. Låter mycket men kartan har mycket extra så det kan nog stämma.
    // 297 mm * 100 = 297000 * 10000/15000
    // visibleWidth is the number of points that are visible with the current transform.
    // We then adjust the zoom by the quotient visibleWidth/pointsInWidth.
    // If more are visible than we should have, the zoom is increased.
	CGFloat z2 = visibleWidth/pointsInWidth;
    NSLog(@"Ensuring correct scale z2 %f",z2);
	_innerMapLayer.transform = CATransform3DMakeScale(z2, z2, 1.0);
    _innerOverprintLayer.transform = _innerMapLayer.transform;
    
    NSRect r = NSMakeRect(0.0, 0.0, mapBounds.size.width*z2, mapBounds.size.height*z2);
    if (r.size.width == 0.0 || r.size.height == 0.0) r.size = NSMakeSize(1.0, 1.0);
	[self setFrame:r];
    
    // Now we want to set the same transform for the tiledLayer, but maintain the center.
    tiledLayer.transform = _innerMapLayer.transform;
    overprintLayer.transform = tiledLayer.transform;

    [self centerMapOnCoordinates:[self.layoutController layoutCenterPosition]];
}

- (CGPoint)centerOfMap {
    CGRect visibleRectOfInnerMapLayer = [_innerMapLayer visibleRect];
    if (visibleRectOfInnerMapLayer.size.width == 0.0) {
        // Not yet displayed.
        return [self.layoutController layoutCenterPosition];
    }
    CGPoint currentMidpointInMapCoordinates = CGPointMake(CGRectGetMidX(visibleRectOfInnerMapLayer), CGRectGetMidY(visibleRectOfInnerMapLayer));

    return currentMidpointInMapCoordinates;
}

- (void)centerMapOnCoordinates:(CGPoint)desiredCenter {
    CGRect mapRect = [_printedMapScrollLayer convertRect:[_printedMapScrollLayer visibleRect] toLayer:_innerMapLayer];
    [_innerMapLayer scrollRectToVisible:CGRectMake(desiredCenter.x-CGRectGetWidth(mapRect)*0.5, desiredCenter.y-CGRectGetHeight(mapRect)*0.5, mapRect.size.width, mapRect.size.height)];
    
    // Calculate the size of the visible rectangle, in map coordinates.
    CGRect visibleRect = [self visibleRect];
    CGSize possibleSize = [_innerMapLayer convertRect:visibleRect fromLayer:[self layer]].size;
    
    //
    CGPoint center = [self centerOfMap];
    CGRect paperFrame = [[self printedMapLayer] frame];
    CGPoint paperCenterInScrollViewCoordinates = CGPointMake(CGRectGetMidX(paperFrame), CGRectGetMidY(paperFrame));
    CGPoint originInMapCoordinates = CGPointMake(center.x - paperCenterInScrollViewCoordinates.x*possibleSize.width/visibleRect.size.width,
                                                 center.y - paperCenterInScrollViewCoordinates.y*possibleSize.height/visibleRect.size.height);
    CGPoint origin = [tiledLayer convertPoint:originInMapCoordinates toLayer:[self layer]];
    [self scrollPoint:origin];
    
    visibleRect = [self visibleRect];
    
    // If these ever get large, we need to move the paper (and then synchronize the paper with the background).
    CGFloat dX = round(origin.x - visibleRect.origin.x);
    CGFloat dY = round(origin.y - visibleRect.origin.y);
    CGPoint mapPos = [self printedMapLayer].position;
    mapPos.x += dX;
    mapPos.y += dY;
    [self printedMapLayer].position = mapPos;
    if (dX > 0 || dY > 0) [self synchronizePaperWithBackground];
    
    [_innerMapLayer setNeedsDisplayInRect:[_innerMapLayer visibleRect]];
    [_innerOverprintLayer setNeedsDisplayInRect:[_innerOverprintLayer visibleRect]];
}

- (void)synchronizePaperWithBackground {
    CGRect paper = [tiledLayer convertRect:_printedMapScrollLayer.frame fromLayer:_printedMapLayer];
    [_innerMapLayer scrollPoint:CGPointMake(paper.origin.x, paper.origin.y)];
}

- (void)updatePaperMapButMaintainPositionWhileDoing:(void (^)(void))block animate:(BOOL)animate {
    [CATransaction begin];
    [CATransaction setDisableActions:!animate];

    CGPoint p = [self centerOfMap];
    block();
    [self centerMapOnCoordinates:p];
    
    [CATransaction commit];
    
}

- (void)printingScaleChanged:(NSNotification *)notification {
    NSLog(@"Printing scale changed");
    CGFloat s = (CGFloat)[self.layoutController scale];
    
    [self updatePaperMapButMaintainPositionWhileDoing:^{
        [self setPrintingScale:s];
    } animate:NO];
    
    [_printedMapLayer setNeedsDisplay];
}

- (void)orientationChanged:(NSNotification *)notification {
    NSLog(@"Orientation or paper size changed");
    orientation = [self.layoutController orientation];
    paperSize = [self.layoutController paperSize];
    [self updatePaperMapButMaintainPositionWhileDoing:^{
        [self adjustPrintedMapLayerForBounds];
    } animate:NO];
    [_printedMapLayer setNeedsDisplay];
}

- (void)layoutFrameChanged:(NSNotification *)notification {
    [self updatePaperMapButMaintainPositionWhileDoing:^{
        if ([self.layoutController frameVisible]) {
            if (frameColor == NULL) {
                // No previous frame.
                _printedMapScrollLayer.frame = CGRectInset(_printedMapScrollLayer.frame, FRAME_INSET,FRAME_INSET);
            } else {
                CGColorRelease(frameColor);
            }
            frameColor = [self.layoutController frameColor];
            NSAssert(frameColor != NULL, @"No frame color!");
            CGColorRetain(frameColor);
            
            _printedMapScrollLayer.cornerRadius = FRAME_CORNER_RADIUS;
        } else {
            if (frameColor != NULL) {
                CGColorRelease(frameColor);
                frameColor = NULL;
                _printedMapScrollLayer.frame = CGRectInset(_printedMapScrollLayer.frame, -FRAME_INSET,-FRAME_INSET);
            }
            _printedMapScrollLayer.cornerRadius = 0.0;
        }
    } animate:NO];

    [_printedMapLayer setNeedsDisplay];
}

- (void)eventDetailsChanged:(NSNotification *)notification {
    NSLog(@"Event details changed");
    
    // Received when the event or date changes. Rebuild the string and setup a new frame.
    
    [_printedMapLayer setNeedsDisplay];
}

- (void)setupLayoutNotificationObserving {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(visibleSymbolsChanged:) name:ASLayoutVisibleItemsChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutFrameChanged:) name:ASLayoutFrameChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameColorChanged:) name:ASLayoutFrameColorChanged object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:ASLayoutOrientationChanged object:nil];
//  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutChanged:) name:ASLayoutChanged object:nil];
/* 
 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(printingScaleChanged:) name:ASLayoutScaleChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventDetailsChanged:) name:ASLayoutEventDetailsChanged object:nil];*/
}

- (void)teardownLayoutNotificationObserving {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutVisibleItemsChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutFrameChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutFrameColorChanged object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutOrientationChanged object:nil];
/*    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutScaleChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutEventDetailsChanged object:nil];
 */
}

@end
