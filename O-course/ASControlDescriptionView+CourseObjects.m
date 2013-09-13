//
//  ASControlDescriptionView+CourseObjects.m
//  O-course
//
//  Created by Erik Aderstedt on 2012-05-25.
//  Copyright (c) 2012 Aderstedt Software AB. All rights reserved.
//

#import "ASControlDescriptionView+CourseObjects.h"
#import "ASControlDescriptionProvider.h"
#import "OverprintObject.h"

#define SYMBOL_SIZE 64
#define SQRT2   0.7
#define ARROW_FRACTION (0.8)
#define THICK_LINE  (2.0)
#define THIN_LINE   (1.0)

@implementation ASControlDescriptionView (CourseObjects)

- (NSArray *)createPathsForColumn:(enum ASControlDescriptionColumn)column
                         withValue:(NSNumber *)value 
                        atPosition:(CGPoint)p 
                          withSize:(CGFloat)sz {
    // Centered around the midpoint.
    CGFloat s = 0.75*0.5*sz/SYMBOL_SIZE;
    CGAffineTransform at = CGAffineTransformMakeScale(s,s);
    at = CGAffineTransformTranslate(at, p.x/s, p.y/s);
    switch (column) {
        case kASWhichOfAnySimilarFeature:
            return [self createPathsForWhichOfAnySimilarFeatureWithValue:value transform:&at];
            break;
        case kASFeature:
        case kASAppearanceOrSecondaryFeature:
            return [self createPathsForFeatureOrAppearance:value transform:&at];
            break;
            
        default:
            break;
    }
    return NULL;
}

- (NSArray *)supportedValuesForColumn:(enum ASControlDescriptionColumn)column {
    NSArray *values = @[];
    switch (column) {
        case kASWhichOfAnySimilarFeature:
            values =  @[@(kASFeatureNotSpecified), @(kASFeatureNorth),
                        @(kASFeatureNorthEast), @(kASFeatureEast),
                        @(kASFeatureSouthEast), @(kASFeatureSouth),
                        @(kASFeatureSouthWest), @(kASFeatureWest),
                        @(kASFeatureNorthWest), @(kASFeatureLower),
                        @(kASFeatureUpper),@(kASFeatureMiddle)];
            break;
        case kASFeature:
            values = (@[@(kASFeatureNone),
                        @(kASFeatureTerrace),
                        @(kASFeatureSpur),
                        @(kASFeatureRe_Entrant),
                        @(kASFeatureEarthBank),
                        @(kASFeatureQuarry),
                        @(kASFeatureEarthWall),
                        @(kASFeatureErosionGully),
                        @(kASFeatureHill),
                        @(kASFeatureKnoll),
                        @(kASFeatureSaddle),
                        @(kASFeatureDepression),
                        @(kASFeatureSmallDepression),
                        @(kASFeaturePit),
                        @(kASFeatureBrokenGround),
                        @(kASFeatureAntHill),
                        @(kASFeatureCliff),
                        @(kASFeatureRockPillar),
                        @(kASFeatureCave),
                        @(kASFeatureBoulder),
                        @(kASFeatureBoulderField),
                        @(kASFeatureBoulderCluster),
                        @(kASFeatureStonyGround),
                        @(kASFeatureBareRock),
                        @(kASFeatureNarrowPassage),
                        @(kASFeatureLake),
                        @(kASFeaturePond),
                        @(kASFeatureWaterhole),
                        @(kASFeatureStream),
                        @(kASFeatureDitch),
                        @(kASFeatureNarrowMarch),
                        @(kASFeatureFirmGroundInMarch),
                        @(kASFeatureWell),
                        @(kASFeatureSpring),
                        @(kASFeatureWaterTrough),
                        @(kASFeatureOpenLand),
                        @(kASFeatureSemiOpenLand),
                        @(kASFeatureForestCorner),
                        @(kASFeatureClearing),
                        @(kASFeatureThicket),
                        @(kASFeatureLinearThicket),
                        @(kASFeatureVegetationBoundary),
                        @(kASFeatureCopse),
                        @(kASFeatureDistinctiveTree),
                        @(kASFeatureTreeStumpOrRootStock),
                        @(kASFeatureRoad),
                        @(kASFeatureTrack),
                        @(kASFeatureRide),
                        @(kASFeatureBridge),
                        @(kASFeaturePowerLine),
                        @(kASFeaturePowerLinePylon),
                        @(kASFeatureTunnel),
                        @(kASFeatureStoneWall),
                        @(kASFeatureFence),
                        @(kASFeatureCrossingPoint),
                        @(kASFeatureBuilding),
                        @(kASFeaturePavedArea),
                        @(kASFeatureRuin),
                        @(kASFeaturePipeline),
                        @(kASFeatureTower),
                        @(kASFeatureShootingPlatform),
                        @(kASFeatureCairn),
                        @(kASFeatureFodderRack),
                        @(kASFeatureCharcoalBurningGround),
                        @(kASFeatureMonument),
                        @(kASFeatureBuildingPassThrough),
                        @(kASFeatureSpecialItem1),
                        @(kASFeatureSpecialItem2)]);
            break;
            
        default:
            break;
    }
    return values;
}

- (NSString *)localizedNameForValue:(NSInteger)value inColumn:(enum ASControlDescriptionColumn)column {
    enum ASFeature feature;
    enum ASWhichOfAnySimilarFeature which;
    
    NSString *s = nil;
    switch (column) {
        case kASFeature:
            feature = (enum ASFeature)value;
            
            switch (feature) {
                case kASFeatureNone:            s = NSLocalizedString(@"None", nil);    break;
                case kASFeatureTerrace:         s = NSLocalizedString(@"1.1", nil);     break;
                case kASFeatureSpur:            s = NSLocalizedString(@"1.2", nil);     break;
                case kASFeatureRe_Entrant:      s = NSLocalizedString(@"1.3", nil);     break;
                case kASFeatureEarthBank:       s = NSLocalizedString(@"1.4", nil);     break;
                case kASFeatureQuarry:          s = NSLocalizedString(@"1.5", nil);     break;
                case kASFeatureEarthWall:       s = NSLocalizedString(@"1.6", nil);     break;
                case kASFeatureErosionGully:    s = NSLocalizedString(@"1.7", nil);     break;
                case kASFeatureSmallErosionGully:s = NSLocalizedString(@"1.8", nil);    break;
                case kASFeatureHill:            s = NSLocalizedString(@"1.9", nil);    break;
                case kASFeatureKnoll:           s = NSLocalizedString(@"1.10", nil);    break;
                case kASFeatureSaddle:           s = NSLocalizedString(@"1.11", nil);    break;
                case kASFeatureDepression:           s = NSLocalizedString(@"1.12", nil);    break;
                case kASFeatureSmallDepression:            s = NSLocalizedString(@"1.13", nil);    break;
                case kASFeaturePit:           s = NSLocalizedString(@"1.14", nil);    break;
                case kASFeatureBrokenGround:           s = NSLocalizedString(@"1.15", nil);    break;
                case kASFeatureAntHill:           s = NSLocalizedString(@"1.16", nil);    break;
                case kASFeatureCliff:           s = NSLocalizedString(@"2.1", nil);    break;
                case kASFeatureRockPillar:             s = NSLocalizedString(@"2.2", nil);    break;
                case kASFeatureCave:           s = NSLocalizedString(@"2.3", nil);    break;
                case kASFeatureBoulder:            s = NSLocalizedString(@"2.4", nil);    break;
                case kASFeatureBoulderField:           s = NSLocalizedString(@"2.5", nil);    break;
                case kASFeatureBoulderCluster:           s = NSLocalizedString(@"2.6", nil);    break;
                case kASFeatureStonyGround:           s = NSLocalizedString(@"2.7", nil);    break;
                case kASFeatureBareRock:            s = NSLocalizedString(@"2.8", nil);    break;
                case kASFeatureNarrowPassage:              s = NSLocalizedString(@"2.9", nil);    break;
                case kASFeatureLake:           s = NSLocalizedString(@"3.1", nil);    break;
                case kASFeaturePond:           s = NSLocalizedString(@"3.2", nil);    break;
                case kASFeatureWaterhole:              s = NSLocalizedString(@"3.3", nil);    break;
                case kASFeatureStream:           s = NSLocalizedString(@"3.4", nil);    break;
                case kASFeatureDitch:              s = NSLocalizedString(@"3.5", nil);    break;
                case kASFeatureNarrowMarch:            s = NSLocalizedString(@"3.6", nil);    break;
                case kASFeatureMarch:           s = NSLocalizedString(@"3.7", nil);    break;
                case kASFeatureFirmGroundInMarch:           s = NSLocalizedString(@"3.8", nil);    break;
                case kASFeatureWell:           s = NSLocalizedString(@"3.9", nil);    break;
                case kASFeatureSpring:           s = NSLocalizedString(@"3.10", nil);    break;
                case kASFeatureWaterTrough:            s = NSLocalizedString(@"3.11", nil);    break;
                case kASFeatureOpenLand:               s = NSLocalizedString(@"4.1", nil);    break;
                case kASFeatureSemiOpenLand:    s = NSLocalizedString(@"4.2", nil); break;
                case kASFeatureForestCorner:    s = NSLocalizedString(@"4.3", nil); break;
                case kASFeatureClearing:        s = NSLocalizedString(@"4.4", nil); break;
                case kASFeatureThicket:         s = NSLocalizedString(@"4.5", nil); break;
                case kASFeatureLinearThicket:   s = NSLocalizedString(@"4.6", nil); break;
                case kASFeatureVegetationBoundary:s = NSLocalizedString(@"4.7", nil); break;
                case kASFeatureCopse:           s = NSLocalizedString(@"4.8", nil); break;
                case kASFeatureDistinctiveTree: s = NSLocalizedString(@"4.9", nil); break;
                case kASFeatureTreeStumpOrRootStock:s = NSLocalizedString(@"4.10", nil); break;
                case kASFeatureRoad:            s = NSLocalizedString(@"5.1", nil); break;
                case kASFeatureTrack:           s = NSLocalizedString(@"5.2", nil); break;
                case kASFeatureRide:            s = NSLocalizedString(@"5.3", nil); break;
                case kASFeatureBridge:          s = NSLocalizedString(@"5.4", nil); break;
                case kASFeaturePowerLine:       s = NSLocalizedString(@"5.5", nil); break;
                case kASFeaturePowerLinePylon:  s = NSLocalizedString(@"5.6", nil); break;
                case kASFeatureTunnel:          s = NSLocalizedString(@"5.7", nil); break;
                case kASFeatureStoneWall:       s = NSLocalizedString(@"5.8", nil); break;
                case kASFeatureFence:           s = NSLocalizedString(@"5.9", nil); break;
                case kASFeatureCrossingPoint:   s = NSLocalizedString(@"5.10", nil); break;
                case kASFeatureBuilding:        s = NSLocalizedString(@"5.11", nil); break;
                case kASFeaturePavedArea:       s = NSLocalizedString(@"5.12", nil); break;
                case kASFeatureRuin:            s = NSLocalizedString(@"5.13", nil); break;
                case kASFeaturePipeline:        s = NSLocalizedString(@"5.14", nil); break;
                case kASFeatureTower:           s = NSLocalizedString(@"5.15", nil); break;
                case kASFeatureShootingPlatform:s = NSLocalizedString(@"5.16", nil); break;
                case kASFeatureCairn:           s = NSLocalizedString(@"5.17", nil); break;
                case kASFeatureFodderRack:      s = NSLocalizedString(@"5.18", nil); break;
                case kASFeatureCharcoalBurningGround:s = NSLocalizedString(@"5.19", nil); break;
                case kASFeatureMonument:        s = NSLocalizedString(@"5.20", nil); break;
                case kASFeatureBuildingPassThrough:s = NSLocalizedString(@"5.23", nil); break;
                case kASFeatureSpecialItem1:    s = NSLocalizedString(@"6.1", nil); break;
                case kASFeatureSpecialItem2:    s = NSLocalizedString(@"6.2", nil); break;
                case kASFeatureStairway:        s = NSLocalizedString(@"5.24", nil); break;
                default:
                    break;
            }
            break;
        case kASWhichOfAnySimilarFeature:
            which = (enum ASWhichOfAnySimilarFeature)value;
            switch (which) {
                case kASFeatureEast:            s = NSLocalizedString(@"Eastern", nil);         break;
                case kASFeatureSouth:           s = NSLocalizedString(@"Southern", nil);        break;
                case kASFeatureWest:            s = NSLocalizedString(@"Western", nil);         break;
                case kASFeatureNorth:           s = NSLocalizedString(@"Northern", nil);        break;
                case kASFeatureSouthEast:       s = NSLocalizedString(@"South Eastern", nil);   break;
                case kASFeatureSouthWest:       s = NSLocalizedString(@"South Western", nil);   break;
                case kASFeatureNorthEast:       s = NSLocalizedString(@"North Eastern", nil);   break;
                case kASFeatureNorthWest:       s = NSLocalizedString(@"North Western", nil);   break;
                case kASFeatureMiddle:          s = NSLocalizedString(@"Middle", nil);          break;
                case kASFeatureUpper:           s = NSLocalizedString(@"Upper", nil);           break;
                case kASFeatureLower:           s = NSLocalizedString(@"Lower", nil);           break;
                case kASFeatureNotSpecified:    s = NSLocalizedString(@"Not specified", nil);   break;
                default:
                    break;
            }
        default:
            break;
    }
    return s;
}

