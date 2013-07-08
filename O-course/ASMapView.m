//
//  ASMapView.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-04.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASMapView.h"
#import "ASControlDescriptionView.h"
#define GLASS_SIZE 180.0
#define SIGN_OF(x) ((x > 0.0)?1.0:-1.0)
#define DEFAULT_PRINTING_SCALE 10000.0

@implementation ASMapView

@synthesize mapProvider, overprintProvider;
@synthesize showMagnifyingGlass;
@synthesize courseDataSource;
@synthesize state=state;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_zoom = 1.0;
        orientation = NSLandscapeOrientation;
        paperSize = CGSizeMake(210.0, 297.0);
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		_zoom = 1.0;
        orientation = NSLandscapeOrientation;
        paperSize = CGSizeMake(210.0, 297.0);
	}
	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:[self enclosingScrollView]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ASOverprintChanged" object:nil];
	[_magnifyingGlass removeFromSuperlayer];
    [_printedMapLayer removeFromSuperlayer];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    NSClipView *vc = [[self enclosingScrollView] contentView];
    
    [vc setPostsBoundsChangedNotifications:YES];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged:) name:NSViewFrameDidChangeNotification object:[self enclosingScrollView]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsChanged:) name:NSViewBoundsDidChangeNotification object:vc];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(overprintChanged:) name:@"ASOverprintChanged" object:nil];
    
    [[self enclosingScrollView] setBackgroundColor:[NSColor whiteColor]];
    
    [self setupTiledLayer];
}

#pragma mark -
#pragma mark Map loading

- (void)setupTiledLayer {
    if (tiledLayer == nil) {
        
        tiledLayer = [CATiledLayer layer];
        tiledLayer.name = @"tiled";
        tiledLayer.needsDisplayOnBoundsChange = YES;
        CGColorRef white = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
        tiledLayer.backgroundColor = white;
        CGColorRelease(white);
        tiledLayer.tileSize = CGSizeMake(512.0, 512.0);
        
        tiledLayer.levelsOfDetail = 7;
        tiledLayer.levelsOfDetailBias = 2;
        
        tiledLayer.anchorPoint = CGPointMake(0.0, 0.0);
        tiledLayer.position = CGPointMake(0.0, 0.0);
        
        overprintLayer = [CATiledLayer layer];
        overprintLayer.name = @"overprint";
        overprintLayer.needsDisplayOnBoundsChange = YES;
        CGColorRef blackTransparent = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.0);
        overprintLayer.backgroundColor = blackTransparent;
        CGColorRelease(blackTransparent);
        /*
         To use simulated overprint:
         overprintLayer.backgroundColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
         CIFilter *mulBlend = [CIFilter filterWithName:@"CIMultiplyCompositing"];
         overprintLayer.compositingFilter = mulBlend;
         */
        overprintLayer.tileSize = tiledLayer.tileSize;
        overprintLayer.levelsOfDetail = tiledLayer.levelsOfDetail;
        overprintLayer.levelsOfDetailBias = tiledLayer.levelsOfDetailBias;
        overprintLayer.anchorPoint = tiledLayer.anchorPoint;
        overprintLayer.position = tiledLayer.position;
        
        dragIndicatorLayer = [CALayer layer];
        dragIndicatorLayer.name = @"drag indicator";
        CGColorRef shadowGrey = CGColorCreateGenericRGB(0.3, 0.3, 0.3, 0.7);
        dragIndicatorLayer.backgroundColor = shadowGrey;
        CGColorRelease(shadowGrey);
        dragIndicatorLayer.cornerRadius = 3.0;
        dragIndicatorLayer.hidden = YES;
        [tiledLayer addSublayer:dragIndicatorLayer];

        [[self layer] addSublayer:tiledLayer]; [[self layer] addSublayer:overprintLayer];
        [tiledLayer setFilters:@[[self backgroundMapFilter]]];
        [overprintLayer setFilters:@[[self backgroundMapFilter]]];

    }
}

