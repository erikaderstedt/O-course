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

@implementation ASMapView

@synthesize mapProvider, overprintProvider;
@synthesize showMagnifyingGlass;
@synthesize courseDataSource;
@synthesize state=state;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_zoom = 1.0;
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		_zoom = 1.0;
	}
	return self;
}

- (void)dealloc {
	[_magnifyingGlass removeFromSuperlayer];
}

- (void)awakeFromNib {
	[self setPostsFrameChangedNotifications:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged:) name:NSViewFrameDidChangeNotification object:[self enclosingScrollView]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(overprintChanged:) name:@"ASOverprintChanged" object:nil];
    
    [[self enclosingScrollView] setBackgroundColor:[NSColor whiteColor]];
}

#pragma mark -
#pragma mark Map loading

- (void)mapLoaded {
    
    if (self.mapProvider != nil) {
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
        }
        mapBounds = [self.mapProvider mapBounds];
        tiledLayer.bounds = mapBounds; overprintLayer.bounds = mapBounds;
        tiledLayer.delegate = self; overprintLayer.delegate = overprintProvider;
        [[self layer] addSublayer:tiledLayer]; [[self layer] addSublayer:overprintLayer];
        tiledLayer.contents = nil;
        [tiledLayer setNeedsDisplay];
        overprintLayer.contents = nil;
        [overprintLayer setNeedsDisplay];
        
        [tiledLayer addSublayer:dragIndicatorLayer];
        
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

- (IBAction)toggleMagnifyingGlass:(id)sender {
	self.showMagnifyingGlass = !self.showMagnifyingGlass;
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
        [self.courseDataSource enumerateCourseObjectsUsingBlock:^(id<ASCourseObject> object, BOOL inSelectedCourse) {
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
/*
- (void)mouseDown:(NSEvent *)theEvent {
//    dragged = NO;
    NSPoint eventLocationInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    if (self.state == kASMapViewNormal && self.draggedCourseObject != nil) {
        self.state = kASMapViewDraggingCourseObject;
        
    }

}
*/
- (void)mouseDragged:(NSEvent *)theEvent {
//    dragged = YES;
    NSPoint eventLocationInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if (self.draggedCourseObject != nil && self.state == kASMapViewNormal) {
        self.state = kASMapViewDraggingCourseObject;
        dragIndicatorLayer.hidden = YES;
    }
    
    
    if (self.state == kASMapViewDraggingCourseObject) {
        // Invalidate the overprint for this object.
        // Change the location of the dragged object.
        // Invalidate the overprint for this object.
        // (Move the dragIndicatorLayer to the new position.)
    }
    
/*
    CATransform3D transform = tiledLayer.transform;
    CGRect r = CGRectMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds), fabs([theEvent deltaX]), fabs([theEvent deltaY]));
    r = [tiledLayer convertRect:r fromLayer:[self layer]];
    transform = CATransform3DTranslate(transform, r.size.width*SIGN_OF([theEvent deltaX]), -r.size.height*SIGN_OF([theEvent deltaY]), 0);
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    tiledLayer.transform = transform;
    overprintLayer.transform = transform;
    if (self.showMagnifyingGlass) {
        // It's hidden, but we do this anyway.
        [[self magnifyingGlass] setPosition:NSPointToCGPoint(p)];
    }
    [CATransaction commit];*/

}

- (void)mouseUp:(NSEvent *)theEvent {
    NSLog(@"up");
    NSPoint eventLocationInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];

    // Tell the overprint provider that a new control should be added at that position. Supply the symbol number from the map provider.
    //
    enum ASCourseObjectType addingType;
    switch (self.state) {
        case kASMapViewNormal:
            return;
            break;
        case kASMapViewDraggingCourseObject:
            self.state = kASMapViewNormal;
            [self updateTrackingAreas];
            return;
            break;
        case kASMapViewAddControls:
            addingType = kASCourseObjectControl;
            break;
        case kASMapViewAddStart:
            addingType = kASCourseObjectStart;
            break;
        case kASMapViewAddFinish:
            addingType = kASCourseObjectFinish;
            break;
        default:
            return;
            break;
    };
    
    NSPoint p = NSPointFromCGPoint([tiledLayer convertPoint:NSPointToCGPoint(eventLocationInView) fromLayer:[self layer]]);
    NSInteger i = [self.mapProvider symbolNumberAtPosition:p];

    [self.courseDataSource addCourseObject:addingType atLocation:p symbolNumber:i];
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
                                
	NSClipView *cv = [[self enclosingScrollView] contentView];
    NSRect v = [cv documentVisibleRect ], f;
    CGPoint midpointBefore, midpointAfter, tentativeNewOrigin, pointInMapCoordinates;
	
    if (zoom > MAX_ZOOM) zoom = MAX_ZOOM;
    if (zoom < minZoom) zoom = minZoom;
    
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
    
	midpointBefore = CGPointMake(NSMidX(v), NSMidY(v));
	pointInMapCoordinates = [tiledLayer convertPoint:midpointBefore fromLayer:[self layer]];

    NSRect r = NSMakeRect(0.0, 0.0, mapBounds.size.width*zoom, mapBounds.size.height*zoom);
    if (r.size.width == 0.0 || r.size.height == 0.0) r.size = NSMakeSize(1.0, 1.0);
    
	[self setFrame:r];
	f = [self frame];
	
	tiledLayer.transform = CATransform3DMakeScale(zoom, zoom, 1.0);
    overprintLayer.transform = tiledLayer.transform;
    
	midpointAfter = [tiledLayer convertPoint:pointInMapCoordinates toLayer:[self layer]];
	
	tentativeNewOrigin = CGPointMake(midpointAfter.x - 0.5*v.size.width, midpointAfter.y - 0.5*v.size.height);
	if (tentativeNewOrigin.x < 0.0) tentativeNewOrigin.x = 0.0;
	if (tentativeNewOrigin.y < 0.0) tentativeNewOrigin.y = 0.0;
	if (tentativeNewOrigin.x + v.size.width > NSMaxX(f)) tentativeNewOrigin.x = NSMaxX(f) - v.size.width;
	if (tentativeNewOrigin.y + v.size.height > NSMaxY(f)) tentativeNewOrigin.y = NSMaxY(f) - v.size.height;
	[cv scrollToPoint:NSPointFromCGPoint(tentativeNewOrigin)];
    if (self.showMagnifyingGlass) {
        [self.magnifyingGlass setPosition:NSPointToCGPoint([self convertPoint:magGlassPositionInWindow fromView:nil])];
        [innerMagnifyingGlassLayer setNeedsDisplay];
    }
	[CATransaction commit];

    
    _zoom = zoom;
}

- (CGFloat)zoom {
    if (_zoom == 0.0) return 1.0;
    return _zoom;
}

- (void)magnifyWithEvent:(NSEvent *)event {
    self.zoom = (1.0 + [event magnification])* self.zoom;
}

#pragma mark Drawing

// CATiledLayer delegate stuff.
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    if (layer == tiledLayer) {
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
    
    if (state == kASMapViewNormal || state == kASMapViewDraggingCourseObject) {
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
        default:
            break;
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


@end
