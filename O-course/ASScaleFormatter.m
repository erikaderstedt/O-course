//
//  ASScaleFormatter.m
//  O-course
//
//  Created by Erik Aderstedt on 2013-08-26.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import "ASScaleFormatter.h"

@implementation ASScaleFormatter

- (id)init {
    self = [super init];
    if (self) {
        [self configure];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self configure];
    }
    return self;
}

- (void)configure {
    [self setFormatterBehavior:NSNumberFormatterBehavior10_0];
    [self setThousandSeparator:@" "];
    [self setPositiveFormat:@"#,##0"];
}

- (NSString *)stringForObjectValue:(id)obj {
    if (obj == nil) return nil;

    return [NSString stringWithFormat:@"1:%@", [super stringForObjectValue:obj]];
}

- (BOOL)getObjectValue:(out id *)anObject forString:(NSString *)aString range:(inout NSRange *)rangep error:(out NSError **)error {
    if ([aString length] < 7) return NO;
    
    return [super getObjectValue:anObject forString:[aString substringFromIndex:2] range:rangep error:error];
}

@end

@implementation ASScaleTransformer

- (id)init {
    if (self = [super init]) {
        formatter = [[ASScaleFormatter alloc] init];
    }
    return self;
}

+ (Class)transformedValueClass { return [NSString class]; }
- (id)transformedValue:(id)value {
    return [formatter stringForObjectValue:value];
}

- (id)reverseTransformedValue:(id)value {
    id ob;
    [formatter getObjectValue:&ob forString:value errorDescription:nil];
    return ob;
}

@end