- (void)mapLoaded {
    
    if (self.mapProvider != nil) {
        if (tiledLayer == nil) [self setupTiledLayer];
        mapBounds = [self.mapProvider mapBounds];
        tiledLayer.bounds = mapBounds; overprintLayer.bounds = mapBounds;
        tiledLayer.delegate = self; overprintLayer.delegate = overprintProvider;
        tiledLayer.contents = nil;
        [tiledLayer setNeedsDisplay];
        overprintLayer.contents = nil;
        [overprintLayer setNeedsDisplay];
        

        // Calculate the initial zoom as the minimum zoom.
        NSRect cv = [[[self enclosingScrollView] contentView] frame];
        minZoom = [self calculateMinimumZoomForFrame:cv];
        [self setZoom:minZoom*3.0];
    } else {
        if (tiledLayer != nil) {
            tiledLayer.delegate = nil;
            [tiledLayer removeFromSuperlayer];
            
            overprintLayer.delegate = nil;
            [overprintLayer removeFromSuperlayer];
        }
    }
    
	[self setNeedsDisplay:YES];
}

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
        _printedMapLayer.hidden = NO;
        _printedMapLayer.name = @"paper";
        
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
        _innerMapLayer.bounds = tiledLayer.bounds;
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

    }
    return _printedMapLayer;
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
    [_printedMapLayer setFrame:page];
    
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
    [_printedMapScrollLayer setFrame:r];
    [self setPrintingScale:5000.0];

}

- (void)setPrintingScale:(CGFloat)printingScale {
    /*
     * We want to 1) set the frame of the inner map layers
     * and 2) set the transform of those layers so that just the right
     * amount of map (and at the correct location) is drawn within the map
     * layer.
     * The frame has to be set after the transform is calculated.
     */
    _printingScale = printingScale;
    
    // Calculate the number of map points that fit in the paper width.
    // 
    CGFloat pointsInWidth = ((orientation == NSPortraitOrientation)?paperSize.width:paperSize.height) * 100.0 * printingScale / 15000.0;
    NSLog(@"points: %f (%f)", pointsInWidth, pointsInWidth/ mapBounds.size.width);
    // Kastellegården har 38000 pts in x. 380 mm i 15000-del. Låter mycket men kartan har mycket extra så det kan nog stämma.
    // 297 mm * 100 = 297000 * 10000/15000
    // Figure out how many points that are visible with the current transform.
    _innerMapLayer.transform = tiledLayer.transform;
    CGFloat visibleWidth = _innerMapLayer.visibleRect.size.width;

    [self setPrimitiveZoom:_zoom*visibleWidth/pointsInWidth];
    
    // Justera scroll-rect så att den hamnar rätt.
    
/*
    CGRect rectOfVisibleAreaInMapCoordinates = [tiledLayer convertRect:_printedMapScrollLayer.frame fromLayer:_printedMapLayer];
    // 
    // Find a transform that takes rectOfVisibleAreaInMapCoordinates to r
    // Then set this to the transorm of the innerMapLayer and innerOverprintLayer, as well as set the frame to rectOfVisibleAreaInMapCoordinates.
    
    // Set the inner map layer
    CATransform3D sought = [[self class] transformFromRect:rectOfVisibleAreaInMapCoordinates toRect:_printedMapScrollLayer.bounds];
    _printedMapScrollLayer.sublayerTransform = sought;
        // Set the trans
*/ 
}

- (void)synchronizeInnerTransform {
    
}