#define C_ARROW_FRACTION 0.4
#define C_DUAL_LINE_SPACING 0.3
#define C_TRIPLE_LINE_SPACING 0.5
#define C_MARK_DOT 0.2

- (NSArray *)createPathsForWhichOfAnySimilarFeatureWithValue:(NSNumber *)value transform:(CGAffineTransform *)tran {
    enum ASWhichOfAnySimilarFeature feature = (enum ASWhichOfAnySimilarFeature)[value intValue];
    CGMutablePathRef path = CGPathCreateMutable(), subpath = NULL;
    CGPathRef fillable;
    switch (feature) {
        case kASFeatureNorth:
            CGPathMoveToPoint(path, NULL, 0.0, -SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, 0.0, SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, C_ARROW_FRACTION*SYMBOL_SIZE, (1.0-C_ARROW_FRACTION)*SYMBOL_SIZE);
            CGPathMoveToPoint(path, NULL, 0.0, SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, -C_ARROW_FRACTION*SYMBOL_SIZE, (1.0-C_ARROW_FRACTION)*SYMBOL_SIZE);
            break;
        case kASFeatureNorthEast:
            CGPathMoveToPoint(path, NULL, -SQRT2*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, SQRT2*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, SQRT2*SYMBOL_SIZE-C_ARROW_FRACTION*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE);
            CGPathMoveToPoint(path, NULL, SQRT2*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, SQRT2*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE-C_ARROW_FRACTION*SYMBOL_SIZE);
            break;
        case kASFeatureEast:
            CGPathMoveToPoint(path, NULL, -SYMBOL_SIZE, 0.0);
            CGPathAddLineToPoint(path, NULL, SYMBOL_SIZE, 0.0);
            CGPathAddLineToPoint(path, NULL, SYMBOL_SIZE-C_ARROW_FRACTION*SYMBOL_SIZE, C_ARROW_FRACTION*SYMBOL_SIZE);
            CGPathMoveToPoint(path, NULL, SYMBOL_SIZE, 0.0);
            CGPathAddLineToPoint(path, NULL, SYMBOL_SIZE-C_ARROW_FRACTION*SYMBOL_SIZE, -C_ARROW_FRACTION*SYMBOL_SIZE);
            break;
        case kASFeatureSouthEast:
            CGPathMoveToPoint(path, NULL, -SQRT2*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, SQRT2*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, SQRT2*SYMBOL_SIZE-C_ARROW_FRACTION*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE);
            CGPathMoveToPoint(path, NULL, SQRT2*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, SQRT2*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE+C_ARROW_FRACTION*SYMBOL_SIZE);
            break;
        case kASFeatureSouth:
            CGPathMoveToPoint(path, NULL, 0.0, SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, 0.0, -SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, ARROW_FRACTION*SYMBOL_SIZE, -(1.0-C_ARROW_FRACTION)*SYMBOL_SIZE);
            CGPathMoveToPoint(path, NULL, 0.0, -SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, -ARROW_FRACTION*SYMBOL_SIZE, -(1.0-C_ARROW_FRACTION)*SYMBOL_SIZE);
            break;
        case kASFeatureSouthWest:
            CGPathMoveToPoint(path, NULL, SQRT2*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, -SQRT2*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, -SQRT2*SYMBOL_SIZE+C_ARROW_FRACTION*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE);
            CGPathMoveToPoint(path, NULL, -SQRT2*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, -SQRT2*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE+C_ARROW_FRACTION*SYMBOL_SIZE);
            break;
        case kASFeatureWest:
            CGPathMoveToPoint(path, NULL, SYMBOL_SIZE, 0.0);
            CGPathAddLineToPoint(path, NULL, -SYMBOL_SIZE, 0.0);
            CGPathAddLineToPoint(path, NULL, -SYMBOL_SIZE+C_ARROW_FRACTION*SYMBOL_SIZE, C_ARROW_FRACTION*SYMBOL_SIZE);
            CGPathMoveToPoint(path, NULL, -SYMBOL_SIZE, 0.0);
            CGPathAddLineToPoint(path, NULL, -SYMBOL_SIZE+C_ARROW_FRACTION*SYMBOL_SIZE, -C_ARROW_FRACTION*SYMBOL_SIZE);
            break;
        case kASFeatureNorthWest:
            CGPathMoveToPoint(path, NULL, SQRT2*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, -SQRT2*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, -SQRT2*SYMBOL_SIZE+C_ARROW_FRACTION*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE);
            CGPathMoveToPoint(path, NULL, -SQRT2*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, -SQRT2*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE-C_ARROW_FRACTION*SYMBOL_SIZE);
            break;
        default:
            break;
    };
    
    if (feature == kASFeatureUpper || feature == kASFeatureLower) {
        CGPathMoveToPoint(path, NULL, -SYMBOL_SIZE, C_DUAL_LINE_SPACING*SYMBOL_SIZE);
        CGPathAddLineToPoint(path, NULL, SYMBOL_SIZE, C_DUAL_LINE_SPACING*SYMBOL_SIZE);
        CGPathMoveToPoint(path, NULL, -SYMBOL_SIZE, -C_DUAL_LINE_SPACING*SYMBOL_SIZE);
        CGPathAddLineToPoint(path, NULL, SYMBOL_SIZE, -C_DUAL_LINE_SPACING*SYMBOL_SIZE);
        
        subpath = CGPathCreateMutable();
        CGRect r = CGRectMake(-C_MARK_DOT*SYMBOL_SIZE, 
                              ((feature == kASFeatureLower)?(-1.0):(1.0))*C_DUAL_LINE_SPACING*SYMBOL_SIZE-C_MARK_DOT*SYMBOL_SIZE, C_MARK_DOT*SYMBOL_SIZE*2.0, C_MARK_DOT*SYMBOL_SIZE*2.0);
        CGPathAddEllipseInRect(subpath, tran, r);
    }
    
    if (feature == kASFeatureMiddle) {
        CGPathMoveToPoint(path, NULL, -C_TRIPLE_LINE_SPACING*SYMBOL_SIZE, -SYMBOL_SIZE);
        CGPathAddLineToPoint(path, NULL, -C_TRIPLE_LINE_SPACING*SYMBOL_SIZE, SYMBOL_SIZE);
        CGPathMoveToPoint(path, NULL, 0.0, -SYMBOL_SIZE);
        CGPathAddLineToPoint(path, NULL, 0.0, SYMBOL_SIZE);
        CGPathMoveToPoint(path, NULL, C_TRIPLE_LINE_SPACING*SYMBOL_SIZE, -SYMBOL_SIZE);
        CGPathAddLineToPoint(path, NULL, C_TRIPLE_LINE_SPACING*SYMBOL_SIZE, SYMBOL_SIZE);
        
        subpath = CGPathCreateMutable();
        CGRect r = CGRectMake(-C_MARK_DOT*SYMBOL_SIZE, 
                              -C_MARK_DOT*SYMBOL_SIZE, C_MARK_DOT*SYMBOL_SIZE*2.0, C_MARK_DOT*SYMBOL_SIZE*2.0);
        CGPathAddEllipseInRect(subpath, tran, r);
    }
    
    // Stroke original path
    CGFloat lw = THIN_LINE;
    if (tran != NULL) lw /= tran->a;
    fillable = CGPathCreateCopyByStrokingPath(path, tran, lw, kCGLineCapButt, kCGLineJoinBevel, 0.0);
    CGPathRelease(path);
    NSArray *pathArray;
    if (subpath != NULL) {
        pathArray = @[(__bridge id)fillable, (__bridge id)subpath];
        CGPathRelease(subpath);
    } else {
        pathArray = @[(__bridge id)fillable];
    }
    CGPathRelease(fillable);
    
    return pathArray;
}

