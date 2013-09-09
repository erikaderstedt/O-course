//
//  ASMapPrintingView.h
//  O-course
//
//  Created by Erik Aderstedt on 2013-09-09.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ASMapView;

@interface ASMapPrintingView : NSView {
    ASMapView *baseView;
}

- (id)initWithBaseView:(ASMapView *)_baseView;

@end