- (void)showPrintedMap {
    if (tiledLayer.filters == nil || [tiledLayer.filters count] == 0) {
        tiledLayer.filters = @[[self backgroundMapFilter]];
        overprintLayer.filters = @[[self backgroundMapFilter]];
    }
    
    _innerMapLayer.transform = tiledLayer.transform;


    CABasicAnimation *unhide = [CABasicAnimation animationWithKeyPath:@"opacity"];
    unhide.fromValue = @(0.0);
    unhide.toValue = @(1.0);
    unhide.duration = 0.6f;
    [[self printedMapLayer] addAnimation:unhide forKey:nil];
    
    CABasicAnimation *b1 = [CABasicAnimation animationWithKeyPath:@"filters.skuggkarta.inputSaturation"];
    b1.fromValue = @(1.0); b1.toValue = @(0.2);
    CABasicAnimation *b2 = [CABasicAnimation animationWithKeyPath:@"filters.skuggkarta.inputBrightness"];
    b2.fromValue = @(0.0); b2.toValue = @(-0.32);
    CABasicAnimation *b3 = [CABasicAnimation animationWithKeyPath:@"filters.skuggkarta.inputContrast"];
    b3.fromValue = @(1.0); b3.toValue = @(0.62);
    CAAnimationGroup *g1 = [CAAnimationGroup animation];
    g1.removedOnCompletion = YES;
    g1.animations = @[b1,b2,b3];
    g1.duration = unhide.duration;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [tiledLayer setValue:b1.toValue forKeyPath:b1.keyPath];
    [tiledLayer setValue:b2.toValue forKeyPath:b2.keyPath];
    [tiledLayer setValue:b3.toValue forKeyPath:b3.keyPath];
    [overprintLayer setValue:b1.toValue forKeyPath:b1.keyPath];
    [overprintLayer setValue:b2.toValue forKeyPath:b2.keyPath];
    [overprintLayer setValue:b3.toValue forKeyPath:b3.keyPath];
    [CATransaction commit];
    
    [tiledLayer addAnimation:g1 forKey:nil];
    [overprintLayer addAnimation:g1 forKey:nil];
    
    [_printedMapLayer setNeedsDisplay];
   [_innerMapLayer setNeedsDisplay];
    [_innerOverprintLayer setNeedsDisplay];
}

- (void)hidePrintedMap {
    [tiledLayer setFilters:@[]];
    [overprintLayer setFilters:@[]];
    
    [[self printedMapLayer] removeFromSuperlayer];
}

#pragma mark -
#pragma mark Magnifying glass

- (CALayer *)magnifyingGlass {
	if (_magnifyingGlass == nil) {
		NSRect f = NSMakeRect(0.0, 0.0, GLASS_SIZE, GLASS_SIZE);

		_magnifyingGlass = [CALayer layer];
		[_magnifyingGlass setBounds:NSRectToCGRect(f)];
		[_magnifyingGlass setAnchorPoint:CGPointMake(0.5, 0.5)];
		[_magnifyingGlass setHidden:YES];
        CGColorRef gray = CGColorCreateGenericGray(0.2, 1.0);
		[_magnifyingGlass setShadowColor:gray];
        CGColorRelease(gray);
		[_magnifyingGlass setShadowOpacity:0.5];
		[_magnifyingGlass setShadowOffset:CGSizeMake(0.0, -3.0)];
		[_magnifyingGlass setShadowRadius:3.0];
        [_magnifyingGlass setCornerRadius:75.0];
        
        innerMagnifyingGlassLayer = [CALayer layer];
        // Set up a transform for the innerMagnifyingGlassLayer.
        [innerMagnifyingGlassLayer setCornerRadius:0.5*GLASS_SIZE];
        innerMagnifyingGlassLayer.anchorPoint = CGPointMake(0.5, 0.5);
        innerMagnifyingGlassLayer.position = CGPointMake(NSMidX(f), NSMidY(f));
        innerMagnifyingGlassLayer.bounds = NSRectToCGRect(f);
        innerMagnifyingGlassLayer.frame = innerMagnifyingGlassLayer.bounds;
        innerMagnifyingGlassLayer.name = @"magnification";
        innerMagnifyingGlassLayer.needsDisplayOnBoundsChange = YES;
        innerMagnifyingGlassLayer.masksToBounds = YES;
        innerMagnifyingGlassLayer.contents = nil;
        CGColorRef white = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
        innerMagnifyingGlassLayer.backgroundColor = white;
        CGColorRelease(white);
        innerMagnifyingGlassLayer.delegate = self;
        [_magnifyingGlass addSublayer:innerMagnifyingGlassLayer];
        [innerMagnifyingGlassLayer setNeedsDisplay];

        courseObjectShapeLayer = [CAShapeLayer layer];
        courseObjectShapeLayer.anchorPoint = CGPointMake(0.5, 0.5);
        courseObjectShapeLayer.position = CGPointMake(NSMidX(f), NSMidY(f));
        courseObjectShapeLayer.bounds = NSRectToCGRect(f);
        courseObjectShapeLayer.strokeColor = [[ASControlDescriptionView defaultOverprintColor] CGColor];
        courseObjectShapeLayer.fillColor = nil;
        courseObjectShapeLayer.lineWidth = 3.5f*1.5;
        courseObjectShapeLayer.opacity = 0.5;
        [_magnifyingGlass addSublayer:courseObjectShapeLayer];
        
	}
	return _magnifyingGlass;
}

