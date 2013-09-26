//
//  ASMapView+Layout.m
//  O-course
//
//  Created by Erik Aderstedt on 2013-08-30.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import "ASMapView+Layout.h"
#import "ASLayoutController.h"
#import "ASControlDescriptionView.h"
#import "Graphic.h"

#define DEFAULT_PRINTING_SCALE 10000.0
#define FRAME_CORNER_RADIUS 12.0
#define FRAME_WIDTH 6.0
#define USER_POINTS_TO_MM(x) ((x)*25.4/72)
#define MM_TO_USER_POINTS(x) ((x)*72./25.4)
#define HANDLE_SIZE 50.0

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
        _printedMapLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
        
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
        _innerMapLayer.delegate = [self.mapProvider layoutProxy];
        
        _innerOverprintLayer = [CATiledLayer layer];
        _innerOverprintLayer.name = @"innerOverprint";
        _innerOverprintLayer.needsDisplayOnBoundsChange = YES;
        _innerOverprintLayer.tileSize = tiledLayer.tileSize;
        _innerOverprintLayer.levelsOfDetail = tiledLayer.levelsOfDetail;
        _innerOverprintLayer.levelsOfDetailBias = tiledLayer.levelsOfDetailBias;
        _innerOverprintLayer.bounds = _innerMapLayer.bounds;
        _innerOverprintLayer.anchorPoint = _innerMapLayer.anchorPoint;
        _innerOverprintLayer.position = _innerMapLayer.position;
        _innerOverprintLayer.delegate = self;

        _decorLayer = [CALayer layer];
        _decorLayer.delegate = self;
        _decorLayer.name = @"decor";
        _decorLayer.zPosition = 1.0;
        _decorLayer.needsDisplayOnBoundsChange = YES;
        [_printedMapLayer addSublayer:_decorLayer];
        [_decorLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
        [_decorLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY]];
        [_decorLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
        [_decorLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY]];
        
        [_printedMapLayer setNeedsLayout];
        
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

- (CALayer *)controlDescriptionLayer {
    if (_controlDescriptionLayer == nil) {
        _controlDescriptionLayer = [CALayer layer];
        _controlDescriptionLayer.backgroundColor = [[self printedMapLayer] backgroundColor];
        _controlDescriptionLayer.hidden = YES;
        _controlDescriptionLayer.delegate = self;
        [[self printedMapLayer] addSublayer:_controlDescriptionLayer];
    }
    return _controlDescriptionLayer;
}

- (void)drawMaskedAreasInContext:(CGContextRef)ctx {
    CGContextSaveGState(ctx);
    CGContextSetFillColorWithColor(ctx, _printedMapLayer.backgroundColor);
    for (NSArray *vertexList in [self.layoutController maskedAreaVertices]) {
        CGContextBeginPath(ctx);
        for (NSValue *v in vertexList) {
            CGPoint p = [v pointValue];
            if (CGContextIsPathEmpty(ctx)) {
                CGContextMoveToPoint(ctx, p.x, p.y);
            } else {
                CGContextAddLineToPoint(ctx, p.x, p.y);
            }
        }
        CGContextFillPath(ctx);
    }
    
    if (self.currentMaskedAreaVertices) {
        CGMutablePathRef base = CGPathCreateMutable();
        CGMutablePathRef corners = CGPathCreateMutable();
        for (NSValue *v in self.currentMaskedAreaVertices) {
            NSPoint p = [v pointValue];
            if (CGPathIsEmpty(base)) {
                CGPathMoveToPoint(base, NULL, p.x, p.y);
            } else {
                CGPathAddLineToPoint(base, NULL, p.x, p.y);
            }
            CGPathAddRect(corners, NULL, CGRectMake(p.x-HANDLE_SIZE, p.y-HANDLE_SIZE, 2.0*HANDLE_SIZE, 2.0*HANDLE_SIZE));
        }
        CGContextBeginPath(ctx);
        CGContextAddPath(ctx, base);
        CGContextFillPath(ctx);
        
        CGContextSetStrokeColorWithColor(ctx, [[NSColor grayColor] CGColor]);
        CGFloat dashes[2]; dashes[0] = HANDLE_SIZE; dashes[1] = 0.6*HANDLE_SIZE;
        CGContextSetLineDash(ctx, 0.0, dashes, 2);
        CGContextStrokePath(ctx);
        
        CGContextSetFillColorWithColor(ctx, [[NSColor darkGrayColor] CGColor]);
        CGContextBeginPath(ctx);
        CGContextAddPath(ctx, corners);
        CGContextFillPath(ctx);
    }
    
    CGContextRestoreGState(ctx);
}

