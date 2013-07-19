//
//  CourseObject.m
//  O-course
//
//  Created by Erik Aderstedt on 2012-05-24.
//  Copyright (c) 2012 Aderstedt Software AB. All rights reserved.
//

#import "OverprintObject.h"

@implementation OverprintObject

- (enum ASOverprintObjectType)objectType {
    enum ASOverprintObjectType objectType = (enum ASOverprintObjectType)[[self valueForKey:@"type"] integerValue];
    return objectType;
}

- (void)setObjectType:(enum ASOverprintObjectType)_type {
    [self setValue:@(_type) forKey:@"type"];
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    [self setPrimitiveValue:[NSDate date] forKey:@"added"];
    if ([[[self entity] name] isEqualToString:@"Control"]) {
        [self setPrimitiveValue:@(kASFeatureNone) forKey:@"controlFeature"];
        [self setPrimitiveValue:@(kASFeatureNotSpecified) forKey:@"whichOfAnySimilarFeature"];
    }
}

@dynamic added;
@dynamic position_x;
@dynamic position_y;
@dynamic angle;
@dynamic distance;
@dynamic data;

- (CGPoint)position {
    return CGPointMake([[self valueForKey:@"position_x"] doubleValue], [[self valueForKey:@"position_y"] doubleValue]);
}

- (void)setPosition:(CGPoint)p {
    [self setValue:@(p.x) forKey:@"position_x"];
    [self setValue:@(p.y) forKey:@"position_y"];
}

- (NSInteger)controlNumber {
    return -1;
}

@dynamic controlCode;
@dynamic whichOfAnySimilarFeature;
@dynamic controlFeature;
@dynamic appearanceOrSecondControlFeature;
@dynamic dimensions;
@dynamic combinationSymbol;
@dynamic locationOfTheControlFlag;
@dynamic otherInformation;

- (void)assignNextFreeControlCode {
    // Excluded numbers : 66, 68, 89, 99,
    // Don't do this in awakeFromInsert.
    NSAssert([self objectType] == kASOverprintObjectControl, @"Assigning control code to something that is not a control");
    
    self.controlCode = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"OverprintObject"];
    [request setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"controlCode" ascending:YES]]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"controlCode != nil"]];
    
    NSArray *otherControls = [[self managedObjectContext] executeFetchRequest:request error:nil];
    NSInteger freeCode = 31;
    for (OverprintObject *control in otherControls) {
        if ([control.controlCode integerValue] != freeCode) {
            break;
        } else {
            freeCode = [control.controlCode integerValue] + 1;
        }
        if (freeCode == 66 ||
            freeCode == 68 ||
            freeCode == 89 ||
            freeCode == 99) {
            freeCode ++;
        }
    }
    self.controlCode = @(freeCode);
}

- (void)setSymbolNumber:(NSInteger)symbolNumber {
    enum ASFeature feature = kASFeatureNone;
    
    // Set the control feature. This is based on the table in Control-Descriptions.pdf
    switch (symbolNumber) {
         /* 1xx */
        case 106:
            // This feature could also be kASFeatureQuarry, as the symbol number is ambiguous.
            feature = kASFeatureEarthBank;
            break;
        case 107:
        case 108:
            feature = kASFeatureEarthWall;
            break;
        case 109:
            feature = kASFeatureErosionGully;
            break;
        case 110:
            feature = kASFeatureSmallErosionGully;
            break;
        case 111:
        case 101:
            feature = kASFeatureHill;
            break;
        case 112:
        case 113:
            feature = kASFeatureKnoll;
            break;
        case 114:
            feature = kASFeatureDepression;
            break;
        case 115:
            feature = kASFeatureSmallDepression;
            break;
        case 116:
        case 204:
            feature = kASFeaturePit;
            break;
        case 117:
            feature = kASFeatureBrokenGround;
            break;
            
        /* Symbols 2xx */
        case 207:
        case 206:
            feature = kASFeatureBoulder;
            break;
        case 203:
        case 201:
            feature = kASFeatureCliff;
            break;
        case 202:
            feature = kASFeatureRockPillar;
            break;
        case 205:
            feature = kASFeatureCave;
            break;
        case 208:
            feature = kASFeatureBoulderField;
            break;
        case 209:
            feature = kASFeatureBoulderCluster;
            break;
        case 210:
            feature = kASFeatureStonyGround;
            break;
        case 212:
            feature = kASFeatureBareRock;
            break;
            
        default:
            break;
    }
    
    self.controlFeature = @(feature);
}

- (NSInteger)symbolNumber {
    return [self.controlFeature integerValue];
}

- (void)addToCourse:(NSManagedObject *)course {
    [[self valueForKey:@"course"] addObject:course];
}

@end