- (void)setShowMagnifyingGlass:(BOOL)b {
    [self ensureFirstResponder];
    
    if (b == showMagnifyingGlass) return;
    
	showMagnifyingGlass = b;
	CALayer *l = [self magnifyingGlass];
	if (b) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideMagnifyingGlass:) name:NSWindowDidResignKeyNotification object:[self window]];
		[[self layer] addSublayer:l];
	} else {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:[self window]];
		[l removeFromSuperlayer];
	}
	[self updateTrackingAreas];
}

- (void)hideMagnifyingGlass:(NSNotification *)n {
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	[self magnifyingGlass].hidden = YES;
	[CATransaction commit];
}

#pragma mark -
#pragma mark Mouse tracking

- (void)updateTrackingAreas {
	[super updateTrackingAreas];
    
    NSArray *tas = [self trackingAreas];
    for (NSTrackingArea *ta in tas) {
        [self removeTrackingArea:ta];
    }
    glassTrackingArea = nil;

    // Handle the glass tracking area, which is to get mouseMoved messages for
    // the magnifying glass.
	if (self.showMagnifyingGlass) {
		glassTrackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] 
														 options:NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow
														   owner:self 
														userInfo:nil];		 
		[self addTrackingArea:glassTrackingArea];
	} else {
        // Now add tracking areas for each course object.
        [self.courseDataSource enumerateAllOverprintObjectsUsingBlock:^(id<ASOverprintObject> object) {
            // Add a tracking rect for this object.
            // Set up a userInfo object for the tracking areas. We need to remember to check that the object actually
            // exists when we get around to dealing with an event for the given tracking area.
            CGPoint positionInMap = [object position];
            CGRect r = CGRectMake(positionInMap.x - 150.0, positionInMap.y-150.0, 300.0, 300.0);
            NSRect rectInView = NSRectFromCGRect([tiledLayer convertRect:r toLayer:[self layer]]);
            NSTrackingArea *ta = [[NSTrackingArea alloc] initWithRect:rectInView options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow owner:self userInfo:@{@"object":object}];
            [self addTrackingArea:ta];
            
            // Are there affiliated digits?
        }];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent {
    if (self.showMagnifyingGlass) {
        [NSCursor hide];
        [[self magnifyingGlass] setHidden:NO];
    } else {
        if (self.state != kASMapViewDraggingCourseObject) {
            // Move our "selection" rect layer to this location.
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            dragIndicatorLayer.frame = [tiledLayer convertRect:NSRectToCGRect([[theEvent trackingArea] rect]) fromLayer:[self layer]];
            dragIndicatorLayer.cornerRadius = dragIndicatorLayer.frame.size.width*0.5;
            [CATransaction commit];
            dragIndicatorLayer.hidden = NO;
            self.draggedCourseObject = [[[theEvent trackingArea] userInfo] objectForKey:@"object"];
        }
    }
}

- (void)mouseMoved:(NSEvent *)theEvent {
	NSAssert(self.showMagnifyingGlass, @"Not showing magnifying glass?");
	NSPoint p = [theEvent locationInWindow];
    p = [self convertPoint:p fromView:nil];

	CALayer *l = [self magnifyingGlass];
	if (l.hidden) l.hidden = NO;	
	[CATransaction begin];
	[CATransaction setDisableActions:YES];

	[[self magnifyingGlass] setPosition:NSPointToCGPoint(p)];
    [innerMagnifyingGlassLayer setNeedsDisplay];
	[CATransaction commit];
}

- (void)mouseExited:(NSEvent *)theEvent {
    if (self.showMagnifyingGlass) {
        [[self magnifyingGlass] setHidden:YES];
        [NSCursor unhide];
    }
    if (self.state != kASMapViewDraggingCourseObject) {
        self.draggedCourseObject = nil;
        dragIndicatorLayer.hidden = YES;
    }
}

#pragma mark -
#pragma mark Regular mouse events

- (void)mouseDragged:(NSEvent *)theEvent {
    NSPoint eventLocationInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if (self.draggedCourseObject != nil && self.state == kASMapViewNormal) {
        self.state = kASMapViewDraggingCourseObject;
        dragIndicatorLayer.hidden = YES;
    }
    
    if (self.state == kASMapViewDraggingCourseObject) {
        CALayer *l = [self magnifyingGlass];
        if (l.hidden) l.hidden = NO;
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        [[self magnifyingGlass] setPosition:NSPointToCGPoint(eventLocationInView)];
        [innerMagnifyingGlassLayer setNeedsDisplay];
        [CATransaction commit];
        // Invalidate the overprint for this object.
        [self.overprintProvider hideOverprintObject:self.draggedCourseObject informLayer:overprintLayer];
    }
}

- (void)mouseUp:(NSEvent *)theEvent {
    NSPoint eventLocationInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];

    // Tell the overprint provider that a new control should be added at that position. Supply the symbol number from the map provider.
    //
    enum ASOverprintObjectType addingType;
    switch (self.state) {
        case kASMapViewNormal:
            if ([self.courseDataSource specificCourseSelected] && self.draggedCourseObject != nil) {
                // Add to current course.
                [self.courseDataSource appendOverprintObjectToSelectedCourse:self.draggedCourseObject];
            }
            self.draggedCourseObject = nil;
            return;
            break;
        case kASMapViewDraggingCourseObject:
            [self.draggedCourseObject setPosition:[tiledLayer convertPoint:eventLocationInView fromLayer:[self layer]]];
            [self.draggedCourseObject setSymbolNumber:[self.mapProvider symbolNumberAtPosition:self.draggedCourseObject.position]];
            [self.overprintProvider showOverprintObject:self.draggedCourseObject informLayer:overprintLayer];
            [self.overprintProvider updateOverprint];
            self.state = kASMapViewNormal;
            self.draggedCourseObject = nil;
            [self updateTrackingAreas];
            return;
            break;
        case kASMapViewAddControls:
            addingType = kASOverprintObjectControl;
            break;
        case kASMapViewAddStart:
            addingType = kASOverprintObjectStart;
            break;
        case kASMapViewAddFinish:
            addingType = kASOverprintObjectFinish;
            break;
        default:
            return;
            break;
    };
    
    NSPoint p = NSPointFromCGPoint([tiledLayer convertPoint:NSPointToCGPoint(eventLocationInView) fromLayer:[self layer]]);
    NSInteger i = [self.mapProvider symbolNumberAtPosition:p];

    [self.courseDataSource addOverprintObject:addingType atLocation:p symbolNumber:i];
    [overprintLayer setNeedsDisplay];
    [innerMagnifyingGlassLayer setNeedsDisplay];
}