+ (NSArray *)cornersForRect:(NSRect)r {
	return @[
             [NSValue valueWithPoint:NSMakePoint(NSMinX(r), NSMinY(r))],
             [NSValue valueWithPoint:NSMakePoint(NSMinX(r), NSMidY(r))],
             [NSValue valueWithPoint:NSMakePoint(NSMinX(r), NSMaxY(r))],
             [NSValue valueWithPoint:NSMakePoint(NSMidX(r), NSMaxY(r))],
             [NSValue valueWithPoint:NSMakePoint(NSMaxX(r), NSMaxY(r))],
             [NSValue valueWithPoint:NSMakePoint(NSMaxX(r), NSMidY(r))],
			[NSValue valueWithPoint:NSMakePoint(NSMaxX(r), NSMinY(r))],
			[NSValue valueWithPoint:NSMakePoint(NSMidX(r), NSMinY(r))]];
}

- (void)drawDecorInContext:(CGContextRef)ctx {
    // Drawing is from the main thread. This means that it's safe to fetch graphic objects using Core Data.
    NSAssert([NSThread isMainThread], @"Drawing paper frame in a background thread!");

    CGContextSaveGState(ctx);
    CGFloat inset = [self recommendedFrameInsetForBounds:_printedMapLayer.bounds];
    CGPathRef path = CGPathCreateRoundRect(CGRectIntegral(CGRectInset([_printedMapScrollLayer frame], -inset*0.5, -inset*0.5)), _printedMapScrollLayer.cornerRadius*0.5);
    CGContextBeginPath(ctx);
    CGContextAddPath(ctx, path);
    CGContextClip(ctx);
    CGPathRelease(path);

    NSGraphicsContext *nsGraphicsContext;
    nsGraphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx
                                                                   flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:nsGraphicsContext];

    [NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:NO];
    CGFloat scalingFactor = 1.0/[self actualPaperRelatedToPaperOnPage];
    for (id <ASGraphicItem> g in [self.layoutController graphicsInLayout]) {
        CGRect f = g.frame;
        CGAffineTransform at = CGAffineTransformMakeScale(scalingFactor, scalingFactor);
        if (g.whiteBackground) {
            [[NSColor whiteColor] set];
            NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:CGRectApplyAffineTransform(CGRectInset(f, -6.0, -6.0), at)
                                                                       xRadius:FRAME_CORNER_RADIUS
                                                                       yRadius:FRAME_CORNER_RADIUS];
            [bezierPath fill];
        }
        f = CGRectApplyAffineTransform(f, at);
        f = CGRectIntegral(f);
        [g.image drawInRect:f fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
        
        if (self.selectedGraphic == g && (
                                          self.layoutState == kASLayoutModeNormal ||
                                          self.layoutState == kASLayoutModeMovingGraphic ||
                                          self.layoutState == kASLayoutModeResizingGraphic ||
                                          self.layoutState == kASLayoutModeDraggingMap)) {
            [[NSColor grayColor] set];
            NSBezierPath *bp = [NSBezierPath bezierPathWithRect:f];
            CGFloat dashes[2]; dashes[0] = 5.0; dashes[1] = 3.0;
            [bp setLineDash:dashes count:2 phase:0.0];
            [bp stroke];
            
            // Draw rects
            [[NSColor darkGrayColor] set];
            for (NSValue *corner in [[self class] cornersForRect:f]) {
                NSPoint p = [corner pointValue];
                NSRect crect = NSMakeRect(p.x-3.0, p.y-3.0, 6.0, 6.0);
                [NSBezierPath fillRect:crect];
            }
        }
    }
    [NSGraphicsContext restoreGraphicsState];
    CGContextRestoreGState(ctx);
}

