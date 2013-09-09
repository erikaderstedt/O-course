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
    NSLog(@"paper frame %@", NSStringFromRect(r));
    CGPathRef p = CGPathCreateRoundRect(r, 12.0);
    CGContextAddPath(ctx, p);
    CGPathRelease(p);
    CGContextSetStrokeColorWithColor(ctx, self.frameColor);
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
    CGFloat a4ratio = self.paperSize.height/self.paperSize.width;
    CGFloat fraction = 0.8;
    if (self.orientation == NSLandscapeOrientation) {
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
    if (self.orientation == NSLandscapeOrientation) {
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
    if (self.frameColor != NULL) {
        r = CGRectInset(r, FRAME_INSET, FRAME_INSET);
        self.frameVisible = YES;
    } else {
        self.frameVisible = NO;
    }
    [_printedMapScrollLayer setFrame:r];
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
    [self.layoutController writeLayoutCenterPosition:newCenterPosition];
}

- (void)setFrameColor:(CGColorRef)fColor {
    if (_frameColor != NULL) {
        CGColorRelease(_frameColor);
    }
    _frameColor = fColor;
    if (_frameColor != NULL) {
        CGColorRetain(_frameColor);
    }
}

- (CGColorRef)frameColor {
    return _frameColor;
}

- (void)layoutWillChange:(NSNotification *)n {
    [self recordNewLayoutCenter];
}

- (void)layoutChanged:(NSNotification *)n {
    
    _printingScale = (CGFloat)[self.layoutController scale];
    self.orientation = [self.layoutController orientation];
    self.paperSize = [self.layoutController paperSize];
    BOOL showFrame = [self.layoutController frameVisible];
    if (showFrame) {
        [self setFrameColor:[self.layoutController frameColor]];
        if (!self.frameVisible) {
            [[self printedMapLayer] setFrame:CGRectInset([[self printedMapLayer] frame], FRAME_INSET, FRAME_INSET)];
            _printedMapScrollLayer.cornerRadius = FRAME_CORNER_RADIUS;
            self.frameVisible = YES;
        }
    } else {
        [self setFrameColor:NULL];
        if (self.frameVisible) {
            [[self printedMapLayer] setFrame:CGRectInset([[self printedMapLayer] frame], -FRAME_INSET, -FRAME_INSET)];
            _printedMapScrollLayer.cornerRadius = 0.0;
            self.frameVisible = NO;
        }
    }

    [self adjustPrintedMapLayerForBounds];
    [self handleScaleAndOrientation];
    [self centerMapOnCoordinates:[self.layoutController layoutCenterPosition]];
    
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
    if (nColor != self.frameColor) {
        if ([self.layoutController frameVisible]) {
            self.frameColor = nColor;
        } else {
            self.frameColor = NULL;
        }
    }

    [_printedMapLayer setNeedsDisplay];
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
    if (fabs(dX) > 0 || fabs(dY) > 0) [self synchronizePaperWithBackground];
    
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

- (void)handleScaleAndOrientation {
    CGFloat visibleWidth = _printedMapScrollLayer.frame.size.width;
    CGFloat p = _printingScale;
    if (visibleWidth == 0.0 || p == 0.0) {
        NSLog(@"Unable to ensure correct scale at this time.");
        return;
    }
    CGFloat pointsInWidth = ((self.orientation == NSLandscapeOrientation)?self.paperSize.height:self.paperSize.width) * 100.0 * p / 15000.0;

    CGFloat z2 = visibleWidth/pointsInWidth;
    
    _innerMapLayer.transform = CATransform3DMakeScale(z2, z2, 1.0);
    tiledLayer.transform = _innerMapLayer.transform;
    overprintLayer.transform = _innerMapLayer.transform;
    NSRect r = NSMakeRect(0.0, 0.0, mapBounds.size.width*z2, mapBounds.size.height*z2);
    if (r.size.width == 0.0 || r.size.height == 0.0) r.size = NSMakeSize(1.0, 1.0);
    [self setFrame:r];
    
    _innerOverprintLayer.transform = _innerMapLayer.transform;
    
}

- (CGFloat)printingScale {
    return _printingScale;
}

- (void)printingScaleChanged:(NSNotification *)notification {
    CGFloat s = (CGFloat)[self.layoutController scale];
    _printingScale = s;

    [self updatePaperMapButMaintainPositionWhileDoing:^{
        [self handleScaleAndOrientation];
    } animate:NO];
    
    [_printedMapLayer setNeedsDisplay];
}

- (void)orientationChanged:(NSNotification *)notification {
    self.orientation = [self.layoutController orientation];
    self.paperSize = [self.layoutController paperSize];
    [self updatePaperMapButMaintainPositionWhileDoing:^{
        [self adjustPrintedMapLayerForBounds];
        [self handleScaleAndOrientation];
    } animate:NO];
    [_printedMapLayer setNeedsDisplay];
}

- (void)layoutFrameChanged:(NSNotification *)notification {
    [self updatePaperMapButMaintainPositionWhileDoing:^{
        if ([self.layoutController frameVisible]) {
            if (!self.frameVisible) {
                _printedMapScrollLayer.frame = CGRectInset(_printedMapScrollLayer.frame, FRAME_INSET,FRAME_INSET);
                _printedMapScrollLayer.cornerRadius = FRAME_CORNER_RADIUS;
                self.frameVisible = YES;
            }
            [self setFrameColor:[self.layoutController frameColor]];
        } else {
            [self setFrameColor:NULL];
            if (self.frameVisible) {
                _printedMapScrollLayer.frame = CGRectInset(_printedMapScrollLayer.frame, -FRAME_INSET,-FRAME_INSET);
                _printedMapScrollLayer.cornerRadius = 0.0;
                self.frameVisible = NO;
            }
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(visibleSymbolsChanged:) name:ASLayoutVisibleItemsChanged object:self.layoutController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutFrameChanged:) name:ASLayoutFrameChanged object:self.layoutController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameColorChanged:) name:ASLayoutFrameColorChanged object:self.layoutController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(printingScaleChanged:) name:ASLayoutScaleChanged object:self.layoutController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:ASLayoutOrientationChanged object:self.layoutController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutChanged:) name:ASLayoutChanged object:self.layoutController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutWillChange:) name:ASLayoutWillChange object:self.layoutController];
/* 
 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventDetailsChanged:) name:ASLayoutEventDetailsChanged object:nil];*/
}

- (void)teardownLayoutNotificationObserving {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutVisibleItemsChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutFrameChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutFrameColorChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutScaleChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutOrientationChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutWillChange object:nil];
    
   /*
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutEventDetailsChanged object:nil];
 */
}

@end
