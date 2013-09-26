//
//  Graphic.h
//  O-course
//
//  Created by Erik Aderstedt on 2013-09-26.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ASGraphicItem.h"

@class Layout;

// Note that the position is in user space points for the current paper ({0,0}, {595,842} for A4).

@interface Graphic : NSManagedObject <ASGraphicItem>

@property (nonatomic) double position_x;
@property (nonatomic) double position_y;
@property (nonatomic) double z_index;
@property (nonatomic, retain) id image;
@property (nonatomic, retain) Layout *layout;
@property (nonatomic) double scale;
@property (nonatomic) BOOL whiteBackground;
@property (nonatomic) CGPoint position;
@property (nonatomic) CGRect frame;

@end