- (void)drawPaperFrameInContext:(CGContextRef)ctx {
    NSAssert(self.frameVisible, @"Shouldn't be drawing the frame");
    CGRect r = uninsetFrameForScrollMapLayer;
    
    CGContextBeginPath(ctx);
    if (self.eventDetails != nil) {
        CGMutablePathRef p;
        p = CGPathCreateMutable();

        CGPathMoveToPoint(p, NULL, r.origin.x + FRAME_CORNER_RADIUS, r.origin.y);
        
        CGFloat maxX = CGRectGetMaxX(r);
        CGFloat maxY = CGRectGetMaxY(r);
        CGFloat inset = NSMinX(r);
        CGFloat scale = 1.0/[self actualPaperRelatedToPaperOnPage];
        
        NSFont *font = [NSFont fontWithName:@"Helvetica Neue" size:round(16.0*scale)];
        NSAttributedString *as = [[NSAttributedString alloc] initWithString:self.eventDetails
                                                                 attributes:@{ NSFontAttributeName:font, NSForegroundColorAttributeName:(__bridge id)self.frameColor}];
        CTLineRef ed = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)as);
        CGRect textBounds = CTLineGetBoundsWithOptions(ed, kCTLineBoundsUseGlyphPathBounds);

        CGContextSetTextPosition(ctx, r.origin.x + 2.5*inset, maxY - 0.25*textBounds.size.height);
        CTLineDraw(ed, ctx);
        CFRelease(ed);
        
        CGPathAddArcToPoint(p, NULL, maxX, r.origin.y, maxX, r.origin.y + FRAME_CORNER_RADIUS, FRAME_CORNER_RADIUS);
        CGPathAddArcToPoint(p, NULL, maxX, maxY, maxX - FRAME_CORNER_RADIUS, maxY, FRAME_CORNER_RADIUS);
        
        CGPathAddLineToPoint(p, NULL, r.origin.x + 3.2*inset + textBounds.size.width, maxY);
        CGPathMoveToPoint(p, NULL, r.origin.x + 2.0*inset, maxY);
        CGPathAddArcToPoint(p, NULL, r.origin.x, maxY, r.origin.x, maxY - FRAME_CORNER_RADIUS, FRAME_CORNER_RADIUS);
        CGPathAddArcToPoint(p, NULL, r.origin.x, r.origin.y, r.origin.x + FRAME_CORNER_RADIUS, r.origin.y, FRAME_CORNER_RADIUS);
        CGContextAddPath(ctx, p);
        CGPathRelease(p);

    } else {
        CGPathRef p2 = CGPathCreateRoundRect(r, FRAME_CORNER_RADIUS);
        CGContextAddPath(ctx, p2);
        CGPathRelease(p2);
    }
    CGContextSetStrokeColorWithColor(ctx, self.frameColor);
    CGContextSetLineWidth(ctx, 5.0/[self actualPaperRelatedToPaperOnPage]);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    
    CGContextStrokePath(ctx);
}

