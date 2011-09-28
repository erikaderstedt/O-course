//
//  CoordinateTransverser.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-09-28.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASOCADController.h"

#define XVAL(i) ((CGFloat)(_coords[i].x >> 8))
#define YVAL(i) ((CGFloat)(_coords[i].y >> 8))
#define CORNERPOINT(i) ((BOOL)(_coords[i].y & 1))
#define BEZIERCONTROLPOINT(i) ((BOOL)(_coords[i].x & 1))

CGFloat ocad_distance_between_points(CGPoint p1, CGPoint p2);
CGFloat regular_distance_between_points(CGPoint p1, CGPoint p2);
CGPoint bezierCurvePoint(float t, CGPoint p0, CGPoint cp1, CGPoint cp2, CGPoint p1);
void splitBezier(float t, CGPoint p0, CGPoint cp1, CGPoint cp2, CGPoint p1, CGPoint *points);
CGFloat angle_between_points(CGPoint p0, CGPoint p1);

#define BEZIER_STEPS 100
#define BEZIER_STEP 0.01

@interface CoordinateTransverser : NSObject {
@private
    int currentIndex;
    CGFloat currentFraction;
    
    struct TDPoly *_coords;
    int _num_coords;
    CGMutablePathRef _path;
}

- (id)initWith:(int)num_coords coordinates:(struct TDPoly *)coords withPath:(CGMutablePathRef)path;
- (BOOL)endHasBeenReached;
- (BOOL)onFirstSegment;
- (BOOL)onLastSegment;

- (void)reset;
- (void)setPath:(CGMutablePathRef)newPath;

- (CGPoint)coordinateAtIndex:(int)i;

- (BOOL)atCornerPoint;

- (CGFloat)currentAngle;
- (CGPoint)currentPoint;

- (CGPoint)advanceSegmentWhileStroking:(BOOL)stroke;
- (CGPoint)advanceDistance:(CGFloat)distance;
- (CGPoint)advanceDistance:(CGFloat)distance stroke:(BOOL)s;

- (CGFloat)lengthOfElementAtIndex:(int)i nextElement:(int *)next;
- (CGFloat)lengthOfCurrentSegment;
- (CGFloat)lengthOfSegmentAtIndex:(int)i nextSegment:(int *)next;
- (float)lengthOfEntirePath;

@end