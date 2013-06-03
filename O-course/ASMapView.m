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

@implementation ASMapView

@synthesize mapProvider;
@synthesize showMagnifyingGlass;

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
	[mapProvider release];
	
	[_magnifyingGlass removeFromSuperlayer];
	[_magnifyingGlass release];
	
	[super dealloc];
}

- (void)awakeFromNib {
	[self setPostsFrameChangedNotifications:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged:) name:NSViewFrameDidChangeNotification object:[self enclosingScrollView]];
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
		[_magnifyingGlass setShadowColor:CGColorCreateGenericGray(0.2, 1.0)];
		[_magnifyingGlass setShadowOpacity:0.5];
		[_magnifyingGlass setShadowOffset:CGSizeMake(0.0, -3.0)];
		[_magnifyingGlass setShadowRadius:3.0];
        [_magnifyingGlass setCornerRadius:75.0];
		[_magnifyingGlass retain];
        
        innerMagnifyingGlassLayer = [CALayer layer];
        // Set up a transform for the innerMagnifyingGlassLayer.
        [innerMagnifyingGlassLayer setCornerRadius:0.5*GLASS_SIZE];
        innerMagnifyingGlassLayer.anchorPoint = CGPointMake(0.5, 0.5);
        innerMagnifyingGlassLayer.position = CGPointMake(NSMidX(f), NSMidY(f));
        innerMagnifyingGlassLayer.bounds = NSRectToCGRect(f);
        innerMagnifyingGlassLayer.frame = innerMagnifyingGlassLayer.bounds;
        innerMagnifyingGlassLayer.name = @"magnification";
//        innerMagnifyingGlassLayer.filters = @[lozenge];
        innerMagnifyingGlassLayer.needsDisplayOnBoundsChange = YES;
        innerMagnifyingGlassLayer.masksToBounds = YES;
        innerMagnifyingGlassLayer.contents = nil;
        innerMagnifyingGlassLayer.backgroundColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
/*        innerMagnifyingGlassLayer.tileSize = CGSizeMake(512.0, 512.0);
        
        innerMagnifyingGlassLayer.levelsOfDetail = 7;
        innerMagnifyingGlassLayer.levelsOfDetailBias = 2; */
        innerMagnifyingGlassLayer.delegate = self;
        [_magnifyingGlass addSublayer:innerMagnifyingGlassLayer];
        [innerMagnifyingGlassLayer setNeedsDisplay];

        courseObjectShapeLayer = [CAShapeLayer layer];
        courseObjectShapeLayer.anchorPoint = CGPointMake(0.5, 0.5);
        courseObjectShapeLayer.position = CGPointMake(NSMidX(f), NSMidY(f));
        courseObjectShapeLayer.bounds = NSRectToCGRect(f);
        courseObjectShapeLayer.strokeColor = [[ASControlDescriptionView defaultOverprintColor] CGColor];
        courseObjectShapeLayer.lineWidth = 3.5f;
        
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

- (void)updateTrackingAreas {
	[super updateTrackingAreas];
	[self removeTrackingArea:glassTrackingArea];
	if (self.showMagnifyingGlass) {
		if (glassTrackingArea != nil) {
			[glassTrackingArea release];
		}
		glassTrackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] 
														 options:NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow 
														   owner:self 
														userInfo:nil];		 
		[self addTrackingArea:glassTrackingArea];
	} else {
		if (glassTrackingArea != nil) {
			[glassTrackingArea release];
			glassTrackingArea = nil;
		}
	}
}

- (IBAction)toggleMagnifyingGlass:(id)sender {
	self.showMagnifyingGlass = !self.showMagnifyingGlass;
}

- (void)mouseEntered:(NSEvent *)theEvent {
	[NSCursor hide];
}

- (void)mouseMoved:(NSEvent *)theEvent {
	NSAssert(self.showMagnifyingGlass, @"Not showing magnifying glass?");
	NSPoint p = [theEvent locationInWindow];
    p = [self convertPoint:p fromView:nil];
//	p = [self convertPointFromBase:p];

	CALayer *l = [self magnifyingGlass];
	if (l.hidden) l.hidden = NO;	
	[CATransaction begin];
	[CATransaction setDisableActions:YES];

	[[self magnifyingGlass] setPosition:NSPointToCGPoint(p)];
    [innerMagnifyingGlassLayer setNeedsDisplay];
	[CATransaction commit];
}

- (void)mouseExited:(NSEvent *)theEvent {
	[[self magnifyingGlass] setHidden:YES];
	[NSCursor unhide];
}

#pragma mark -

- (void)ensureFirstResponder {
    if ([[self window] firstResponder] != self) {
        [[self window] makeFirstResponder:self];
    }
}

