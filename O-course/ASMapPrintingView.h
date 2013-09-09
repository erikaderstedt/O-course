//
//  ASMapPrintingView.h
//  O-course
//
//  Created by Erik Aderstedt on 2013-09-09.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASMapProvider.h"

@class ASMapView;

@interface ASMapPrintingView : NSView {
    ASMapView *baseView;
    
}
@property (strong) id <ASMapProvider> mapProvider;
@property (strong) id <ASOverprintProvider> overprintProvider;

- (id)initWithBaseView:(ASMapView *)_baseView;
- (CGAffineTransform)patternTransform;

@end