- (CIFilter *)backgroundMapFilter {
    if (_backgroundMapFilter == nil) {
        _backgroundMapFilter = [CIFilter filterWithName:@"CIColorControls"];
        [_backgroundMapFilter setDefaults];
        _backgroundMapFilter.name = @"skuggkarta";
    }
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
    
    [self determineMargins];
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
    CGFloat inset = [self recommendedFrameInsetForBounds:_printedMapLayer.bounds];
    uninsetFrameForScrollMapLayer = r;
    if (self.frameColor != NULL) {
        r = CGRectInset(uninsetFrameForScrollMapLayer, inset, inset);
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
    self.changedLayoutPosition = YES;
}

#pragma mark Responding to layout change notifications

- (void)recordNewLayoutCenter {
    CGPoint p = [self centerOfMap];
    p.x = round(p.x);
    p.y = round(p.y);
    CGPoint p2 = [self.layoutController layoutCenterPosition];
    p2.x = round(p2.x);
    p2.y = round(p2.y);
    if (p2.x != p.x || p2.y != p2.y) {
        [self.layoutController writeLayoutCenterPosition:p];
    }
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
    if (self.changedLayoutPosition == YES) {
        [self recordNewLayoutCenter];
        self.changedLayoutPosition = NO;
    }
}

- (void)layoutChanged:(NSNotification *)n {
    
    _printingScale = (CGFloat)[self.layoutController scale];
    self.orientation = [self.layoutController orientation];
    self.paperSize = [self.layoutController paperSize];
    BOOL showFrame = [self.layoutController frameVisible];
    if (showFrame) {
        [self setFrameColor:[self.layoutController frameColor]];
        if (!self.frameVisible) {
            CGFloat inset = [self recommendedFrameInsetForBounds:_printedMapLayer.bounds];
            [_printedMapScrollLayer setFrame:CGRectInset(uninsetFrameForScrollMapLayer, inset, inset)];
            _printedMapScrollLayer.cornerRadius = FRAME_CORNER_RADIUS;
            self.frameVisible = YES;
        }
    } else {
        [self setFrameColor:NULL];
        if (self.frameVisible) {
            [_printedMapScrollLayer setFrame:uninsetFrameForScrollMapLayer];
            _printedMapScrollLayer.cornerRadius = 0.0;
            self.frameVisible = NO;
        }
    }

    [self visibleSymbolsChanged:n];
    
    [self adjustPrintedMapLayerForBounds];
    [self handleScaleAndOrientation];
    [self centerMapOnCoordinates:[self.layoutController layoutCenterPosition]];
    
    [_printedMapLayer setNeedsDisplay];
}

- (void)visibleSymbolsChanged:(NSNotification *)n {
    if (self.state == kASMapViewLayout && [self.mapProvider supportsHiddenSymbolNumbers]) {
        size_t c;
        const int32_t *hidden = [self.layoutController hiddenObjects:&c];
        [[self.mapProvider layoutProxy] setHiddenSymbolNumbers:hidden count:c];
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
        CGPoint p = [self.layoutController layoutCenterPosition];
        if (p.x > 1.e6) return CGPointMake(0.0, 0.0);
        NSAssert(p.x < 1e6, @"NO?");
        return p;
    }
    CGPoint currentMidpointInMapCoordinates = CGPointMake(CGRectGetMidX(visibleRectOfInnerMapLayer), CGRectGetMidY(visibleRectOfInnerMapLayer));

    NSAssert(currentMidpointInMapCoordinates.x < 1e6, @"NO?");
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

- (CGFloat)actualPaperRelatedToPaperOnPage {
    NSSize  actualPaper = self.paperSize,
            paperOnPage = _printedMapLayer.bounds.size;
    
    return sqrt((actualPaper.width*actualPaper.width + actualPaper.height*actualPaper.height)/(paperOnPage.height*paperOnPage.height + paperOnPage.width*paperOnPage.width));
}

- (CGFloat)recommendedFrameInsetForBounds:(NSRect)r {
    // This value will change if we're showing event name or event details.
    // 5 mm otherwise
    
    CGFloat x = MAX(self.paperSize.width, self.paperSize.height);
    CGFloat inset = 4.5 /* mm */ /USER_POINTS_TO_MM(x);
    return inset*MAX(r.size.width, r.size.height);
}

- (void)determineMargins {
    NSPrintInfo *pi = [NSPrintInfo sharedPrintInfo];
    CGFloat scale;
    scale = 1.0/[self actualPaperRelatedToPaperOnPage];
    [pi setOrientation:self.orientation];
    NSRect ib = [pi imageablePageBounds];
    NSSize psize = [pi paperSize];

    leftMargin = NSMinX(ib) *scale;
    rightMargin = (psize.width -NSMaxX(ib)) *scale;
    topMargin = NSMinY(ib)*scale;
    bottomMargin = (psize.height - NSMaxY(ib)) *scale;

    topMargin = MIN(leftMargin,rightMargin);
    bottomMargin = MIN(leftMargin,rightMargin);
    leftMargin = MIN(leftMargin,rightMargin);
    rightMargin = MIN(leftMargin,rightMargin);
    
    if (self.frameVisible && self.eventDetails != nil) {
        if (self.orientation == NSLandscapeOrientation) {
            rightMargin += 5.0*scale;
        } else {
            topMargin += 5.0*scale;
        }
    }
    
}

- (void)handleScaleAndOrientation {
    CGFloat visibleWidth = _printedMapLayer.frame.size.width;
    CGFloat p = _printingScale;
    if (visibleWidth == 0.0 || p == 0.0) {
        NSLog(@"Unable to ensure correct scale at this time.");
        return;
    }
    CGFloat pointsInWidth = USER_POINTS_TO_MM(((self.orientation == NSLandscapeOrientation)?self.paperSize.height:self.paperSize.width)) * 100.0 * p / [self.mapProvider nativeScale];

    CGFloat z2 = visibleWidth/pointsInWidth;
    
    _innerMapLayer.transform = CATransform3DMakeScale(z2, z2, 1.0);
    tiledLayer.transform = _innerMapLayer.transform;
    overprintLayer.transform = _innerMapLayer.transform;
    NSRect r = NSMakeRect(0.0, 0.0, mapBounds.size.width*z2, mapBounds.size.height*z2);
    if (r.size.width == 0.0 || r.size.height == 0.0) r.size = NSMakeSize(1.0, 1.0);
    [self setFrame:r];
    
    _innerOverprintLayer.transform = _innerMapLayer.transform;
    
    [self adjustControlDescription];    
}

- (void)adjustControlDescription {
    enum ASLayoutControlDescriptionLocation location = [self.layoutController controlDescriptionLocation];
    CGRect psmf = [_printedMapScrollLayer frame];
    CGRect frame = [[self printedMapLayer] frame];
    CGSize pSize = [self.layoutController paperSize];
    
    CALayer *cd = [self controlDescriptionLayer];
    // TODO: calculate a better inset.
    CGFloat inset = round([self.controlDescriptionView insetDistanceForLayer:cd]);
    CGFloat width = MIN(frame.size.width,frame.size.height)/MIN(USER_POINTS_TO_MM(pSize.width), USER_POINTS_TO_MM(pSize.height)) * 6.0 * 8.0 + 2.0*inset;
    cd.bounds = CGRectMake(0.0, 0.0, width, [self.controlDescriptionView heightForWidth:width]);
    switch (location) {
        case kASControlDescriptionBottomLeft:
            cd.anchorPoint = CGPointMake(0.0, 0.0);
            cd.position = CGPointMake(CGRectGetMinX(psmf) - inset, CGRectGetMinY(psmf) - inset);
            break;
        case kASControlDescriptionBottomRight:
            cd.anchorPoint = CGPointMake(1.0, 0.0);
            cd.position = CGPointMake(CGRectGetMaxX(psmf) + inset, CGRectGetMinY(psmf) - inset);
            break;
        case kASControlDescriptionTopLeft:
            cd.anchorPoint = CGPointMake(0.0, 1.0);
            cd.position = CGPointMake(CGRectGetMinX(psmf) - inset, CGRectGetMaxY(psmf) + inset);
            break;
        case kASControlDescriptionTopRight:
            cd.anchorPoint = CGPointMake(1.0, 1.0);
            cd.position = CGPointMake(CGRectGetMaxX(psmf) + inset, CGRectGetMaxY(psmf) + inset);
            break;
        default:
            break;
    }
    
    if (![self.layoutController showControlDescription]) {
        cd.hidden = YES;
    } else {
        cd.hidden = NO;
        [cd setNeedsDisplay];
    }

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
    BOOL after = [self.layoutController frameVisible];
    BOOL change = (self.frameVisible != after) || (self.eventDetails != [self.layoutController eventDescription]);
    if (change) {
    [self updatePaperMapButMaintainPositionWhileDoing:^{
        if ([self.layoutController frameVisible]) {
            if (!self.frameVisible) {
                CGFloat inset = [self recommendedFrameInsetForBounds:_printedMapLayer.bounds];
                _printedMapScrollLayer.frame = CGRectInset(uninsetFrameForScrollMapLayer, inset, inset);
                _printedMapScrollLayer.cornerRadius = FRAME_CORNER_RADIUS;
                self.frameVisible = YES;
            }
            [self setFrameColor:[self.layoutController frameColor]];
        } else {
            [self setFrameColor:NULL];
            if (self.frameVisible) {
                _printedMapScrollLayer.frame = uninsetFrameForScrollMapLayer;
                _printedMapScrollLayer.cornerRadius = 0.0;
                self.frameVisible = NO;
            }
        }
        
        self.eventDetails = [self.layoutController eventDescription];

        [self adjustPrintedMapLayerForBounds];

    } animate:NO];
    }
    
    CGColorRef nColor = [self.layoutController frameColor];
    if (nColor != self.frameColor) {
        if ([self.layoutController frameVisible]) {
            self.frameColor = nColor;
        } else {
            self.frameColor = NULL;
        }
    }

    [self adjustControlDescription];
    [_printedMapLayer setNeedsDisplay];
}

- (void)decorChanged:(NSNotification *)notification {
    if (_decorLayer == nil) {
        [[self printedMapLayer] setNeedsDisplay];
    }
    [_decorLayer setNeedsDisplay];
}

- (void)maskedAreasChanged:(NSNotification *)notification {
    [self.layoutController cacheMaskedAreas];
    [_innerOverprintLayer setNeedsDisplayInRect:[_innerOverprintLayer bounds]];
}

- (void)setupLayoutNotificationObserving {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(visibleSymbolsChanged:) name:ASLayoutVisibleItemsChanged object:self.layoutController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutFrameChanged:) name:ASLayoutFrameChanged object:self.layoutController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(printingScaleChanged:) name:ASLayoutScaleChanged object:self.layoutController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:ASLayoutOrientationChanged object:self.layoutController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutChanged:) name:ASLayoutChanged object:self.layoutController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(decorChanged:) name:ASLayoutDecorChanged object:self.layoutController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(courseChanged:) name:@"ASCourseChanged" object:self.layoutController.layouts.managedObjectContext];
}