- (void)mouseDown:(NSEvent *)theEvent {
    NSPoint p = [theEvent locationInWindow];
    p = [self convertPoint:p fromView:nil];
    p = NSPointFromCGPoint([tiledLayer convertPoint:NSPointToCGPoint(p) fromLayer:[self layer]]);

    NSInteger i = [mapProvider symbolNumberAtPosition:p];
    if (i != NSNotFound) {
        NSLog(@"Clicked symbol number: %ld", i);
    } else {
        NSLog(@"No symbol there.");
    }
}

- (void)cancelOperation:(id)sender {
    [self revertToStandardMode:sender];
}

- (IBAction)revertToStandardMode:(id)sender {
    self.state = kASMapViewNormal;
    self.showMagnifyingGlass = NO;
}

- (IBAction)goIntoAddControlsMode:(id)sender {
    self.state = kASMapViewAddControls;
    self.showMagnifyingGlass = YES;
}

- (IBAction)goIntoAddStartMode:(id)sender {
    self.state = kASMapViewAddStart;
    self.showMagnifyingGlass = YES;
}

- (IBAction)goIntoAddFinishMode:(id)sender {
    self.state = kASMapViewAddFinish;
    self.showMagnifyingGlass = YES;
}

- (BOOL)isOpaque {
	return YES;
}

- (CGFloat)calculateMinimumZoomForFrame:(NSRect)frame {
    if (mapBounds.size.width == 0.0 || mapBounds.size.height == 0.0) return 0.0;
	return fmax(frame.size.height/mapBounds.size.height, frame.size.width/mapBounds.size.width);
}

- (void)frameChanged:(NSNotification *)n {
	minZoom = [self calculateMinimumZoomForFrame:[[n object] frame]];
	if (self.zoom < minZoom) [self setZoom:minZoom];
	
//	[[[self enclosingScrollView] contentView] viewFrameChanged:n];
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
	midpointAfter = [tiledLayer convertPoint:pointInMapCoordinates toLayer:[self layer]];
	
	tentativeNewOrigin = CGPointMake(midpointAfter.x - 0.5*v.size.width, midpointAfter.y - 0.5*v.size.height);
	if (tentativeNewOrigin.x < 0.0) tentativeNewOrigin.x = 0.0;
	if (tentativeNewOrigin.y < 0.0) tentativeNewOrigin.y = 0.0;
	if (tentativeNewOrigin.x + v.size.width > NSMaxX(f)) tentativeNewOrigin.x = NSMaxX(f) - v.size.width;
	if (tentativeNewOrigin.y + v.size.height > NSMaxY(f)) tentativeNewOrigin.y = NSMaxY(f) - v.size.height;
	[cv scrollToPoint:NSPointFromCGPoint(tentativeNewOrigin)];
	[CATransaction commit];

	[tiledLayer performSelector:@selector(setNeedsDisplay) withObject:nil afterDelay:1.0];
    _zoom = zoom;
}

- (CGFloat)zoom {
    if (_zoom == 0.0) return 1.0;
    return _zoom;
}

- (void)magnifyWithEvent:(NSEvent *)event {
    self.zoom = (1.0 + [event magnification])* self.zoom;
}

- (void)mapLoaded {
    
    if (self.mapProvider != nil) {
        if (tiledLayer == nil) {

            tiledLayer = [CATiledLayer layer];
            tiledLayer.name = @"tiled";
            tiledLayer.needsDisplayOnBoundsChange = YES;
            tiledLayer.backgroundColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
            tiledLayer.tileSize = CGSizeMake(512.0, 512.0);
            
            tiledLayer.levelsOfDetail = 7;
            tiledLayer.levelsOfDetailBias = 2;
            [tiledLayer retain];
            
            tiledLayer.anchorPoint = CGPointMake(0.0, 0.0);
            tiledLayer.position = CGPointMake(0.0, 0.0);
            
        }
        mapBounds = [self.mapProvider mapBounds];
        tiledLayer.bounds = mapBounds;
        tiledLayer.delegate = self;
        [[self layer] addSublayer:tiledLayer];
        tiledLayer.contents = nil;
        [tiledLayer setNeedsDisplay];
        
        // Calculate the initial zoom as the minimum zoom.
        NSRect cv = [[[self enclosingScrollView] contentView] frame];
        minZoom = [self calculateMinimumZoomForFrame:cv];
        [self setZoom:minZoom*3.0];
    } else {
        if (tiledLayer != nil) {
            tiledLayer.delegate = nil;
            [tiledLayer removeFromSuperlayer];
        }
    }
    
	[self setNeedsDisplay:YES];
}

static CGFloat randomFloat()
{
	return random() / (double)LONG_MAX;
}

// CATiledLayer delegate stuff.
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    if (layer == tiledLayer) {
        [mapProvider drawLayer:layer inContext:ctx];
        [overprintProvider drawLayer:layer inContext:ctx];
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

@end
