//
//  ASMapView.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-04.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASMapProvider.h"
#import <QuartzCore/QuartzCore.h>

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


@interface ASMapView : NSView {
	id <ASMapProvider> mapProvider;
	double zoom, minZoom;
	NSAffineTransform *currentTransform;
	NSRect mapBounds;

	NSMutableArray *imageCaches;
	NSImage *cachedImage;
	NSRect rectForCachedImage;
	
	BOOL showMagnifyingGlass;
	CALayer *_magnifyingGlass;
	CIFilter *lozenge;
	CIFilter *mask;
	NSTrackingArea *glassTrackingArea;
}
@property(nonatomic,retain) id <ASMapProvider> mapProvider;
@property(nonatomic,retain) NSImage *cachedImage;
@property(nonatomic,assign) BOOL showMagnifyingGlass;
@property(nonatomic,assign) double zoom;
@property(nonatomic,retain) NSAffineTransform *currentTransform;

- (CALayer *)magnifyingGlass;
- (IBAction)toggleMagnifyingGlass:(id)sender;

@end