#pragma mark -
#pragma mark Zooming

- (CGFloat)calculateMinimumZoomForFrame:(NSRect)frame {
    if (mapBounds.size.width == 0.0 || mapBounds.size.height == 0.0) return 0.0;
	return fmax(frame.size.height/mapBounds.size.height, frame.size.width/mapBounds.size.width);
}

- (void)frameChanged:(NSNotification *)n {
	minZoom = [self calculateMinimumZoomForFrame:[[n object] frame]];
	if (self.zoom < minZoom) [self setZoom:minZoom];
}

- (void)boundsChanged:(NSNotification *)n {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    // Track an appropriate transform for the inner paper layer.
    CGRect paper = [tiledLayer convertRect:_printedMapScrollLayer.frame fromLayer:_printedMapLayer];
    [_innerMapLayer scrollPoint:CGPointMake(paper.origin.x, paper.origin.y)];
    
    [CATransaction commit];
}

- (void)setPrimitiveZoom:(CGFloat)z2 {
    NSClipView *cv = [[self enclosingScrollView] contentView];
    NSRect v = [cv documentVisibleRect ], f;
    CGPoint midpointBefore, midpointAfter, tentativeNewOrigin, pointInMapCoordinates;
	
    midpointBefore = CGPointMake(NSMidX(v), NSMidY(v));
	pointInMapCoordinates = [tiledLayer convertPoint:midpointBefore fromLayer:[self layer]];
    
    NSRect r = NSMakeRect(0.0, 0.0, mapBounds.size.width*z2, mapBounds.size.height*z2);
    if (r.size.width == 0.0 || r.size.height == 0.0) r.size = NSMakeSize(1.0, 1.0);
    
	[self setFrame:r];
	f = [self frame];
	
	tiledLayer.transform = CATransform3DMakeScale(z2, z2, 1.0);
    overprintLayer.transform = tiledLayer.transform;
    
	midpointAfter = [tiledLayer convertPoint:pointInMapCoordinates toLayer:[self layer]];
	
	tentativeNewOrigin = CGPointMake(midpointAfter.x - 0.5*v.size.width, midpointAfter.y - 0.5*v.size.height);
	if (tentativeNewOrigin.x < 0.0) tentativeNewOrigin.x = 0.0;
	if (tentativeNewOrigin.y < 0.0) tentativeNewOrigin.y = 0.0;
	if (tentativeNewOrigin.x + v.size.width > NSMaxX(f)) tentativeNewOrigin.x = NSMaxX(f) - v.size.width;
	if (tentativeNewOrigin.y + v.size.height > NSMaxY(f)) tentativeNewOrigin.y = NSMaxY(f) - v.size.height;
    
	[cv scrollToPoint:NSPointFromCGPoint(tentativeNewOrigin)];
    
    _zoom = z2;

}

