//
//  ASMapView.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-04.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASMapView.h"
#import "ASControlDescriptionView.h"
#import "ASLayoutController.h"
#import "ASMapView+Layout.h"

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
    [tiledLayer removeObserver:self forKeyPath:@"transform"];
    [_innerMapLayer removeObserver:self forKeyPath:@"transform"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:[self enclosingScrollView]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ASOverprintChanged" object:nil];
    [self teardownLayoutNotificationObserving];
    
	[_magnifyingGlass removeFromSuperlayer];
    [_printedMapLayer removeFromSuperlayer];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [[self.layoutConfigurationView superview] removeConstraints:[[self.layoutConfigurationView superview] constraints]];

    NSView *v1 = [self enclosingScrollView];
    NSView *v2 = self.layoutConfigurationView;
    NSView *cv = [self.layoutConfigurationView superview];
    [cv addConstraint:[NSLayoutConstraint constraintWithItem:v1 attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:cv attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-1.0]];
    [cv addConstraint:[NSLayoutConstraint constraintWithItem:v1 attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cv attribute:NSLayoutAttributeBottom multiplier:1.0 constant:1.0]];
    [cv addConstraint:[NSLayoutConstraint constraintWithItem:v1 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:cv attribute:NSLayoutAttributeTop multiplier:1.0 constant:-1.0]];
    [cv addConstraint:[NSLayoutConstraint constraintWithItem:v1 attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:v2 attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [cv addConstraint:[NSLayoutConstraint constraintWithItem:v2 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:LAYOUT_VIEW_WIDTH]];
    self.theConstraint = [NSLayoutConstraint constraintWithItem:v1 attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:cv attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
    [cv addConstraint:self.theConstraint];
    
    [cv addConstraint:[NSLayoutConstraint constraintWithItem:v2 attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cv attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    [cv addConstraint:[NSLayoutConstraint constraintWithItem:v2 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:cv attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    
    
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged:) name:NSViewFrameDidChangeNotification object:[self enclosingScrollView]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(overprintChanged:) name:@"ASOverprintChanged" object:nil];
    [self setupLayoutNotificationObserving];
    
    [[self enclosingScrollView] setBackgroundColor:[NSColor whiteColor]];
    
    [self setupTiledLayer];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
    return YES;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"transform"]) {
        if (context == (__bridge void *)(_innerMapLayer) && self.state == kASMapViewLayout) {
/*            _innerOverprintLayer.transform = _innerMapLayer.transform;
            tiledLayer.transform = _innerMapLayer.transform;
            overprintLayer.transform = tiledLayer.transform;*/
        } else if (context == (__bridge void *)(tiledLayer)) {
            overprintLayer.transform = tiledLayer.transform;
            if (self.state == kASMapViewLayout) {
                _innerMapLayer.transform = tiledLayer.transform;
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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

        [tiledLayer addObserver:self forKeyPath:@"transform" options:0 context:(__bridge void *)(tiledLayer)];
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
        
        [self.layoutController setSymbolList:[self.mapProvider symbolList]];

        // Calculate the initial zoom as the minimum zoom.
        NSRect cv = [[[self enclosingScrollView] contentView] frame];
        if (cv.size.width > 0) {
            minZoom = [self calculateMinimumZoomForFrame:cv];
            [self setZoom:minZoom*3.0];
        }
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

- (void)showPrintedMap {
    NSClipView *vc = [[self enclosingScrollView] contentView];
    [vc setPostsBoundsChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsChanged:) name:NSViewBoundsDidChangeNotification object:vc];

    if (tiledLayer.filters == nil || [tiledLayer.filters count] == 0) {
        tiledLayer.filters = @[[self backgroundMapFilter]];
        overprintLayer.filters = @[[self backgroundMapFilter]];
    }
    
    CABasicAnimation *unhide = [CABasicAnimation animationWithKeyPath:@"hidden"];
    unhide.fromValue = @(YES);
    unhide.toValue = @(NO);
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
    [[self printedMapLayer] setHidden:NO];
    [CATransaction commit];
    
    [tiledLayer addAnimation:g1 forKey:nil];
    [overprintLayer addAnimation:g1 forKey:nil];
    
    [self.layoutController willAppear];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        if ([context respondsToSelector:@selector(setAllowsImplicitAnimation:)]) {
            [context setAllowsImplicitAnimation:YES];
        }
        [self.theConstraint setConstant:-LAYOUT_VIEW_WIDTH];
        [self layoutSubtreeIfNeeded];
    } completionHandler:^{
    }];
    
}

- (void)hidePrintedMap {
    NSClipView *vc = [[self enclosingScrollView] contentView];
    [vc setPostsBoundsChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:vc];

    [tiledLayer setFilters:@[]];
    [overprintLayer setFilters:@[]];
    
//    [[self printedMapLayer] setHidden:YES];
    [[self printedMapLayer] removeFromSuperlayer];
    
    if ([self.mapProvider supportsHiddenSymbolNumbers]) {
        [self.mapProvider setHiddenSymbolNumbers:NULL count:0];
        [tiledLayer setNeedsDisplayInRect:[tiledLayer bounds]];
    }
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        if ([context respondsToSelector:@selector(setAllowsImplicitAnimation:)]) {
            [context setAllowsImplicitAnimation:YES];
        }
        [self.theConstraint setConstant:0.0];
        [self layoutSubtreeIfNeeded];
    } completionHandler:^{
    }];
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
//    [NSCursor unhide];
    
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
														 options:NSTrackingMouseMoved/* | NSTrackingCursorUpdate */| NSTrackingActiveInKeyWindow
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
    if (self.state != kASMapViewDraggingCourseObject) {
        self.draggedCourseObject = nil;
        dragIndicatorLayer.hidden = YES;
    }
}
/*
- (void)cursorUpdate:(NSEvent *)event {
    if (self.showMagnifyingGlass) {
        [NSCursor hide];
    }
}
*/
#pragma mark -
#pragma mark Regular mouse events

- (void)mouseDown:(NSEvent *)theEvent {
    if (self.state == kASMapViewLayout) {
        NSPoint eventLocationInView = [[[self window] contentView] convertPoint:[theEvent locationInWindow] fromView:nil];
        if (CGRectContainsPoint([[self printedMapLayer] frame],eventLocationInView)) {
            draggingPaperMap = YES;
            return;
        }
    }
    draggingPaperMap = NO;
}

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
    if (self.state == kASMapViewLayout && draggingPaperMap) {
        // Move the paper map.
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [self dragPaperMapBasedOnEvent:theEvent];
        [self synchronizePaperWithBackground];
        [CATransaction commit];
    }
}

- (void)mouseUp:(NSEvent *)theEvent {
    NSPoint eventLocationInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSPoint p = NSPointFromCGPoint([tiledLayer convertPoint:NSPointToCGPoint(eventLocationInView) fromLayer:[self layer]]);
    NSInteger i = [self.mapProvider symbolNumberAtPosition:p];
    // Tell the overprint provider that a new control should be added at that position. Supply the symbol number from the map provider.
    //
    enum ASOverprintObjectType addingType;
    switch (self.state) {
        case kASMapViewNormal:
            if ([self.courseDataSource specificCourseSelected] && self.draggedCourseObject != nil) {
                // Add to current course.
                if ([theEvent modifierFlags] & NSShiftKeyMask) {
                    [self.courseDataSource removeLastOccurrenceOfOverprintObjectFromSelectedCourse:self.draggedCourseObject];
                } else {
                    [self.courseDataSource appendOverprintObjectToSelectedCourse:self.draggedCourseObject];
                }
            }
            self.draggedCourseObject = nil;
            return;
            break;
        case kASMapViewDraggingCourseObject:
            NSLog(@"location %@", NSStringFromPoint(p));
            [self.draggedCourseObject setPosition:p];
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
    
    NSLog(@"location %@", NSStringFromPoint(p));
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

    if (self.state == kASMapViewLayout) {
        NSLog(@"frame width now %f", [self frame].size.width);
        // This is the point where we should adjust the scale etc., because now we know the size of the paper.
        [self adjustPrintedMapLayerForBounds];
        [self ensureCorrectScaleAndLocation];
        //CGPoint p = [self centerOfMap];
        //[self centerMapOnCoordinates:p];
    } else {
        CGFloat oMinZoom = minZoom;
        minZoom = [self calculateMinimumZoomForFrame:[[n object] frame]];
        if (oMinZoom == 0.0) {
            [self setZoom:minZoom*3.0];
        }
        if (self.zoom < minZoom) [self setZoom:minZoom]; else [self setZoom:self.zoom];
        
    }
}

- (void)boundsChanged:(NSNotification *)n {
    NSAssert(self.state == kASMapViewLayout, @"Bounds notification even though we aren't in layout mode");
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    [self synchronizeBackgroundWithPaper];
//    [self synchronizePaperWithBackground];
    
    [CATransaction commit];
}

- (void)setPrimitiveZoom:(CGFloat)z2 {
    NSLog(@"Setting primitive zoom %f", z2);
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
	midpointAfter = [tiledLayer convertPoint:pointInMapCoordinates toLayer:[self layer]];
	
	tentativeNewOrigin = CGPointMake(midpointAfter.x - 0.5*v.size.width, midpointAfter.y - 0.5*v.size.height);
	if (tentativeNewOrigin.x < 0.0) tentativeNewOrigin.x = 0.0;
	if (tentativeNewOrigin.y < 0.0) tentativeNewOrigin.y = 0.0;
	if (tentativeNewOrigin.x + v.size.width > NSMaxX(f)) tentativeNewOrigin.x = NSMaxX(f) - v.size.width;
	if (tentativeNewOrigin.y + v.size.height > NSMaxY(f)) tentativeNewOrigin.y = NSMaxY(f) - v.size.height;
    
	[cv scrollToPoint:NSPointFromCGPoint(tentativeNewOrigin)];
    if (self.state == kASMapViewLayout) {
        [self synchronizePaperWithBackground];
        [_innerMapLayer setNeedsDisplayInRect:[_innerMapLayer bounds]];
    }
    
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
        
    } else if (layer == _printedMapLayer && frameColor != NULL) {
        [self drawPaperFrameInContext:ctx];
    }
}

#pragma mark -
#pragma mark State handling

- (void)setState:(enum ASMapViewUIState)s2 {
    enum ASMapViewUIState oldState = state;
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
            break;
        case kASMapViewLayout:
        {
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
            
            [self showPrintedMap];
        }
            break;
        default:
            break;
    }
    
    if (oldState == kASMapViewLayout && state != kASMapViewLayout) {
        [self recordNewLayoutCenter];
        
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
    [self.layoutController willDisappear];
    
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
    // Make first responder to ensure that we get 'cancelOperation'
    
    [[self window] makeFirstResponder:self];
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
