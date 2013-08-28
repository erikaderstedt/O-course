//
//  Layout.m
//  O-course
//
//  Created by Erik Aderstedt on 2013-08-25.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import "Layout.h"
#import "Course.h"
#import "Project.h"


@implementation Layout

@dynamic mapInset;
@dynamic frameVisible;
@dynamic frameColor;
@dynamic hiddenObjectTypes;
@dynamic name;
@dynamic paperType;
@dynamic scale;
@dynamic courses;
@dynamic project;

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    self.frameColor = [NSColor colorWithDeviceRed:0.875 green:0.649 blue:0.223 alpha:1.000];
}

+ (instancetype)defaultLayoutInContext:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Layout"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"default == YES"]];
    [fetchRequest setFetchLimit:1];
    
    NSError *error = nil;
    NSArray *objs = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if ([objs count] > 0) {
        return objs[0];
    }
    
    return nil;
}

- (NSString *)paperName {
    enum ASLayoutPaperType sz = (enum ASLayoutPaperType)[self.paperType integerValue];
    if (sz == kASLayoutPaperTypeA3) return @"A3";
    return @"A4";
}

+ (NSSet *)keyPathsForValuesAffectingPaperSize { return [NSSet setWithObjects:@"paperType",@"orientation", nil]; }
- (NSSize)paperSize {
    enum ASLayoutPaperType type = (enum ASLayoutPaperType)[self.paperType integerValue];
    NSSize sz;
    
    if (type == kASLayoutPaperTypeA3) {
        sz = NSMakeSize(297, 420);
    } else {
        sz = NSMakeSize(210, 297);
    }

    return sz;
}

- (BOOL)symbolNumberIsVisible:(NSInteger)number {
    const int32_t *hidden_symbols = (const int32_t *)[self.hiddenObjectTypes bytes];
    if (hidden_symbols == NULL) return YES;
    
    int32_t num_hidden_symbols = hidden_symbols[0];
    for (int32_t i = 1; i <= num_hidden_symbols; i++) {
        if (number == hidden_symbols[i]) return NO;
    }
    return YES;
}

- (int32_t)allSymbolNumbersVisibleIn:(NSArray *)list {
    const int32_t *hidden_symbols = (const int32_t *)[self.hiddenObjectTypes bytes];
    if (hidden_symbols == NULL) return YES;

    int32_t num_hidden_symbols = hidden_symbols[0], i, j;
    BOOL allVisible = YES, allHidden = YES;
    for (NSDictionary *item in list) {
        j = (int32_t)[[item valueForKey:@"number"] integerValue];
        for (i = 1; i <= num_hidden_symbols && hidden_symbols[i] != j; i++);
        allHidden = allHidden && (i <= num_hidden_symbols);
        allVisible = allVisible && (i > num_hidden_symbols);
    }
    
    if (allHidden) return NSOffState;
    if (allVisible) return NSOnState;
    return NSMixedState;
}

- (void)modifySymbolList:(NSArray *)list toBeVisible:(BOOL)visible {
    for (NSDictionary *dictionary in list) {
        NSInteger i = [[dictionary valueForKey:@"number"] integerValue];
        [self modifySymbolNumber:i toBeVisible:visible];
    }
}

- (void)modifySymbolNumber:(NSInteger)number toBeVisible:(BOOL)visible {
    
    int32_t *modifiedHiddenSymbols;
    const int32_t *hidden_symbols = (const int32_t *)[self.hiddenObjectTypes bytes];
    int32_t defaultValue[1];
    if (hidden_symbols == NULL) {
        defaultValue[0] = 0;
        hidden_symbols = (const int32_t *)defaultValue;
    }
    
    if (visible) {
        // Remove if there.
        modifiedHiddenSymbols = calloc(hidden_symbols[0] + 1, sizeof(int32_t));
        
        int32_t num_hidden_symbols = hidden_symbols[0], i, j;
        for (i = 1, j = 1; j <= num_hidden_symbols; j++) {
            if (number != hidden_symbols[j]) {
                modifiedHiddenSymbols[i] = hidden_symbols[j];
                i++;
            }
        }
        modifiedHiddenSymbols[0] = i-1;
    } else {
        // Add if not already there.
        if ([self symbolNumberIsVisible:number]) {
            modifiedHiddenSymbols = calloc(hidden_symbols[0] + 2, sizeof(int32_t));
            memcpy(modifiedHiddenSymbols, hidden_symbols, (hidden_symbols[0] + 1)*sizeof(int32_t) );
            modifiedHiddenSymbols[modifiedHiddenSymbols[0]+1] = (int32_t)number;
            modifiedHiddenSymbols[0]++;
        } else {
            return;
        }
    }
    
    self.hiddenObjectTypes = [NSData dataWithBytes:modifiedHiddenSymbols length:(modifiedHiddenSymbols[0]+1)*sizeof(int32_t)];
    free(modifiedHiddenSymbols);
}

- (const int32_t *)hiddenObjects:(size_t *)count {
    const int32_t *hidden_symbols = (const int32_t *)[self.hiddenObjectTypes bytes];
    if (hidden_symbols == NULL) {
        *count = 0;
        return NULL;
    };
//    for (int32_t j = 1; j <= hidden_symbols[0]; j++) printf("%d ", hidden_symbols[j]);
    *count = hidden_symbols[0];
    return hidden_symbols+1;
}

@end