- (void)setZoom:(CGFloat)zoom {
    
    // Before we change the zoom, we need to change the anchor point, so that when we change the transform
    // it will zoom in or out around the current center point.
    //
    // Note that mapBounds is the *frame* of the view, but [self layer] has the origin at (0,0).
	// 
	// Both tiledLayer and the view have the same effective bounds. The former by using a transform,
	// and the latter by simply scaling the frame according to the zoom. We need to do it this way
	// to automatically get the scroll view to update according to
    
    // If the magnifying glass is active, we can save its position in window coordinates, and then reset that same position in window coordinates
    // afterwards.
    CGPoint magGlassPositionInWindow = CGPointMake(0.0, 0.0);
    if (self.showMagnifyingGlass) {
        magGlassPositionInWindow = [self convertPoint:NSPointFromCGPoint(self.magnifyingGlass.position) toView:nil];
    }
                                
    if (zoom > MAX_ZOOM) zoom = MAX_ZOOM;
    if (zoom < minZoom) zoom = minZoom;
    
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
    
    [self setPrimitiveZoom:zoom];
    if (self.showMagnifyingGlass) {
        [self.magnifyingGlass setPosition:NSPointToCGPoint([self convertPoint:magGlassPositionInWindow fromView:nil])];
        [innerMagnifyingGlassLayer setNeedsDisplay];
    }
	[CATransaction commit];

}

- (CGFloat)zoom {
    if (_zoom == 0.0) return 1.0;
    return _zoom;
}

