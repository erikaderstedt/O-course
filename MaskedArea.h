//
//  MaskedArea.h
//  O-course
//
//  Created by Erik Aderstedt on 2013-09-26.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ASMaskedAreaItem.h"

@class Layout;

@interface MaskedArea : NSManagedObject <ASMaskedAreaItem>

@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) Layout *layout;

@end
