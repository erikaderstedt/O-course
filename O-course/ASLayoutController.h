//
//  ASLayoutController.h
//  O-course
//
//  Created by Erik Aderstedt on 2013-08-26.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASMaskedAreaItem.h"
#import "ASGraphicItem.h"

@class ASScaleFormatter;
@class Layout;

extern NSString *const ASLayoutWillChange;
extern NSString *const ASLayoutChanged;
extern NSString *const ASLayoutVisibleItemsChanged;
extern NSString *const ASLayoutScaleChanged;
extern NSString *const ASLayoutOrientationChanged;
extern NSString *const ASLayoutFrameColorChanged;
extern NSString *const ASLayoutFrameChanged;
extern NSString *const ASLayoutEventDetailsChanged;
extern NSString *const ASLayoutDecorChanged;

@interface ASLayoutController : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, strong) IBOutlet NSArrayController *layouts;
@property (weak) IBOutlet NSTableView *layoutsTable;
@property (weak) IBOutlet NSOutlineView *visibleSymbolsTable;
@property (weak) IBOutlet NSMatrix *paperMatrix;
@property (weak) IBOutlet NSMatrix *orientationMatrix;
@property (weak) IBOutlet NSMatrix *controlDescriptionMatrix;

@property (weak) NSArray *symbolList;
@property (assign) BOOL observing;

@property (strong) NSArray *landForms;
@property (strong) NSArray *rocksAndCliffs;
@property (strong) NSArray *waterAndMarsh;
@property (strong) NSArray *vegetation;
@property (strong) NSArray *manMade;
@property (strong) NSArray *technical;
@property (assign) BOOL recognizesSymbols;
@property (nonatomic,retain) NSArray *maskedAreaVertices;

- (void)willAppear;
- (void)willDisappear;
- (void)setSymbolList:(NSArray *)symbolList;

- (const int32_t *)hiddenObjects:(size_t *)count;
- (NSInteger)scale;
- (NSPrintingOrientation)orientation;
- (NSSize)paperSize;
- (NSString *)paperName;
- (CGColorRef)frameColor;
- (BOOL)frameVisible;
- (CGPoint)layoutCenterPosition;
- (void)writeLayoutCenterPosition:(CGPoint)centerPosition;
- (NSString *)eventDescription;
- (enum ASLayoutControlDescriptionLocation)controlDescriptionLocation;
- (BOOL)showControlDescription;
- (BOOL)printClassNameOnBack;
- (Layout *)selectedLayout;
- (void)addImage:(NSImage *)image atLocation:(CGPoint)p;
- (NSArray *)graphicsInLayout;
- (NSArray *)masksInLayout;
- (id <ASMaskedAreaItem>)startNewMaskedAreaAt:(CGPoint)location;
- (void)removeGraphicItem:(id <ASGraphicItem>)item;
- (void)removeMaskedArea:(id <ASMaskedAreaItem>)item;
- (void)cacheMaskedAreas;

- (IBAction)duplicateLayout:(id)sender;

@end