- (NSArray *)createPathsForFeatureOrAppearance:(NSNumber *)value transform:(CGAffineTransform *)tran {
    enum ASFeature feature = (enum ASFeature)[value intValue];
    CGMutablePathRef path = CGPathCreateMutable(), nonfilled = NULL;
    CGPathRef fillable;
    int xindex, yindex;
    
    switch (feature) {
        case kASFeatureTerrace:
            CGPathMoveToPoint(path, NULL, -31.5, 48.5);
            CGPathAddCurveToPoint(path, NULL, -29.5, 42.5, -25.59, 15.49, -25.5, 1.5);
            CGPathAddCurveToPoint(path, NULL, -25.41, -12.49, -27.14, -40.77, -31.5, -51.5);
            
            
            CGPathMoveToPoint(path, NULL, -13.5, 47.5);
            CGPathAddCurveToPoint(path, NULL, -12.5, 43.5, -13.44, 36.84, -7.5, 33.5);
            CGPathAddCurveToPoint(path, NULL, -1.56, 30.16, 24.61, 32.39, 29.5, 25.5);
            CGPathAddCurveToPoint(path, NULL, 34.39, 18.61, 39.26, -20.52, 29.5, -27.5);
            CGPathAddCurveToPoint(path, NULL, 19.74, -34.48, -1.5, -30.26, -7.5, -36.5);
            CGPathAddCurveToPoint(path, NULL, -13.5, -42.74, -11.49, -40.23, -13.5, -51);
            break;            
        case kASFeatureSpur:
            CGPathMoveToPoint(path, NULL, -31.5, 48.5);
            CGPathAddCurveToPoint(path, NULL, -29.5, 42.5, -25.59, 15.49, -25.5, 1.5);
            CGPathAddCurveToPoint(path, NULL, -25.41, -12.49, -27.14, -40.77, -31.5, -51.5);
            
            
            CGPathMoveToPoint(path, NULL, -14.5, 47.5);
            CGPathAddCurveToPoint(path, NULL, -13.5, 37.5, -11.61, 20.18, -6.5, 14.5);
            CGPathAddCurveToPoint(path, NULL, -1.39, 8.82, 40.78, 11.79, 43.5, 7.5);
            CGPathAddCurveToPoint(path, NULL, 46.22, 3.21, 48.17, -8.82, 43.5, -12.5);
            CGPathAddCurveToPoint(path, NULL, 38.83, -16.18, 1.5, -13.88, -6.5, -18.5);
            CGPathAddCurveToPoint(path, NULL, -14.5, -23.12, -13.35, -43.99, -14, -52);
            break;
        case kASFeatureRe_Entrant:
            CGPathMoveToPoint(path, NULL, -55.5, -48.5);
            CGPathAddCurveToPoint(path, NULL, -51.5, -48.5, -37.77, -52.2, -32.5, -43.5);
            CGPathAddCurveToPoint(path, NULL, -27.23, -34.8, -27.6, 38.94, -2.5, 38.5);
            CGPathAddCurveToPoint(path, NULL, 22.6, 38.06, 22.24, -34.69, 29.5, -43.5);
            CGPathAddCurveToPoint(path, NULL, 36.76, -52.31, 43.84, -48.5, 55.5, -48.5);
            break;
        case kASFeatureEarthBank:
            CGPathMoveToPoint(path, NULL, -39.5, 12.5);
            CGPathAddCurveToPoint(path, NULL, -34.5, 8.5, -27.56, 0, 0.5, 0.5);
            CGPathAddCurveToPoint(path, NULL, 28.56, 1, 34.03, 6.04, 43.5, 12.5);
            CGPathMoveToPoint(path, NULL, -29.5, 5.5);
            CGPathAddCurveToPoint(path, NULL, -40.5, -7.5, -40.5, -7.5, -40.5, -7.5);            
            CGPathMoveToPoint(path, NULL, -12.5, -0.5);
            CGPathAddCurveToPoint(path, NULL, -16.5, -21.5, -16.5, -21.5, -16.5, -21.5);
            CGPathMoveToPoint(path, NULL, 9.5, -0.5);
            CGPathAddCurveToPoint(path, NULL, 12.5, -21.5, 12.5, -21.5, 12.5, -21.5);
            CGPathMoveToPoint(path, NULL, 31.5, 3.5);
            CGPathAddCurveToPoint(path, NULL, 39.5, -10.5, 39.5, -11.5, 39.5, -11.5);
            break;
        case kASFeatureEarthWall:
            CGPathMoveToPoint(path, NULL, -42.5, -0.5);
            CGPathAddCurveToPoint(path, NULL, 42.5, -0.5, 42.5, -0.5, 42.5, -0.5);
            CGPathMoveToPoint(path, NULL, -28.5, 10.5);
            CGPathAddCurveToPoint(path, NULL, -28.5, -12.5, -28.5, -13.5, -28.5, -13.5);
            CGPathMoveToPoint(path, NULL, -9.5, 16.5);
            CGPathAddCurveToPoint(path, NULL, -9.5, -17.5, -9.5, -18.5, -9.5, -18.5);
            CGPathMoveToPoint(path, NULL, 10.5, 16.5);
            CGPathAddCurveToPoint(path, NULL, 10.5, -18.5, 10.5, -18.5, 10.5, -18.5);
            CGPathMoveToPoint(path, NULL, 29.5, 11.5);
            CGPathAddCurveToPoint(path, NULL, 29.5, -13.5, 29.5, -13.5, 29.5, -13.5);
            break;
        case kASFeatureErosionGully:
            CGPathMoveToPoint(path, NULL, -31.5, -45.5);
            CGPathAddLineToPoint(path, NULL, -2.5, 41.5);
            CGPathAddLineToPoint(path, NULL, 25.5, -45.5);
            break;
        case kASFeatureQuarry:
            CGPathMoveToPoint(path, NULL, -38.5, -47.5);
            CGPathAddCurveToPoint(path, NULL, -44.5, -37.5, -54.96, -14.62, -54.5, -2.5);
            CGPathAddCurveToPoint(path, NULL, -54.04, 9.62, -41.93, 30.03, -33.5, 37.5);
            CGPathAddCurveToPoint(path, NULL, -25.07, 44.97, -17.74, 49.43, -0.5, 49.5);
            CGPathAddCurveToPoint(path, NULL, 16.74, 49.57, 24.22, 43.99, 32.5, 37.5);
            CGPathAddCurveToPoint(path, NULL, 40.78, 31.01, 52.31, 11.16, 52.5, -2.5);
            CGPathAddCurveToPoint(path, NULL, 52.69, -16.16, 42.37, -39.5, 36.5, -48.5);
            CGPathMoveToPoint(path, NULL, -33.5, 36.5);
            CGPathAddLineToPoint(path, NULL, -15.5, 16.5);
            CGPathMoveToPoint(path, NULL, 33.5, 36.5);
            CGPathAddLineToPoint(path, NULL, 13.5, 16.5);
            CGPathMoveToPoint(path, NULL, 48.5, -22.5);
            CGPathAddLineToPoint(path, NULL, 29.5, -15.5);
            CGPathMoveToPoint(path, NULL, -49.5, -22.5);
            CGPathAddLineToPoint(path, NULL, -31.5, -16.5);
            break;
        case kASFeatureSmallErosionGully:
            nonfilled = CGPathCreateMutable();
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-39.5, 23.5, 16, 17));  
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-22.5, 6.5, 16, 17));  
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-7.5, -9.5, 16, 17));  
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(10.5, -26.5, 16, 17));  
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(26.5, -43.5, 16, 17));  
            CGPathMoveToPoint(path, NULL, -23.5, 49.5);
            CGPathAddLineToPoint(path, NULL, 53.5, -27.5);
            CGPathMoveToPoint(path, NULL, -49.5, 24.5);
            CGPathAddLineToPoint(path, NULL, 26.5, -51.5);
            break;
        case kASFeatureHill:
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-55.5, -33.5, 110, 67));
            break;
        case kASFeatureKnoll:
            nonfilled = CGPathCreateMutable();
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-17.5, -17.5, 36, 36));
            break;
        case kASFeatureSaddle:
            CGPathMoveToPoint(path, NULL, -24.5, 51.5);
            CGPathAddCurveToPoint(path, NULL, -20.5, 43.5, -11.53, 22.95, -11.5, 0.5);
            CGPathAddCurveToPoint(path, NULL, -11.47, -21.95, -18.67, -40.42, -24.5, -49.5);
            CGPathMoveToPoint(path, NULL, 24.5, 51.5);
            CGPathAddCurveToPoint(path, NULL, 20.5, 43.5, 11.53, 22.95, 11.5, 0.5);
            CGPathAddCurveToPoint(path, NULL, 11.47, -21.95, 18.67, -40.42, 24.5, -49.5);
            break;
        case kASFeatureDepression:
            CGPathMoveToPoint(path, NULL, -17.5, -0.5);
            CGPathAddLineToPoint(path, NULL, -54.5, -0.5);
            CGPathMoveToPoint(path, NULL, 18.5, -1);
            CGPathAddLineToPoint(path, NULL, 54.5, -1);
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-54.5, -33.5, 109, 66));
            break;
        case kASFeatureSmallDepression:
            CGPathMoveToPoint(path, NULL, -42.5, 29.5);
            CGPathAddCurveToPoint(path, NULL, -47.5, 19.5, -48.97, 12.57, -48.5, 4.5);
            CGPathAddCurveToPoint(path, NULL, -48.03, -3.57, -39.25, -21.59, -32.5, -26.5);
            CGPathAddCurveToPoint(path, NULL, -25.75, -31.41, -12.55, -37.49, -0.5, -37.5);
            CGPathAddCurveToPoint(path, NULL, 11.55, -37.51, 22.74, -32.79, 29.5, -26.5);
            CGPathAddCurveToPoint(path, NULL, 36.26, -20.21, 44.5, -7.63, 44.5, 4.5);
            CGPathAddCurveToPoint(path, NULL, 44.5, 16.63, 44.4, 18.36, 39.5, 29.5);
            break;
        case kASFeaturePit:
            CGPathMoveToPoint(path, NULL, -34.5, 37.5);
            CGPathAddLineToPoint(path, NULL, 0.5, -39.5);
            CGPathAddLineToPoint(path, NULL, 35.5, 37.5);
            break;
        case kASFeatureBrokenGround:
            CGPathMoveToPoint(path, NULL, -47.5, 34.5);
            CGPathAddCurveToPoint(path, NULL, -50.5, 29.5, -51.92, 19.56, -45, 12.5);
            CGPathAddCurveToPoint(path, NULL, -38.08, 5.44, -26.93, 3.88, -19.5, 12);
            CGPathAddCurveToPoint(path, NULL, -12.07, 20.12, -13.16, 23.44, -15.5, 33.5);
            CGPathMoveToPoint(path, NULL, 19.5, 34.5);
            CGPathAddCurveToPoint(path, NULL, 16.5, 29.5, 15.08, 19.56, 22, 12.5);
            CGPathAddCurveToPoint(path, NULL, 28.92, 5.44, 40.07, 3.88, 47.5, 12);
            CGPathAddCurveToPoint(path, NULL, 54.93, 20.12, 53.84, 23.44, 51.5, 33.5);
            CGPathMoveToPoint(path, NULL, -15, -13.5);
            CGPathAddCurveToPoint(path, NULL, -18, -18.5, -19.42, -28.44, -12.5, -35.5);
            CGPathAddCurveToPoint(path, NULL, -5.58, -42.56, 5.57, -44.12, 13, -36);
            CGPathAddCurveToPoint(path, NULL, 20.43, -27.88, 19.34, -24.56, 17, -14.5);
            break;
        case kASFeatureAntHill:
            CGPathMoveToPoint(path, NULL, 0.5, 49.5);
            CGPathAddLineToPoint(path, NULL, 0.5, -53.5);
            CGPathMoveToPoint(path, NULL, 37.5, 36.5);
            CGPathAddLineToPoint(path, NULL, -34.5, -35.5);
            CGPathMoveToPoint(path, NULL, 52.5, 0.5);
            CGPathAddLineToPoint(path, NULL, -49.5, 0.5);
            CGPathMoveToPoint(path, NULL, -34.5, 34.5);
            CGPathAddLineToPoint(path, NULL, 37.5, -37.5);
            break;
        case kASFeatureCliff:
            CGPathMoveToPoint(path, NULL, -49.5, -15.5);
            CGPathAddLineToPoint(path, NULL, -49.5, 17.5);
            CGPathAddLineToPoint(path, NULL, 50.5, 16.5);
            CGPathAddLineToPoint(path, NULL, 50.5, -15.5);
            CGPathMoveToPoint(path, NULL, -18.5, -15.5);
            CGPathAddLineToPoint(path, NULL, -18.5, 16.5);
            CGPathMoveToPoint(path, NULL, 15.5, -15.5);
            CGPathAddLineToPoint(path, NULL, 15.5, 16.5);
            break;
        case kASFeatureRockPillar:
            nonfilled = CGPathCreateMutable();
            CGPathMoveToPoint(nonfilled, tran, -22.5, -50.5);
            CGPathAddLineToPoint(nonfilled, tran, -0.5, 49.5);
            CGPathAddLineToPoint(nonfilled, tran, 20.5, -50.5);
            CGPathCloseSubpath(nonfilled);
            break;
        case kASFeatureCave:
            CGPathMoveToPoint(path, NULL, -8.5, -53.5);
            CGPathAddCurveToPoint(path, NULL, -3.5, -44.5, 6.13, -29.36, 7.5, -10.5);
            CGPathMoveToPoint(path, NULL, -8.5, 52.5);
            CGPathAddCurveToPoint(path, NULL, -3.5, 43.5, 6.13, 28.36, 7.5, 9.5);
            CGPathMoveToPoint(path, NULL, 29.5, 18.5);
            CGPathAddLineToPoint(path, NULL, -17.5, 0.5);
            CGPathAddLineToPoint(path, NULL, 29.5, -19.5);
            break;
        case kASFeatureBoulder:
            nonfilled = CGPathCreateMutable();
            CGPathMoveToPoint(nonfilled, tran, -0.5, 36.5);
            CGPathAddLineToPoint(nonfilled, tran, -38.5, -27.5);
            CGPathAddLineToPoint(nonfilled, tran, 37.5, -27.5);
            CGPathCloseSubpath(nonfilled);
            break;
        case kASFeatureBoulderField:
            nonfilled = CGPathCreateMutable();
            CGPathMoveToPoint(nonfilled, tran, -32.5, 52.5);
            CGPathAddLineToPoint(nonfilled, tran, -51.5, 19.5);
            CGPathAddLineToPoint(nonfilled, tran, -12.5, 19.5);
            CGPathCloseSubpath(nonfilled);
            CGPathMoveToPoint(nonfilled, tran, 30.5, 52.5);
            CGPathAddLineToPoint(nonfilled, tran, 11.5, 19.5);
            CGPathAddLineToPoint(nonfilled, tran, 50.5, 19.5);
            CGPathCloseSubpath(nonfilled);
            CGPathMoveToPoint(nonfilled, tran, -1.5, 18.5);
            CGPathAddLineToPoint(nonfilled, tran, -20.5, -14.5);
            CGPathAddLineToPoint(nonfilled, tran, 18.5, -14.5);
            CGPathCloseSubpath(nonfilled);
            CGPathMoveToPoint(nonfilled, tran, -32.5, -18);
            CGPathAddLineToPoint(nonfilled, tran, -51.5, -51);
            CGPathAddLineToPoint(nonfilled, tran, -12.5, -51);
            CGPathCloseSubpath(nonfilled);
            CGPathMoveToPoint(nonfilled, tran, 30.5, -18);
            CGPathAddLineToPoint(nonfilled, tran, 11.5, -51);
            CGPathAddLineToPoint(nonfilled, tran, 50.5, -51);
            CGPathCloseSubpath(nonfilled);
            break;
        case kASFeatureBoulderCluster:
            nonfilled = CGPathCreateMutable();
            CGPathMoveToPoint(nonfilled, tran, -10.5, 37.5);
            CGPathAddLineToPoint(nonfilled, tran, -43.5, -19.5);
            CGPathAddLineToPoint(nonfilled, tran, -10.5, -19.5);
            CGPathAddLineToPoint(nonfilled, tran, -16.5, -29.5);
            CGPathAddLineToPoint(nonfilled, tran, 42.5, -29.5);
            CGPathAddLineToPoint(nonfilled, tran, 15.5, 25.5);
            CGPathAddLineToPoint(nonfilled, tran, 5.5, 6.5);
            CGPathCloseSubpath(nonfilled);
            break;
        case kASFeatureStonyGround:
            nonfilled = CGPathCreateMutable();
            for (xindex = -2; xindex <= 2; xindex ++) {
                for (yindex = -2; yindex <= 2; yindex++) {
                    CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-10.0 + 20.0*xindex, -10.0 + 20.0*yindex, 15, 15));                    
                }
            }
            break;
        case kASFeatureBareRock:
            CGPathMoveToPoint(path, NULL, -36.5, 36.5);
            CGPathAddLineToPoint(path, NULL, -10.5, 10.5);
            CGPathMoveToPoint(path, NULL, 0.5, 14.5);
            CGPathAddLineToPoint(path, NULL, 0.5, 53.5);
            CGPathMoveToPoint(path, NULL, -53.5, 0.5);
            CGPathAddLineToPoint(path, NULL, -14.5, 0.5);
            CGPathMoveToPoint(path, NULL, -37.5, -37.5);
            CGPathAddLineToPoint(path, NULL, -10.5, -10.5);
            CGPathMoveToPoint(path, NULL, 0.5, -53.5);
            CGPathAddLineToPoint(path, NULL, 0.5, -14.5);
            CGPathMoveToPoint(path, NULL, 10.5, -10.5);
            CGPathAddLineToPoint(path, NULL, 37.5, -37.5);
            CGPathMoveToPoint(path, NULL, 14.5, 0.5);
            CGPathAddLineToPoint(path, NULL, 53.5, 0.5);
            CGPathMoveToPoint(path, NULL, 10.5, 10.5);
            CGPathAddLineToPoint(path, NULL, 37.5, 37.5);
            break;
        case kASFeatureNarrowPassage:
            CGPathMoveToPoint(path, NULL, -27.5, 33.5);
            CGPathAddLineToPoint(path, NULL, -10.5, 33.5);
            CGPathAddLineToPoint(path, NULL, -10.5, -32.5);
            CGPathAddLineToPoint(path, NULL, -27.5, -32.5);
            CGPathMoveToPoint(path, NULL, 27.5, 33.5);
            CGPathAddLineToPoint(path, NULL, 10.5, 33.5);
            CGPathAddLineToPoint(path, NULL, 10.5, -32.5);
            CGPathAddLineToPoint(path, NULL, 27.5, -32.5);
            break;
        case kASFeatureLake:
            CGPathMoveToPoint(path, NULL, -27.5, -11.5);
            CGPathAddCurveToPoint(path, NULL, -27.5, -5.5, -28.97, -0.14, -25, 5.5);
            CGPathAddCurveToPoint(path, NULL, -21.03, 11.14, -15.02, 10.55, -10.5, 4.5);
            CGPathAddCurveToPoint(path, NULL, -5.98, -1.55, -11.29, -7.13, -6.5, -12);
            CGPathAddCurveToPoint(path, NULL, -1.71, -16.87, 3.63, -15.72, 7.5, -10);
            CGPathAddCurveToPoint(path, NULL, 11.37, -4.28, 7.26, 1.38, 12, 6);
            CGPathAddCurveToPoint(path, NULL, 16.74, 10.62, 24.03, 9.12, 27.5, 3.5);
            CGPathAddCurveToPoint(path, NULL, 30.97, -2.12, 27.5, -11, 27.5, -11.5);
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-46.5, -37.5, 95, 70));
            break;
        case kASFeaturePond:
            CGPathMoveToPoint(path, NULL, -30.5, 2.5);
            CGPathAddCurveToPoint(path, NULL, -34.5, -5.5, -39.12, -23.21, -27.5, -36.5);
            CGPathAddCurveToPoint(path, NULL, -15.88, -49.79, -7.03, -50.76, 0.5, -51);
            CGPathAddCurveToPoint(path, NULL, 8.03, -51.24, 22.64, -47.48, 29, -36);
            CGPathAddCurveToPoint(path, NULL, 35.36, -24.52, 38.32, -11.62, 32.5, 2);
            CGPathMoveToPoint(path, NULL, 47.5, 21.5);
            CGPathAddCurveToPoint(path, NULL, 47.5, 28.5, 48.05, 37.9, 45, 45);
            CGPathAddCurveToPoint(path, NULL, 41.95, 52.1, 33, 50.93, 30.5, 45.5);
            CGPathAddCurveToPoint(path, NULL, 28, 40.07, 30.78, 29.5, 26.5, 25.5);
            CGPathAddCurveToPoint(path, NULL, 22.22, 21.5, 18.03, 18.17, 11.5, 25.5);
            CGPathAddCurveToPoint(path, NULL, 4.97, 32.83, 11.59, 36.99, 6.5, 45.5);
            CGPathAddCurveToPoint(path, NULL, 1.41, 54.01, -5.06, 51.23, -8.5, 45.5);
            CGPathAddCurveToPoint(path, NULL, -11.94, 39.77, -7.84, 33.54, -12.5, 25.5);
            CGPathAddCurveToPoint(path, NULL, -17.16, 17.46, -24.2, 19.24, -27.5, 25.5);
            CGPathAddCurveToPoint(path, NULL, -30.8, 31.76, -26.41, 37.48, -32.5, 45.5);
            CGPathAddCurveToPoint(path, NULL, -38.59, 53.52, -42.8, 52.07, -46.5, 45.5);
            CGPathAddCurveToPoint(path, NULL, -50.2, 38.93, -48.87, 32.96, -49, 26.5);
            break;
        case kASFeatureWaterhole:
            CGPathMoveToPoint(path, NULL, 45.5, 22.41);
            CGPathAddCurveToPoint(path, NULL, 45.5, 28.96, 46.03, 37.75, 43.13, 44.39);
            CGPathAddCurveToPoint(path, NULL, 40.23, 51.02, 31.75, 49.93, 29.38, 44.86);
            CGPathAddCurveToPoint(path, NULL, 27.01, 39.78, 29.64, 29.89, 25.59, 26.15);
            CGPathAddCurveToPoint(path, NULL, 21.53, 22.41, 17.55, 19.3, 11.36, 26.15);
            CGPathAddCurveToPoint(path, NULL, 5.18, 33.01, 11.45, 36.9, 6.62, 44.86);
            CGPathAddCurveToPoint(path, NULL, 1.8, 52.81, -4.34, 50.21, -7.6, 44.86);
            CGPathAddCurveToPoint(path, NULL, -10.86, 39.5, -6.97, 33.67, -11.39, 26.15);
            CGPathAddCurveToPoint(path, NULL, -15.82, 18.63, -22.49, 20.29, -25.62, 26.15);
            CGPathAddCurveToPoint(path, NULL, -28.75, 32.01, -24.58, 37.36, -30.36, 44.86);
            CGPathAddCurveToPoint(path, NULL, -36.14, 52.35, -40.13, 51, -43.64, 44.86);
            CGPathAddCurveToPoint(path, NULL, -47.15, 38.71, -45.89, 33.13, -46.01, 27.09);
            CGPathMoveToPoint(path, NULL, -23.5, 1.5);
            CGPathAddLineToPoint(path, NULL, -0.5, -52.5);
            CGPathAddLineToPoint(path, NULL, 23.5, 1.5);
            break;
        case kASFeatureStream:
            CGPathMoveToPoint(path, NULL, -38.5, 50.5);
            CGPathAddCurveToPoint(path, NULL, -43.5, 45.5, -49.32, 44.05, -49.5, 35.5);
            CGPathAddCurveToPoint(path, NULL, -49.68, 26.95, -46.77, 26.49, -38.5, 26.5);
            CGPathAddCurveToPoint(path, NULL, -30.23, 26.51, -31.89, 35.5, -22.5, 35.5);
            CGPathAddCurveToPoint(path, NULL, -13.11, 35.5, -14.3, 30.78, -14.5, 26.5);
            CGPathAddCurveToPoint(path, NULL, -14.7, 22.22, -22.5, 20.48, -22.5, 10.5);
            CGPathAddCurveToPoint(path, NULL, -22.5, 0.52, -18.41, 1.33, -14.5, 1.5);
            CGPathAddCurveToPoint(path, NULL, -10.59, 1.67, -4.67, 10.5, 3.5, 10.5);
            CGPathAddCurveToPoint(path, NULL, 11.67, 10.5, 11.69, 6.18, 11.5, 1.5);
            CGPathAddCurveToPoint(path, NULL, 11.31, -3.18, 3.5, -6.2, 3.5, -14.5);
            CGPathAddCurveToPoint(path, NULL, 3.5, -22.8, 6.21, -24.33, 11.5, -24.5);
            CGPathAddCurveToPoint(path, NULL, 16.79, -24.67, 21.84, -14.5, 29.5, -14.5);
            CGPathAddCurveToPoint(path, NULL, 37.16, -14.5, 36.92, -19.26, 36.5, -24.5);
            CGPathAddCurveToPoint(path, NULL, 36.08, -29.74, 29.5, -30.52, 29.5, -38.5);
            CGPathAddCurveToPoint(path, NULL, 29.5, -46.48, 30.98, -49.17, 36.5, -49.5);
            break;
        case kASFeatureDitch:
            CGPathMoveToPoint(path, NULL, -21.5, 50.5);
            CGPathAddLineToPoint(path, NULL, 0.5, 28.5);
            CGPathMoveToPoint(path, NULL, 7.5, 21.5);
            CGPathAddLineToPoint(path, NULL, 25.5, 3.5);
            CGPathMoveToPoint(path, NULL, 33.5, -4.5);
            CGPathAddLineToPoint(path, NULL, 50.5, -21.5);
            CGPathMoveToPoint(path, NULL, -50.5, 20.5);
            CGPathAddLineToPoint(path, NULL, -28.5, -1.5);
            CGPathMoveToPoint(path, NULL, -21.5, -8.5);
            CGPathAddLineToPoint(path, NULL, -3.5, -26.5);
            CGPathMoveToPoint(path, NULL, 4.5, -34.5);
            CGPathAddLineToPoint(path, NULL, 21.5, -51.5);
            CGPathMoveToPoint(path, NULL, -27.5, 36.5);
            CGPathAddCurveToPoint(path, NULL, -30.5, 33.5, -35.22, 29.65, -35, 25);
            CGPathAddCurveToPoint(path, NULL, -34.78, 20.35, -33.25, 20.03, -29.5, 19.5);
            CGPathAddCurveToPoint(path, NULL, -25.75, 18.97, -21.4, 27.46, -16, 27);
            CGPathAddCurveToPoint(path, NULL, -10.6, 26.54, -9.84, 23.95, -10.5, 20);
            CGPathAddCurveToPoint(path, NULL, -11.16, 16.05, -16.96, 12.03, -16.5, 7.5);
            CGPathAddCurveToPoint(path, NULL, -16.04, 2.97, -15.86, 1.29, -11.5, 1);
            CGPathAddCurveToPoint(path, NULL, -7.14, 0.71, -3.42, 8.54, 3, 8.5);
            CGPathAddCurveToPoint(path, NULL, 9.42, 8.46, 8.27, 5.54, 8.5, 1.5);
            CGPathAddCurveToPoint(path, NULL, 8.73, -2.54, 2, -3.85, 2.5, -9.5);
            CGPathAddCurveToPoint(path, NULL, 3, -15.15, 3.94, -17.26, 7.5, -17.5);
            CGPathAddCurveToPoint(path, NULL, 11.06, -17.74, 14.77, -9.72, 20.5, -10);
            CGPathAddCurveToPoint(path, NULL, 26.23, -10.28, 26.53, -13.18, 26.5, -17.5);
            CGPathAddCurveToPoint(path, NULL, 26.47, -21.82, 19.98, -22.53, 20.5, -27.5);
            CGPathAddCurveToPoint(path, NULL, 21.02, -32.47, 21.17, -35.12, 25, -35);
            CGPathAddCurveToPoint(path, NULL, 28.83, -34.88, 32.54, -32.34, 37.5, -28);
            break;
        case kASFeatureNarrowMarch:
            nonfilled = CGPathCreateMutable();
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(25, -43, 17, 17));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(8, -26, 17, 17));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-41, 25, 17, 17));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-25, 8, 17, 17));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-8, -9, 17, 17));
            break;
        case kASFeatureMarch:
            CGPathMoveToPoint(path, NULL, -21.5, 49.5);
            CGPathAddLineToPoint(path, NULL, 21.5, 49.5);
            CGPathMoveToPoint(path, NULL, -42.5, 24.5);
            CGPathAddLineToPoint(path, NULL, 40.5, 24.5);
            CGPathMoveToPoint(path, NULL, -55.5, 0.5);
            CGPathAddLineToPoint(path, NULL, 54.5, 0.5);
            CGPathMoveToPoint(path, NULL, -43.5, -24.5);
            CGPathAddLineToPoint(path, NULL, 39.5, -24.5);
            CGPathMoveToPoint(path, NULL, -23.5, -49.5);
            CGPathAddLineToPoint(path, NULL, 22.5, -49.5);
            break;
        case kASFeatureFirmGroundInMarch:
            CGPathMoveToPoint(path, NULL, -54.5, 49.5);
            CGPathAddLineToPoint(path, NULL, 54.5, 49.5);
            CGPathMoveToPoint(path, NULL, -54.5, 24.5);
            CGPathAddLineToPoint(path, NULL, -26.5, 24.5);
            CGPathMoveToPoint(path, NULL, 25.5, 24.5);
            CGPathAddLineToPoint(path, NULL, 54.5, 24.5);
            CGPathMoveToPoint(path, NULL, 35.5, 0.5);
            CGPathAddLineToPoint(path, NULL, 55.5, 0.5);
            CGPathMoveToPoint(path, NULL, -54.5, -24.5);
            CGPathAddLineToPoint(path, NULL, -26.5, -24.5);
            CGPathMoveToPoint(path, NULL, 24.5, -24.5);
            CGPathAddLineToPoint(path, NULL, 55.5, -24.5);
            CGPathMoveToPoint(path, NULL, -55.5, -49.5);
            CGPathAddLineToPoint(path, NULL, 55.5, -49.5);
            CGPathMoveToPoint(path, NULL, -55.5, -0.5);
            CGPathAddLineToPoint(path, NULL, -36.5, -0.5);
            break;
        case kASFeatureWell:
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-32.5, -15.5, 65, 63));
            CGPathMoveToPoint(path, NULL, -32.5, -49.5);
            CGPathAddCurveToPoint(path, NULL, -32.5, -42.5, -34.97, -33.27, -28.5, -27);
            CGPathAddCurveToPoint(path, NULL, -22.03, -20.73, -17.45, -23.05, -13.5, -28.5);
            CGPathAddCurveToPoint(path, NULL, -9.55, -33.95, -14.66, -41.15, -9, -46.5);
            CGPathAddCurveToPoint(path, NULL, -3.34, -51.85, 4.33, -53.76, 10, -47);
            CGPathAddCurveToPoint(path, NULL, 15.67, -40.24, 9.09, -33.38, 15, -28);
            CGPathAddCurveToPoint(path, NULL, 20.91, -22.62, 24.48, -21.46, 30.5, -29);
            CGPathAddCurveToPoint(path, NULL, 36.52, -36.54, 33.21, -41.37, 34, -48.5);
            break;
        case kASFeatureSpring:
            CGPathMoveToPoint(path, NULL, -30.5, 11.5);
            CGPathAddCurveToPoint(path, NULL, -36.5, 12.5, -39.07, 15.66, -42.5, 20.5);
            CGPathAddCurveToPoint(path, NULL, -45.93, 25.34, -45.39, 34.55, -42.5, 40.5);
            CGPathAddCurveToPoint(path, NULL, -39.61, 46.45, -34.14, 49.68, -27.5, 49.5);
            CGPathAddCurveToPoint(path, NULL, -20.86, 49.32, -16.97, 48.45, -8.5, 36);
            CGPathMoveToPoint(path, NULL, -25.5, 29.5);
            CGPathAddCurveToPoint(path, NULL, -17.5, 20.5, -15.69, 13.97, -9.5, 12);
            CGPathAddCurveToPoint(path, NULL, -3.31, 10.03, 2.64, 13.79, 9, 10.5);
            CGPathAddCurveToPoint(path, NULL, 15.36, 7.21, 15.69, 4.45, 14.5, -1);
            CGPathAddCurveToPoint(path, NULL, 13.31, -6.45, 7.18, -8.17, 7, -14);
            CGPathAddCurveToPoint(path, NULL, 6.82, -19.83, 9.64, -27.48, 15.5, -27.5);
            CGPathAddCurveToPoint(path, NULL, 21.36, -27.52, 24.32, -16.78, 34.5, -18);
            CGPathAddCurveToPoint(path, NULL, 44.68, -19.22, 44.87, -22.55, 46, -27.5);
            CGPathAddCurveToPoint(path, NULL, 47.13, -32.45, 43.24, -43.16, 41, -49);
            break;
        case kASFeatureWaterTrough:
            CGPathAddRect(path, NULL, CGRectMake(-37.5, -42.5, 73, 38));
            CGPathMoveToPoint(path, NULL, -45.5, 17.5);
            CGPathAddCurveToPoint(path, NULL, -45.5, 25.5, -46.33, 35.07, -41.5, 39.5);
            CGPathAddCurveToPoint(path, NULL, -36.67, 43.93, -33.32, 43.24, -29, 36.5);
            CGPathAddCurveToPoint(path, NULL, -24.68, 29.76, -29.95, 25.56, -26, 19.5);
            CGPathAddCurveToPoint(path, NULL, -22.05, 13.44, -15.71, 13.66, -11.5, 19.5);
            CGPathAddCurveToPoint(path, NULL, -7.29, 25.34, -11.52, 33.39, -6.5, 38.5);
            CGPathAddCurveToPoint(path, NULL, -1.48, 43.61, 1.79, 43.11, 6, 38.5);
            CGPathAddCurveToPoint(path, NULL, 10.21, 33.89, 5.92, 26.74, 9.5, 21);
            CGPathAddCurveToPoint(path, NULL, 13.08, 15.26, 20.75, 13.5, 24.5, 20.5);
            CGPathAddCurveToPoint(path, NULL, 28.25, 27.5, 23.3, 33.41, 29, 39.5);
            CGPathAddCurveToPoint(path, NULL, 34.7, 45.59, 37.03, 42.92, 41, 37.5);
            CGPathAddCurveToPoint(path, NULL, 44.97, 32.08, 43.49, 26.65, 43.5, 20);
            break;
        case kASFeatureOpenLand:
            CGPathMoveToPoint(path, NULL, 1.5, 49.5);
            CGPathAddLineToPoint(path, NULL, -47.5, 0.5);
            CGPathAddLineToPoint(path, NULL, 1.5, -48.5);
            CGPathAddLineToPoint(path, NULL, 50.5, 0.5);
            CGPathCloseSubpath(path);
            break;
        case kASFeatureSemiOpenLand:
            //// Color Declarations
            nonfilled = CGPathCreateMutable();
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-33.5, 11.5, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-49, -4, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-18, 26, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-4, 40, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(11, 26, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(26, 11, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(40, -4, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(25, -18, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(10, -33, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-4, -48, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-19, -33, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-35, -18, 11, 11));
            break;
        case kASFeatureForestCorner:
            //// Color Declarations
            CGPathMoveToPoint(path, NULL, -47, 0);
            CGPathAddLineToPoint(path, NULL, 2, 49);
            CGPathAddLineToPoint(path, NULL, 3, 0);
            CGPathAddLineToPoint(path, NULL, 52, 0);
            CGPathAddLineToPoint(path, NULL, 2, -49);
            CGPathAddLineToPoint(path, NULL, -47, 0);
            CGPathCloseSubpath(path);
            break;
        case kASFeatureClearing:
            nonfilled = CGPathCreateMutable();
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-6, 42, 12, 12));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(18, 35, 12, 12));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(35, 18, 12, 12));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(42, -6, 12, 12));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(35, -30, 12, 12));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(18, -47, 12, 12));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-6, -54, 12, 12));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-29, -48, 12, 12));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-46, -30, 12, 12));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-53, -6, 12, 12));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-47, 18, 12, 12));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-29, 35, 12, 12));
            break;
        case kASFeatureThicket:
            CGPathMoveToPoint(path, NULL, -12.5, 47.5);
            CGPathAddLineToPoint(path, NULL, 48.5, -14.5);
            CGPathMoveToPoint(path, NULL, -30.5, 29.5);
            CGPathAddLineToPoint(path, NULL, 31.5, -33.5);
            CGPathMoveToPoint(path, NULL, -48.5, 11.5);
            CGPathAddLineToPoint(path, NULL, 13.5, -50.5);
            CGPathMoveToPoint(path, NULL, 48.5, 14);
            CGPathAddLineToPoint(path, NULL, -12.5, -48);
            CGPathMoveToPoint(path, NULL, 31.5, 33.5);
            CGPathAddLineToPoint(path, NULL, -30.5, -29.5);
            CGPathMoveToPoint(path, NULL, 13.5, 50.5);
            CGPathAddLineToPoint(path, NULL, -48.5, -11.5);
            break;
        case kASFeatureLinearThicket:
            CGPathMoveToPoint(path, NULL, -49.5, -51.5);
            CGPathAddLineToPoint(path, NULL, -34.5, -35.5);
            CGPathMoveToPoint(path, NULL, 51.5, 49.5);
            CGPathAddLineToPoint(path, NULL, 35.5, 33.5);
            CGPathMoveToPoint(path, NULL, 18.5, 17.5);
            CGPathAddLineToPoint(path, NULL, 9.5, 7.5);
            CGPathMoveToPoint(path, NULL, -7.5, -8.5);
            CGPathAddLineToPoint(path, NULL, -17.5, -19.5);
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-37.5, -38.5, 23, 22));
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-10.5, -11.5, 23, 22));
            CGPathAddEllipseInRect(path, NULL, CGRectMake(15.5, 14.5, 23, 22));
            break;
        case kASFeatureVegetationBoundary:
            nonfilled = CGPathCreateMutable();
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-37, 41, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-20, 27, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-5, 17, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(11, 6, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(27, -5, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(11, -16, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-4, -27, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-20, -38, 11, 11));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-37, -49, 11, 11));
            break;
        case kASFeatureCopse:
            //// Color Declarations
            CGPathMoveToPoint(path, NULL, -36.5, -26.5);
            CGPathAddLineToPoint(path, NULL, -15.5, 40.5);
            CGPathAddLineToPoint(path, NULL, -0.5, -8.7);
            CGPathAddLineToPoint(path, NULL, 15.5, 40.5);
            CGPathAddLineToPoint(path, NULL, 36.5, -26.5);
            CGPathCloseSubpath(path);
            
            CGPathMoveToPoint(path, NULL, -14.5, -42.5);
            CGPathAddLineToPoint(path, NULL, -14.5, -25.5);
            CGPathMoveToPoint(path, NULL, 14.5, -26.5);
            CGPathAddCurveToPoint(path, NULL, 14.5, -41.5, 14.5, -42.5, 14.5, -42.5);
            break;
        case kASFeatureDistinctiveTree:
            CGPathMoveToPoint(path, NULL, -22.5, -26.5);
            CGPathAddLineToPoint(path, NULL, -1.5, 37.5);
            CGPathAddLineToPoint(path, NULL, 21.5, -26.5);
            CGPathAddLineToPoint(path, NULL, -22.5, -26.5);
            CGPathCloseSubpath(path);
            CGPathMoveToPoint(path, NULL, -1, -43);
            CGPathAddLineToPoint(path, NULL, -1, -26);
            break;
        case kASFeatureTreeStumpOrRootStock:
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-40.5, -39.5, 81, 81));
            CGPathMoveToPoint(path, NULL, -29.5, 28.5);
            CGPathAddLineToPoint(path, NULL, 29.5, -26.5);
            CGPathMoveToPoint(path, NULL, -28.5, -27.5);
            CGPathAddLineToPoint(path, NULL, 29.5, 28.5);
            break;
        case kASFeatureRoad:
            CGPathMoveToPoint(path, NULL, -48.5, -46.5);
            CGPathAddLineToPoint(path, NULL, 53.5, 55.5);
            break;
        case kASFeatureTrack:
            CGPathMoveToPoint(path, NULL, -52.5, -51.5);
            CGPathAddLineToPoint(path, NULL, -25.5, -25.5);
            CGPathMoveToPoint(path, NULL, -16.5, -16.5);
            CGPathAddLineToPoint(path, NULL, 13.5, 13.5);
            CGPathMoveToPoint(path, NULL, 22.5, 22.5);
            CGPathAddLineToPoint(path, NULL, 49.5, 49.5);
            break;
        case kASFeatureRide:
            nonfilled = CGPathCreateMutable();

            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-49, -31, 14, 14));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-35, -17, 14, 14));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-20, -2, 14, 14));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-5, 13, 14, 14));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(9, 27, 14, 14));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(24, 42, 14, 14));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-32, -46, 14, 14));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-18, -32, 14, 14));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-3, -17, 14, 14));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(12, -2, 14, 14));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(26, 12, 14, 14));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(41, 27, 14, 14));
            break;
        case kASFeatureBridge:
            CGPathMoveToPoint(path, NULL, -50.5, -22.5);
            CGPathAddLineToPoint(path, NULL, -32.5, -22.5);
            CGPathAddLineToPoint(path, NULL, 20.5, 31.5);
            CGPathAddLineToPoint(path, NULL, 20.5, 50.5);
            CGPathMoveToPoint(path, NULL, 51.5, 20.5);
            CGPathAddLineToPoint(path, NULL, 31.5, 20.5);
            CGPathAddLineToPoint(path, NULL, -21.5, -32.5);
            CGPathAddLineToPoint(path, NULL, -21.5, -50.5);
            break;
        case kASFeaturePowerLine:
            CGPathMoveToPoint(path, NULL, -51.5, -48.5);
            CGPathAddLineToPoint(path, NULL, 49.5, 52.5);
            CGPathMoveToPoint(path, NULL, -12.5, 14.5);
            CGPathAddLineToPoint(path, NULL, 8.5, -7.5);
            CGPathMoveToPoint(path, NULL, 19.5, 46.5);
            CGPathAddLineToPoint(path, NULL, 41.5, 24.5);
            CGPathMoveToPoint(path, NULL, -43.5, -16.5);
            CGPathAddLineToPoint(path, NULL, -22.5, -38.5);
            break;
        case kASFeaturePowerLinePylon:
            CGPathMoveToPoint(path, NULL, -49.5, -49.5);
            CGPathAddLineToPoint(path, NULL, 51.5, 51.5);
            CGPathMoveToPoint(path, NULL, -9.5, 11.5);
            CGPathAddLineToPoint(path, NULL, 11.5, -10.5);
            CGPathMoveToPoint(path, NULL, 19.5, 42.5);
            CGPathAddLineToPoint(path, NULL, 41.5, 20.5);
            CGPathMoveToPoint(path, NULL, -41.5, -17.5);
            CGPathAddLineToPoint(path, NULL, -20.5, -39.5);
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-29.5, -28.5, 60, 60));
            break;
        case kASFeatureTunnel:
            CGPathMoveToPoint(path, NULL, -38.5, 16.5);
            CGPathAddLineToPoint(path, NULL, 38.5, 16.5);
            CGPathMoveToPoint(path, NULL, -15.5, 39.5);
            CGPathAddLineToPoint(path, NULL, -0.5, 16.5);
            CGPathAddLineToPoint(path, NULL, 15.5, 38.5);
            CGPathMoveToPoint(path, NULL, -38.5, -14.5);
            CGPathAddLineToPoint(path, NULL, 38.5, -14.5);
            CGPathMoveToPoint(path, NULL, -15.5, -37.5);
            CGPathAddLineToPoint(path, NULL, -0.5, -14.5);
            CGPathAddLineToPoint(path, NULL, 15.5, -36.5);
            break;
        case kASFeatureStoneWall:
            CGPathMoveToPoint(path, NULL, -49.5, -49.5);
            CGPathAddLineToPoint(path, NULL, 49.5, 49.5);
            nonfilled = CGPathCreateMutable();
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-42.5, -41.5, 27, 27));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-13.5, -12.5, 27, 27));
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(16.5, 17.5, 27, 27));
            break;
        case kASFeatureFence:
            CGPathMoveToPoint(path, NULL, -34.5, -51.5);
            CGPathAddLineToPoint(path, NULL, -34.5, -20.5);
            CGPathAddLineToPoint(path, NULL, 35.5, 48.5);
            CGPathAddLineToPoint(path, NULL, 35.5, 19.5);
            CGPathMoveToPoint(path, NULL, -10.5, -27.5);
            CGPathAddLineToPoint(path, NULL, -10.5, 2.5);
            CGPathMoveToPoint(path, NULL, 13.5, -4.5);
            CGPathAddLineToPoint(path, NULL, 13.5, 27.5);
            break;
        case kASFeatureCrossingPoint:
            CGPathMoveToPoint(path, NULL, -52.5, -0.5);
            CGPathAddLineToPoint(path, NULL, -12.5, -0.5);
            CGPathMoveToPoint(path, NULL, -13.5, 39.5);
            CGPathAddLineToPoint(path, NULL, -13.5, -38.5);
            CGPathMoveToPoint(path, NULL, 15.5, 38.5);
            CGPathAddLineToPoint(path, NULL, 15.5, -38.5);
            CGPathMoveToPoint(path, NULL, 16.5, 0.5);
            CGPathAddLineToPoint(path, NULL, 53.5, 0.5);
            break;
        case kASFeatureBuilding:
            CGPathAddRect(path, NULL, CGRectMake(-43.5, -41.5, 85, 85));
            break;
        case kASFeaturePavedArea:
            CGPathAddRect(path, NULL, CGRectMake(-44.5, -44.5, 90, 88));
            CGPathMoveToPoint(path, NULL, -42.5, 9);
            CGPathAddLineToPoint(path, NULL, -6.5, 44);
            CGPathMoveToPoint(path, NULL, -45.5, -26.5);
            CGPathAddLineToPoint(path, NULL, 26.5, 44.5);
            CGPathMoveToPoint(path, NULL, -27, -45);
            CGPathAddLineToPoint(path, NULL, 45, 26);
            CGPathMoveToPoint(path, NULL, 7, -45);
            CGPathAddLineToPoint(path, NULL, 43, -10);
            break;
        case kASFeatureRuin:
            CGPathMoveToPoint(path, NULL, -40.5, 7.5);
            CGPathAddLineToPoint(path, NULL, -40.5, 38.5);
            CGPathAddLineToPoint(path, NULL, -7.5, 38.5);
            CGPathMoveToPoint(path, NULL, 38.5, 7.5);
            CGPathAddLineToPoint(path, NULL, 38.5, 38.5);
            CGPathAddLineToPoint(path, NULL, 6.5, 38.5);
            CGPathMoveToPoint(path, NULL, 38.5, -5.5);
            CGPathAddLineToPoint(path, NULL, 38.5, -40.5);
            CGPathAddLineToPoint(path, NULL, 6.5, -40.5);
            CGPathMoveToPoint(path, NULL, -40.5, -5.5);
            CGPathAddLineToPoint(path, NULL, -40.5, -40.5);
            CGPathAddLineToPoint(path, NULL, -8.5, -40.5);
            break;
        case kASFeaturePipeline:
            CGPathMoveToPoint(path, NULL, -45.5, -45.5);
            CGPathAddLineToPoint(path, NULL, 44.5, 45.5);
            CGPathMoveToPoint(path, NULL, -54.5, -21.5);
            CGPathAddLineToPoint(path, NULL, -21.5, -21.5);
            CGPathAddLineToPoint(path, NULL, -21.5, -50.5);
            CGPathMoveToPoint(path, NULL, -25.5, 7.5);
            CGPathAddLineToPoint(path, NULL, 7.5, 7.5);
            CGPathAddLineToPoint(path, NULL, 7.5, -21.5);
            CGPathMoveToPoint(path, NULL, 4, 38.5);
            CGPathAddLineToPoint(path, NULL, 37, 38.5);
            CGPathAddLineToPoint(path, NULL, 37, 9.5);
            break;
        case kASFeatureTower:
            CGPathMoveToPoint(path, NULL, -41.5, 39.5);
            CGPathAddLineToPoint(path, NULL, 40.5, 39.5);
            CGPathMoveToPoint(path, NULL, -0.5, 38.5);
            CGPathAddLineToPoint(path, NULL, -0.5, -40.5);
            break;
        case kASFeatureShootingPlatform:
            CGPathMoveToPoint(path, NULL, -19.5, -41.5);
            CGPathAddLineToPoint(path, NULL, -19.5, 38.5);
            CGPathAddLineToPoint(path, NULL, 23.5, 38.5);
            break;
        case kASFeatureCairn:
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-31.5, -31.5, 64, 64));
            nonfilled = CGPathCreateMutable();
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-10.5, -10.5, 21, 21));
            break;
        case kASFeatureFodderRack:
            CGPathMoveToPoint(path, NULL, -24.5, 25.5);
            CGPathAddLineToPoint(path, NULL, 0.5, 50.5);
            CGPathAddLineToPoint(path, NULL, 25.5, 26.5);
            CGPathMoveToPoint(path, NULL, 0.5, -48.5);
            CGPathAddLineToPoint(path, NULL, 0.5, 51.5);
            CGPathMoveToPoint(path, NULL, -24.5, -48.5);
            CGPathAddLineToPoint(path, NULL, 26.5, -48.5);
            break;
        case kASFeatureCharcoalBurningGround:
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-46, -46, 92, 92));
            CGPathMoveToPoint(path, NULL, -39.5, -21.5);
            CGPathAddLineToPoint(path, NULL, 39.5, -21.5);
            CGPathAddLineToPoint(path, NULL, -0.5, 45.5);
            CGPathAddLineToPoint(path, NULL, -39.5, -21.5);
            CGPathCloseSubpath(path);
            break;
        case kASFeatureMonument:
            CGPathMoveToPoint(path, NULL, -46.5, -43.5);
            CGPathAddLineToPoint(path, NULL, 45.5, -43.5);
            CGPathMoveToPoint(path, NULL, -27.5, -43.5);
            CGPathAddLineToPoint(path, NULL, -0.5, 42.5);
            CGPathAddLineToPoint(path, NULL, 27.5, -42.5);
            break;
        case kASFeatureBuildingPassThrough:
            CGPathMoveToPoint(path, NULL, -29.5, -47.5);
            CGPathAddLineToPoint(path, NULL, -29.5, 43.5);
            CGPathMoveToPoint(path, NULL, 29.5, -47.5);
            CGPathAddLineToPoint(path, NULL, 29.5, 43.5);
            CGPathMoveToPoint(path, NULL, -46.5, 43.5);
            CGPathAddLineToPoint(path, NULL, 46.5, 43.5);
            break;
        case kASFeatureStairway:
            CGPathMoveToPoint(path, NULL, -46.5, -34.5);
            CGPathAddLineToPoint(path, NULL, -22.5, -34.5);
            CGPathAddLineToPoint(path, NULL, -22.5, -12.5);
            CGPathAddLineToPoint(path, NULL, -0.5, -12.5);
            CGPathAddLineToPoint(path, NULL, -0.5, 9.5);
            CGPathAddLineToPoint(path, NULL, 22.5, 9.5);
            CGPathAddLineToPoint(path, NULL, 22.5, 32.5);
            CGPathAddLineToPoint(path, NULL, 45.5, 32.5);
            break;
        case kASFeatureSpecialItem1:
            CGPathMoveToPoint(path, NULL, -32.5, -33.5);
            CGPathAddLineToPoint(path, NULL, 33.5, 32.5);
            CGPathMoveToPoint(path, NULL, -32.5, 32.5);
            CGPathAddLineToPoint(path, NULL, 32.5, -33.5);
            break;
        case kASFeatureSpecialItem2:
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-51, -51, 102, 102));
            break;
        default:
            
            break;
    }
    CGFloat lw = THIN_LINE;
    if (tran != NULL) lw /= tran->a;
    fillable = CGPathCreateCopyByStrokingPath(path, tran, lw, kCGLineCapButt, kCGLineJoinBevel, 0.0);
    CGPathRelease(path);
    NSArray *pathArray;
    if (nonfilled != NULL) {
        pathArray = @[(__bridge id)fillable, (__bridge id)nonfilled];
        CGPathRelease(nonfilled);
    } else {
        pathArray = @[(__bridge id)fillable];
    }
    CGPathRelease(fillable);
    
    return pathArray;
}

- (void)setValue:(NSNumber *)value forColumn:(enum ASControlDescriptionColumn)column {
    NSAssert(NO, @"A regular ASControlDescriptionView is not editable.");
}

@end
