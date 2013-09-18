//
//  CourseObject.m
//  O-course
//
//  Created by Erik Aderstedt on 2012-05-24.
//  Copyright (c) 2012 Aderstedt Software AB. All rights reserved.
//

#import "OverprintObject.h"
#import "Course.h"
#import "Project.h"

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
    
    NSArray *affectedCourses = [self valueForKeyPath:@"courseObjects.@distinctUnionOfObjects.course"];
    for (Course *course in affectedCourses) {
        [course recalculateControlNumberPositions];
    }    
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
        if ([control objectType] != kASOverprintObjectControl) continue;
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
            
        /* Symbols 3xx */
        case 301:
        case 304:
            feature = kASFeatureLake;
            break;
        case 302:
            feature = kASFeaturePond;
            break;
        case 303:
            feature = kASFeatureWaterhole;
            break;
        case 305:
        case 306:
            feature = kASFeatureStream;
            break;
        case 307:
            feature = kASFeatureDitch;
            break;
        case 308:
            feature = kASFeatureNarrowMarch;
            break;
        case 309:
        case 310:
        case 311:
            feature = kASFeatureMarch;
            break;
        case 312:
            feature = kASFeatureWell;
            break;
        case 313:
            feature = kASFeatureSpring;
            break;
            
        /* Symbols 4xx */
        case 401:
        case 403:
            feature = kASFeatureOpenLand;
            break;
        case 402:
        case 404:
            feature = kASFeatureSemiOpenLand;
            break;

        /* Symbols 5xx */
        case 501:
        case 502:
        case 503:
        case 504:
            feature = kASFeatureRoad;
            break;
        case 505:
        case 506:
        case 507:
            feature = kASFeatureTrack;
            break;
        case 508:
        case 509:
            feature = kASFeatureRide;
            break;
        case 512:
            feature = kASFeatureBridge;
            break;
        case 516:
        case 517:
            feature = kASFeaturePowerLine;
            break;
        case 518:
            feature = kASFeatureTunnel;
            break;
        case 519:
        case 521:
            feature = kASFeatureStoneWall;
            break;
        case 520:
            feature = kASFeatureStoneWall;
            self.appearanceOrSecondControlFeature = @(kASAppearanceRuined);
            break;
        case 522:
        case 524:
            feature = kASFeatureFence;
            break;
        case 523:
            feature = kASFeatureFence;
            self.appearanceOrSecondControlFeature = @(kASAppearanceRuined);
            break;
        case 525:
            feature = kASFeatureCrossingPoint;
            break;
        case 527:
        case 526:
            feature = kASFeatureBuilding;
            break;
        case 529:
            feature = kASFeaturePavedArea;
            break;
        case 530:
            feature = kASFeatureRuin;
            break;
        case 533:
        case 534:
            feature = kASFeaturePipeline;
            break;
        case 535:
            feature = kASFeatureTower;
            break;
        case 536:
            feature = kASFeatureShootingPlatform;
            break;
        case 537:
            feature = kASFeatureCairn;
            break;
        case 538:
            feature = kASFeatureFodderRack;
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

- (CGRect)frame {
    CGPoint p = [self position];
    // TODO: Adjust frame based on object type.
    return CGRectMake(p.x - 325.0, p.y - 325.0, 650.0, 650.0);
}

- (CGPoint)controlCodePosition {
    CGPoint p = [Course controlNumberPositionBasedOnObjectPosition:[self position] angle:0.75*M_PI];
    return p;
}


+ (CGPoint)averagePositionOfOverprintObjectsInContext:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"OverprintObject"];
    [fr setPredicate:[NSPredicate predicateWithFormat:@"type == %@ || type == %@ || type == %@", @(kASOverprintObjectControl), @(kASOverprintObjectFinish), @(kASOverprintObjectStart)]];
    NSArray *overprintObjects = [managedObjectContext executeFetchRequest:fr error:nil];
    if ([overprintObjects count] == 0) {
        return [[Project projectInManagedObjectContext:managedObjectContext] centerPosition];
    }
    CGFloat fx = 0, fy = 0;
    NSInteger i = 0;
    CGPoint p;
    for (OverprintObject *object in overprintObjects) {
        p = [object position];
        fx += p.x; fy += p.y; i++;
    }
    
    NSAssert(i > 0, @"What?");
    fx /= i; fy /= i;
    
    return CGPointMake(fx, fy);
}

@end
