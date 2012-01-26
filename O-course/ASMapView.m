//
//  ASMapView.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-04.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASMapView.h"
#define LogR(t,z) NSLog(@"%@: {{%.0f, %.0f}, {%.0f, %.0f}}", t, z.origin.x, z.origin.y, z.size.width, z.size.height)


@implementation ASMapView

@synthesize mapProvider;
@synthesize cachedImage;
@synthesize showMagnifyingGlass;
@synthesize currentTransform;
@synthesize chooseButton;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		imageCaches = [[NSMutableArray alloc] initWithCapacity:20];
		_zoom = 1.0;
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		imageCaches = [[NSMutableArray alloc] initWithCapacity:20];
		_zoom = 1.0;
	}
	return self;
}

- (void)dealloc {
	[mapProvider release];
	[cachedImage release];
	
	[_magnifyingGlass removeFromSuperlayer];
	[_magnifyingGlass release];
	[lozenge release];
	[mask release];
    [chooseButton release];
	
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
		mask = [CIFilter filterWithName:@"CISourceInCompositing"];
		[mask setDefaults];
		
		NSImage *i = [[NSImage alloc] init];
		NSRect f = NSMakeRect(0.0, 0.0, 150.0, 150.0);
		[i setSize:f.size];
		[i lockFocus];
		[[NSColor clearColor] set];
		[NSBezierPath fillRect:f];
		[[NSColor whiteColor] set];
		NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:f];
		[circle fill];
		[i unlockFocus];
		
		[mask setValue:[CIImage imageWithCGImage:[i CGImageForProposedRect:&f context:[NSGraphicsContext currentContext] hints:nil]]
				forKey:@"inputBackgroundImage"];
		
		[i release];
		/*
		lozenge = [CIFilter filterWithName:@"CIGlassLozenge"];
		[lozenge setDefaults];
		[lozenge setValue:[CIVector vectorWithX:NSMidX(f) Y:NSMidY(f)] forKey:@"inputPoint0"];
		[lozenge setValue:[CIVector vectorWithX:NSMidX(f) Y:NSMidY(f)] forKey:@"inputPoint1"];
		[lozenge setValue:[NSNumber numberWithFloat:f.size.width*0.5] forKey:@"inputRadius"];
		[lozenge setValue:[NSNumber numberWithFloat:1.04] forKey:@"inputRefraction"];
		[lozenge retain]; */
		[mask retain];
		
		_magnifyingGlass = [CALayer layer];
		[_magnifyingGlass setBackgroundColor:CGColorCreateGenericRGB(0.3, 0.3, 1.0, 0.6)];
		
		[_magnifyingGlass setBounds:NSRectToCGRect(f)];
		[_magnifyingGlass setAnchorPoint:CGPointMake(0.5, 0.5)];
		[_magnifyingGlass setHidden:YES];
		[_magnifyingGlass setFilters:[NSArray arrayWithObjects:mask, lozenge, nil]];
		[_magnifyingGlass setShadowColor:CGColorCreateGenericGray(0.2, 1.0)];
		[_magnifyingGlass setShadowOpacity:0.5];
		[_magnifyingGlass setShadowOffset:CGSizeMake(0.0, -3.0)];
		[_magnifyingGlass setShadowRadius:3.0];
		[_magnifyingGlass retain];
		
		
		CALayer *bezel = [CALayer layer];
		bezel.bounds = _magnifyingGlass.bounds;
		bezel.anchorPoint = CGPointMake(0.0, 0.0);
		bezel.position = CGPointMake(0.0, 0.0);
		i = [NSImage imageNamed:@"compass bezel.png"];
		[bezel setContents:(id)[i CGImageForProposedRect:NULL context:nil hints:nil]];
		[_magnifyingGlass addSublayer:bezel];
	}
	return _magnifyingGlass;
}

- (void)setShowMagnifyingGlass:(BOOL)b {
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
	p = [self convertPointFromBase:p];

	CALayer *l = [self magnifyingGlass];
	if (l.hidden) l.hidden = NO;	
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	[[self magnifyingGlass] setPosition:NSPointToCGPoint(p)];
	[CATransaction commit];
}

- (void)mouseExited:(NSEvent *)theEvent {
	[[self magnifyingGlass] setHidden:YES];
	[NSCursor unhide];
}

#pragma mark -

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
        [[self chooseButton] setHidden:YES];
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
        tiledLayer.delegate = mapProvider;
        [[self layer] addSublayer:tiledLayer];
        tiledLayer.contents = nil;
        [tiledLayer setNeedsDisplay];
        
        // Calculate the initial zoom as the minimum zoom.
        NSRect cv = [[[self enclosingScrollView] contentView] frame];
        minZoom = [self calculateMinimumZoomForFrame:cv];
        [self setZoom:minZoom*3.0];
    } else {
        [[self chooseButton] setHidden:NO];
        if (tiledLayer != nil) {
            tiledLayer.delegate = nil;
            [tiledLayer removeFromSuperlayer];
        }
    }
    
	[self setNeedsDisplay:YES];
}

- (NSRect)convertRectFromMapCoordinates:(NSRect)r {
	NSPoint p = r.origin;
	NSSize s = r.size;
	p = [self.currentTransform transformPoint:p];
	s = [self.currentTransform transformSize:s];
	return NSMakeRect(p.x, p.y, s.width, s.height);
}

- (NSRect)convertRectToMapCoordinates:(NSRect)r {
	NSAffineTransform *at = [[self.currentTransform copy] autorelease];
	[at invert];
	NSPoint p = r.origin;
	NSSize s = r.size;
	p = [at transformPoint:p];
	s = [at transformSize:s];
	return NSMakeRect(p.x, p.y, s.width, s.height);
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
    }
}

@end