- (void)magnifyWithEvent:(NSEvent *)event {
    // Disallow zooming in layout mode.
    if (self.state != kASMapViewLayout) {
        self.zoom = (1.0 + [event magnification])* self.zoom;
    }
}

#pragma mark Drawing

// CATiledLayer delegate stuff.
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    if (layer == tiledLayer || layer == _innerMapLayer) {
        [mapProvider drawLayer:layer inContext:ctx];
    } else if (layer == innerMagnifyingGlassLayer) {
        CGContextSaveGState(ctx);
       
        // Get the current position of the glass, in map coordinates.
        CGPoint p = NSPointFromCGPoint([tiledLayer convertPoint:[[self magnifyingGlass] position] fromLayer:[self layer]]);

        // The zoom of the glass is fixed, so that it covers 15 mm of map, diagonally. Since map units are 0.01 mm, this means
        // 1500 map points across.
        
        float across=1200.0;
        // Set up a transform to a 1500x1500 rect centered on p, from a rect {0,0,GLASS_SIZE,GLASS_SIZE}.
        // (assume they are both square)
        float a = GLASS_SIZE/across;
        float tx = - a * (p.x - across*0.5);
        float ty = - a * (p.y - across*0.5);
        CGAffineTransform t = CGAffineTransformMake(a, 0, 0, a, tx, ty);
        CGContextConcatCTM(ctx, t);
        CGContextSetPatternPhase(ctx, CGSizeMake(t.tx, t.ty));
        [mapProvider drawLayer:layer inContext:ctx useSecondaryTransform:YES];
        [overprintProvider drawLayer:layer inContext:ctx];
        CGContextRestoreGState(ctx);
        
    } 
}

#pragma mark -
#pragma mark State handling

- (void)setState:(enum ASMapViewUIState)s2 {
    state = s2;
    CGMutablePathRef path = NULL;
    
    if (state == kASMapViewNormal || state == kASMapViewLayout) {
        if (self.showMagnifyingGlass == YES)
            self.showMagnifyingGlass = NO;
    } else {
        if (self.showMagnifyingGlass == NO)
            self.showMagnifyingGlass = YES;
    }

    CGPoint middle = CGPointMake(90.0, 90.0);
    double z;

    path = CGPathCreateMutable();

    switch (state) {
        case kASMapViewAddControls:
            CGPathAddEllipseInRect(path, NULL, CGRectMake(45, 45, 90, 90));
            break;
        case kASMapViewAddStart:
            z = 1.5*70.0/2.0/cos(M_PI/6);
            CGPathMoveToPoint(path, NULL, middle.x, middle.y + z);
            CGPathAddLineToPoint(path, NULL, middle.x + cos(M_PI/6)*z, middle.y - sin(M_PI/6)*z);
            CGPathAddLineToPoint(path, NULL, middle.x - cos(M_PI/6)*z, middle.y - sin(M_PI/6)*z);
            CGPathCloseSubpath(path);
            break;
        case kASMapViewAddFinish:
            z = 1.5*50;
            CGPathAddEllipseInRect(path, NULL, CGRectMake(middle.x-0.5*z, middle.y-0.5*z, z, z));
            z = 1.5*70;
            CGPathAddEllipseInRect(path, NULL, CGRectMake(middle.x-0.5*z, middle.y-0.5*z, z, z));
            break;
        case kASMapViewDraggingCourseObject:
            switch ([self.draggedCourseObject objectType]) {
                case kASOverprintObjectControl:
                    CGPathAddEllipseInRect(path, NULL, CGRectMake(45, 45, 90, 90));
                    break;
                case kASOverprintObjectFinish:
                    z = 1.5*50;
                    CGPathAddEllipseInRect(path, NULL, CGRectMake(middle.x-0.5*z, middle.y-0.5*z, z, z));
                    z = 1.5*70;
                    CGPathAddEllipseInRect(path, NULL, CGRectMake(middle.x-0.5*z, middle.y-0.5*z, z, z));
                    break;
                case kASOverprintObjectStart:
                    z = 1.5*70.0/2.0/cos(M_PI/6);
                    CGPathMoveToPoint(path, NULL, middle.x, middle.y + z);
                    CGPathAddLineToPoint(path, NULL, middle.x + cos(M_PI/6)*z, middle.y - sin(M_PI/6)*z);
                    CGPathAddLineToPoint(path, NULL, middle.x - cos(M_PI/6)*z, middle.y - sin(M_PI/6)*z);
                    CGPathCloseSubpath(path);

                default:
                    break;
            }
        case kASMapViewLayout:
            // Remember the current transform.
            // Ask the layout controller for the layout for the current course.
            
            // (If there is no layout defined, the layout controller will create one).
            // Add in the printmap layer
            //
                [[[[self enclosingScrollView] superview] layer] addSublayer:[self printedMapLayer]];
                
                leftMargin = 50.0;
                rightMargin = 50.0;
                topMargin = 50.0;
                bottomMargin = 50.0;
                [self adjustPrintedMapLayerForBounds];
                CGRect paper = [tiledLayer convertRect:_printedMapScrollLayer.frame fromLayer:_printedMapLayer];
                [_innerMapLayer scrollPoint:CGPointMake(paper.origin.x, paper.origin.y)];

                [self showPrintedMap];
            break;
        default:
            break;
    }
    
    if (state != kASMapViewLayout) {
        // Remove the filter from the tiledLayer
        // Go back to the other transforms.
        [self hidePrintedMap];
    }
    
    courseObjectShapeLayer.path = path;
    CGPathRelease(path);
}

