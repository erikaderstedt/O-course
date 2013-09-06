//
//  ASLayoutController.h
//  O-course
//
//  Created by Erik Aderstedt on 2013-08-26.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ASScaleFormatter;

extern NSString *const ASLayoutWillChange;
extern NSString *const ASLayoutChanged;
extern NSString *const ASLayoutVisibleItemsChanged;
extern NSString *const ASLayoutScaleChanged;
extern NSString *const ASLayoutOrientationChanged;
extern NSString *const ASLayoutFrameColorChanged;
extern NSString *const ASLayoutFrameChanged;
extern NSString *const ASLayoutEventDetailsChanged;

@interface ASLayoutController : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, strong) IBOutlet NSArrayController *layouts;
@property (weak) IBOutlet NSTableView *layoutsTable;
@property (weak) IBOutlet NSOutlineView *visibleSymbolsTable;
@property (weak) NSArray *symbolList;
@property (assign) BOOL observing;

@property (strong) NSArray *landForms;
@property (strong) NSArray *rocksAndCliffs;
@property (strong) NSArray *waterAndMarsh;
@property (strong) NSArray *vegetation;
@property (strong) NSArray *manMade;
@property (assign) BOOL recognizesSymbols;

- (void)willAppear;
- (void)willDisappear;
- (void)setSymbolList:(NSArray *)symbolList;

- (const int32_t *)hiddenObjects:(size_t *)count;
- (NSInteger)scale;
- (NSPrintingOrientation)orientation;
- (NSSize)paperSize;
- (CGColorRef)frameColor;
- (BOOL)frameVisible;
- (CGPoint)layoutCenterPosition;
- (void)writeLayoutCenterPosition:(CGPoint)centerPosition;

@end
