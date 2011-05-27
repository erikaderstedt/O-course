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
	NSLog(@"mouse down");
}

- (BOOL)isOpaque {
	return YES;
}

- (CGFloat)calculateMinimumZoomForFrame:(NSRect)frame {
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
                                
	NSClipView *cv = [[self enclosingScrollView] contentView];
    NSRect v = [cv documentVisibleRect ], f;
    CGPoint midpointBefore, midpointAfter, tentativeNewOrigin, pointInMapCoordinates;
	CGFloat oldWidth = v.size.width;
	
    midpointBefore = CGPointMake(NSMidX(v), NSMidY(v));
	pointInMapCoordinates = [tiledLayer convertPoint:midpointBefore fromLayer:[self layer]];
	
    if (zoom > 3.0) zoom = 3.0;
    if (zoom < minZoom) zoom = minZoom;
    
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	[self setFrame:NSMakeRect(0.0, 0.0, mapBounds.size.width*zoom, mapBounds.size.height*zoom)];
	tiledLayer.transform = CATransform3DMakeScale(zoom, zoom, 1.0);
	midpointAfter = [tiledLayer convertPoint:pointInMapCoordinates toLayer:[self layer]];
	
	tentativeNewOrigin = CGPointMake(midpointAfter.x - 0.5*v.size.width, midpointAfter.y - 0.5*v.size.height);
	if (tentativeNewOrigin.x < 0.0) tentativeNewOrigin.x = 0.0;
	if (tentativeNewOrigin.y < 0.0) tentativeNewOrigin.y = 0.0;
	if (tentativeNewOrigin.x + v.size.width > NSMaxX(f)) tentativeNewOrigin.x = NSMaxX(f) - v.size.width;
	if (tentativeNewOrigin.y + v.size.height > NSMaxY(f)) tentativeNewOrigin.y = NSMaxY(f) - v.size.height;
	
	[cv scrollToPoint:tentativeNewOrigin];
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

- (void)mapLoaded {
	 // Reset zoom.
	mapBounds = [mapProvider mapBounds];

    // 1. Scale map bounds according to the zoom.
    // 2. Assign that as the view frame.
    // 3. Set the tiled layer bounds to the map bounds.
    // 4. Assign 
//    [self setFrame:mapBounds]; // Adjust for zoom.
//    [[[self enclosingScrollView] contentView] viewFrameChanged:[NSNotification notificationWithName:NSViewFrameDidChangeNotification object:self userInfo:nil]];
    
    tiledLayer = [CATiledLayer layer];
//    [tiledLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
 //   [tiledLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
 //   [tiledLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY]];
 //   [tiledLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY]];
    tiledLayer.delegate = self;
    tiledLayer.name = @"tiled";
    tiledLayer.needsDisplayOnBoundsChange = YES;
    tiledLayer.backgroundColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
    
    tiledLayer.levelsOfDetail = 15;
    tiledLayer.levelsOfDetailBias = 2;
    [tiledLayer retain];
    
    tiledLayer.anchorPoint = CGPointMake(0.0, 0.0);
    tiledLayer.bounds = mapBounds;
	tiledLayer.position = CGPointMake(0.0, 0.0);
//    tiledLayer.position = CGPointMake(mapBounds.size.width*0.5, mapBounds.size.height*0.5);

 //   [[self layer] setLayoutManager:[CAConstraintLayoutManager layoutManager]];
    [[self layer] addSublayer:tiledLayer];
 //  [[self layer] layoutSublayers];
    
	// Calculate the initial zoom as the minimum zoom.
	minZoom = [self calculateMinimumZoomForFrame:[self frame]];
    [self setZoom:minZoom*3.0];

    
    [self setNeedsDisplay:YES];
}
/*
- (void)setZoom:(double)z {
	// Calculate a new frame for us.
	zoom = z;

	[imageCaches removeAllObjects];
	NSRect r = NSMakeRect(0.0, 0.0, mapBounds.size.width*z, mapBounds.size.height * z);
	
	NSAffineTransform *at = [NSAffineTransform transform];
	
    NSAffineTransformStruct ts;
	
	ts.m12 = 0.0; ts.m21 = 0.0;	
	ts.tX = - NSMinX(mapBounds)*z;
	ts.tY = - NSMinY(mapBounds)*z;
	ts.m11 = z; ts.m22 = z;
	[at setTransformStruct:ts];
	self.currentTransform = at;
	
	[self setFrame:NSIntegralRect(r)];
//	[self setNeedsDisplay:YES];
}
	*/
/*
- (void)setVisibleMapBounds:(NSRect)r {
	NSSize b = [self bounds].size, ratios, v = r;
	ratios = NSMakeSize(r.size.width / b.width, r.size.height / b.height);
	if (ratios.height > ratios.width) {
		// map is taller than the window.
		v.size.height = v.size.width * ratios.height / ratios.width;
		v.origin.y += 0.5*(r.size.height - v.size.height);
	} else if (ratios.height < ratios.width) {
		v.size.width = v.size.height * ratios.width / ratios.height;
		v.origin.x + = 0.5*(r.size.width - v.size.width);
	}
	[mapProvider beginRenderingMapWithSize:b fromSourceRect:visibleMapBounds whenDone:^(NSImage *i) {
		[self performSelectorOnMainThread:@selector(setCachedImage:) withObject:i waitUntilDone:YES];
		_visibleMapBounds = v;
		[self setNeedsDisplay:YES];
	}];
}

- (void)visibleMapBounds {
	return _visibleMapBounds;
}*/
/*

- (void)setFrameSize:(NSSize)newSize {
	[super setFrameSize:newSize];
	[mapProvider beginRenderingMapWithPixelsPerMeter:_pixelsPerMeter fromSourceRect:mapBounds whenDone:^(NSImage *i) {
		[self performSelectorOnMainThread:@selector(setCachedImage:) withObject:i waitUntilDone:YES];
		[self setNeedsDisplay:YES];
	}];
}
*/

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

// these methods would be better implemented by taking into account the scale
// instead of always moving 10 on way or the other
/*
- (BOOL)acceptsFirstResponder {
    return YES;
}*/
/*
- (void)moveRight:(id)sender {
    tiledLayer.position = CGPointMake(tiledLayer.position.x - 10.0f, 
                                      tiledLayer.position.y);
}

- (void)moveLeft:(id)sender {
    tiledLayer.position = CGPointMake(tiledLayer.position.x + 10.0f,
                                      tiledLayer.position.y);
}

- (void)moveUp:(id)sender {
    tiledLayer.position = CGPointMake(tiledLayer.position.x, 
                                      tiledLayer.position.y - 10.0f);
}

- (void)moveDown:(id)sender {
    tiledLayer.position = CGPointMake(tiledLayer.position.x, 
                                      tiledLayer.position.y + 10.0f);
}*/

// CATiledLayer delegate stuff.
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    if (layer == tiledLayer) {
        //       NSLog(@"Thread: %d", [NSThread isMainThread]);
//        CGPoint p = layer.frame.origin;
//        CGAffineTransform at;
//        CGRect r = CGContextGetClipBoundingBox(ctx);

//        at = CGAffineTransformIdentity;
//        at = CGAffineTransformMakeScale(-1.0, -1.0);
       // at = CGAffineTransformTranslate(at, p.x,p.y);
//        at = CGAffineTransformScale(at, 0.5, 0.5);
//        CGContextSaveGState(ctx);
//        CGContextConcatCTM(ctx, at);
        [mapProvider drawLayer:layer inContext:ctx];
        
//        CGContextRestoreGState(ctx);
    }
}

@end