- (void)cancelOperation:(id)sender {
    [self revertToStandardMode:sender];
}

- (IBAction)revertToStandardMode:(id)sender {
    self.state = kASMapViewNormal;
}

- (IBAction)goIntoAddControlsMode:(id)sender {
    self.state = kASMapViewAddControls;
}

- (IBAction)goIntoAddStartMode:(id)sender {
    self.state = kASMapViewAddStart;
}

- (IBAction)goIntoAddFinishMode:(id)sender {
    self.state = kASMapViewAddFinish;
}

- (IBAction)enterLayoutMode:(id)sender {
    self.state = kASMapViewLayout;
}

#pragma mark -
#pragma mark Miscellaneous

- (void)overprintChanged:(NSNotification *)n {
    [overprintLayer setNeedsDisplay];
    [self setNeedsDisplay:YES];
    
    // Update tracking areas.
    [self updateTrackingAreas];
}

- (BOOL)isOpaque {
	return YES;
}

- (void)ensureFirstResponder {
    if ([[self window] firstResponder] != self) {
        [[self window] makeFirstResponder:self];
    }
}

+ (CATransform3D)transformFromRect:(CGRect)src toRect:(CGRect)dst {
    /*
                        [ 1  0  0  0 ]
     [ x  y  z  1 ]  x  [ 0  1  0  0 ]  =  [ x+1  y+2  z+3  1 ]
                        [ 0  0  1  0 ]
                        [ 1  2  3  1 ]
     */
    // There is no rotation and only x and y values, so we're looking
    // for the elements m11, m22, m41, m42.
    CATransform3D t = CATransform3DIdentity;
    
    // Lower left corner gives the following equations:
    // src.origin.x * m11 + m41 = dst.origin.x
    // src.origin.y * m22 + m42 = dst.origin.y
    
    // Upper right:
    // (src.origin.x + src.size.width)*m11 + m41 = dst.origin.x + dst.size.width
    // (src.origin.y + src.size.height)*m22 + m42 = dst.origin.y + dst.size.height
    
    // Four equations with four unknowns. Gaussian elimination:
    // (this would be so much easier with MathML comments)
    t.m11 = dst.size.width / src.size.width;
    t.m22 = dst.size.height / src.size.height;
    t.m41 = dst.origin.x - src.origin.x * t.m11;
    t.m42 = dst.origin.y - src.origin.y * t.m22;

    return t;
}


@end