- (void)teardownLayoutNotificationObserving {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutVisibleItemsChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutFrameChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutScaleChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutOrientationChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASLayoutDecorChanged object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ASCourseChanged" object:nil];
}

- (CGRect)mapFrame {
    return [_printedMapScrollLayer frame];
}

- (CGRect)paperFrame {
    return [[self printedMapLayer] bounds];
}

- (CGFloat)cornerRadius {
    return [_printedMapScrollLayer cornerRadius];    
}

- (enum ASLayoutControlDescriptionLocation)location {
    return [self.layoutController controlDescriptionLocation];
}

- (BOOL)controlDescriptionVisible {
    return [self.layoutController showControlDescription];
}

- (void)courseChanged:(NSNotification *)n {
    [self adjustControlDescription];
}

- (void)resetCursorRects {
    if (self.state == kASMapViewLayout && self.layoutState == kASLayoutModeAddingArea) {
        [self addCursorRect:[self bounds] cursor:[NSCursor crosshairCursor]];
    } else if (self.selectedGraphic) {
        for (NSValue *cornerCenterValue in [[self class] cornersForRect:self.selectedGraphic.frame]) {
            NSPoint cornerCenter = [cornerCenterValue pointValue];
            // Convert this point to view coordinates.
            CGFloat f = [self actualPaperRelatedToPaperOnPage];
            cornerCenter.x /= f;
            cornerCenter.y /= f;
            cornerCenter = [[self layer] convertPoint:cornerCenter fromLayer:[self printedMapLayer]];
            NSRect r = NSMakeRect(cornerCenter.x-3.0, cornerCenter.y-3.0, 6.0, 6.0);
            
            [self addCursorRect:r cursor:[NSCursor openHandCursor]];
        }
    }
}

- (IBAction)addWhiteArea:(id)sender {
    if (self.state != kASMapViewLayout) return;

    self.layoutState = kASLayoutModeAddingArea;
    self.selectedGraphic = nil;
    [_decorLayer setNeedsDisplay];
    [self resetCursorRects];
    [self updateTrackingAreas];
}

@end
