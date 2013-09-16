//
//  ASMapView.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-04.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASMapProvider.h"
#import "ASCourseObject.h"
#import <QuartzCore/QuartzCore.h>

#define MAX_ZOOM 1.5
#define GLASS_SIZE 180.0
#define ACROSS_GLASS 1200.0

// The map view has several heavy tasks.
// 1. Show the background map.
//	  The ASMapProvider
// 2. Show control description

enum ASMapViewUIState {
    kASMapViewNormal,
    kASMapViewDraggingCourseObject,
    kASMapViewAddControls,
    kASMapViewAddStart,
    kASMapViewAddFinish,
    kASMapViewLayout
};

@class ASLayoutController;
@class ASControlDescriptionView;

@interface ASMapView : NSView {
    
	CGRect mapBounds;
    BOOL dragged;
	
	BOOL showMagnifyingGlass;
	CALayer *_magnifyingGlass;
    CALayer *innerMagnifyingGlassLayer;
    CAShapeLayer *courseObjectShapeLayer;
	NSTrackingArea *glassTrackingArea;
    
    CATiledLayer *tiledLayer;
    CATiledLayer *overprintLayer;
    CALayer *dragIndicatorLayer;
    CGFloat _zoom;
	CGFloat minZoom;
    
    CAScrollLayer *_printedMapScrollLayer;
    CATiledLayer *_innerMapLayer;
    CATiledLayer *_innerOverprintLayer;
    CALayer *_printedMapLayer;
    CIFilter *_backgroundMapFilter;
    CALayer *_controlDescriptionLayer;
    
    CGColorRef _frameColor;
    NSString *eventTitle;
    CTLineRef eventDetails;
    CGFloat _printingScale;
    BOOL draggingPaperMap;
    CGSize paperOffset;
    CGRect uninsetFrameForScrollMapLayer;
    
    // The margins given are for the portrait orientation.
    CGFloat topMargin;
    CGFloat leftMargin;
    CGFloat rightMargin;
    CGFloat bottomMargin;
    
    enum ASMapViewUIState state;
}
@property(nonatomic,strong) id <ASMapProvider> mapProvider;
@property(nonatomic,strong) id <ASOverprintProvider> overprintProvider;
@property(nonatomic,weak) IBOutlet id <ASCourseDataSource> courseDataSource;
@property(nonatomic,strong) id <ASOverprintObject> draggedCourseObject;
@property(nonatomic,assign) BOOL showMagnifyingGlass;
@property(nonatomic,assign) CGFloat zoom;
@property(nonatomic,assign) enum ASMapViewUIState state;
@property(nonatomic,weak) IBOutlet NSView *layoutConfigurationView;
@property(weak) IBOutlet ASLayoutController *layoutController;
@property(weak) NSLayoutConstraint *theConstraint;
@property(nonatomic,weak) IBOutlet NSView *controlDescriptionContainerView;
@property(nonatomic,weak) IBOutlet ASControlDescriptionView *controlDescriptionView;

@property(assign) BOOL frameVisible;
@property(assign) CGSize paperSize; // in points, in portrait orientation
@property(assign) NSPrintingOrientation orientation;
@property CGColorRef frameColor;

- (IBAction)revertToStandardMode:(id)sender;
- (IBAction)goIntoAddControlsMode:(id)sender;
- (IBAction)goIntoAddStartMode:(id)sender;
- (IBAction)goIntoAddFinishMode:(id)sender;
- (IBAction)enterLayoutMode:(id)sender;

- (void)mapLoaded;
- (CGFloat)calculateMinimumZoomForFrame:(NSRect)frame;
- (void)setPrimitiveZoom:(CGFloat)_pzoom;

- (CALayer *)magnifyingGlass;

+ (CATransform3D)transformFromRect:(CGRect)src toRect:(CGRect)dst;

@end
