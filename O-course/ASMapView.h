//
//  ASMapView.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-04.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASMapProvider.h"
#import "ASOverprintProvider.h"
#import <QuartzCore/QuartzCore.h>

#define MAX_ZOOM 1.5

// The map view has several heavy tasks.
// 1. Show the background map.
//	  The ASMapProvider
// 2. Show control description

// Zooming / panning / resizing
// Maintain a cache of rendered images:
//	- image
//	- NSRect
// If the cache doesn't cover everything that we were asked to draw, we start rendering those areas
// and invalidate that rect (in map coordinates) when rendering completes.
// Always retain the original render (as re-rendered when the frame changes). This is used to render empty areas
// until a suitable re-render can be obtained.
//
// When a cached image has been used, bump it up to position 1 in the cached array. If we run low on memory
// we can start trimming from the end.
// 
// When a map has been loaded, we set our frame according to the default zoom.
// Then invalidate the view to start rendering.
// 
// Zooming: after rendering finishes, if the magnifying glass is active, invalidate the
// magnifying glass image and re-render a 10x magnified image of the current bounds.
// Zooming invalidates the normal cache of rendered images.

enum ASMapViewUIState {
    kASMapViewNormal,
    kASMapViewAddControls,
    kASMapViewAddStart,
    kASMapViewAddFinish
};

@interface ASMapView : NSView {
	id <ASMapProvider> mapProvider;
    id <ASOverprintProvider> overprintProvider;
    
	NSAffineTransform *currentTransform;
	CGRect mapBounds;

	NSMutableArray *imageCaches;
	NSImage *cachedImage;
	NSRect rectForCachedImage;
	
	BOOL showMagnifyingGlass;
	CALayer *_magnifyingGlass;
	CIFilter *lozenge;
	CIFilter *mask;
	NSTrackingArea *glassTrackingArea;
    
    CATiledLayer *tiledLayer;
    CGFloat _zoom;
	CGFloat minZoom;
    
    NSButton *chooseButton;
}
@property(nonatomic,retain) id <ASMapProvider> mapProvider;
@property(nonatomic,retain) NSImage *cachedImage;
@property(nonatomic,assign) BOOL showMagnifyingGlass;
@property(nonatomic,assign) CGFloat zoom;
@property(nonatomic,retain) NSAffineTransform *currentTransform;
@property(nonatomic,retain) IBOutlet NSButton *chooseButton;
@property(nonatomic,assign) enum ASMapViewUIState state;

- (IBAction)revertToStandardMode:(id)sender;
- (IBAction)goIntoAddControlsMode:(id)sender;
- (IBAction)goIntoAddStartMode:(id)sender;
- (IBAction)goIntoAddFinishMode:(id)sender;

- (void)mapLoaded;
- (CGFloat)calculateMinimumZoomForFrame:(NSRect)frame;

- (CALayer *)magnifyingGlass;
- (IBAction)toggleMagnifyingGlass:(id)sender;

@end
