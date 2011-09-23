//
//  Project.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-09-23.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "Project.h"

@implementation Project

@dynamic map;

- (void)awakeFromInsert {
    [super awakeFromInsert];
    [self addObserver:self forKeyPath:@"map" options:0 context:self];    
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
    [self addObserver:self forKeyPath:@"map" options:0 context:self];    
}

- (void)willTurnIntoFault {
    [self removeObserver:self forKeyPath:@"map"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == self) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ASMapChangedNotification" object:[self managedObjectContext]];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
