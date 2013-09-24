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
    BOOL classNameOnBack;
}
@property (strong) id <ASMapProvider> mapProvider;

- (id)initWithBaseView:(ASMapView *)_baseView;
- (CGAffineTransform)patternTransform;

@end
