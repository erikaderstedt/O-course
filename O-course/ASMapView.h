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

enum ASMapViewUIState {
    kASMapViewNormal,
    kASMapViewAddControls,
    kASMapViewAddStart,
    kASMapViewAddFinish
};

@interface ASMapView : NSView {
	id <ASMapProvider> mapProvider;
    id <ASOverprintProvider> overprintProvider;
    
	CGRect mapBounds;
	
	BOOL showMagnifyingGlass;
	CALayer *_magnifyingGlass;
    CALayer *innerMagnifyingGlassLayer;
    CAShapeLayer *courseObjectShapeLayer;
	NSTrackingArea *glassTrackingArea;
    
    CATiledLayer *tiledLayer;
    CATiledLayer *overprintLayer;
    CGFloat _zoom;
	CGFloat minZoom;
    
    enum ASMapViewUIState state;
}
@property(nonatomic,retain) id <ASMapProvider> mapProvider;
@property(nonatomic,retain) id <ASOverprintProvider> overprintProvider;
@property(nonatomic,assign) BOOL showMagnifyingGlass;
@property(nonatomic,assign) CGFloat zoom;
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
