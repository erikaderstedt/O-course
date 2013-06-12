//
//  CoordinateTransverser.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-09-28.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "CoordinateTransverser.h"

CGFloat ocad_distance_between_points(CGPoint p1, CGPoint p2) {
    // According to purple-pen, OCAD does not calculate distance normally. Instead it is approximated using the 'Bizarro' (their name)
    // distance metric.
    
    float dx = p2.x - p1.x;
    float dy = p2.y - p1.y;
    float bd = fmaxf(dx, dy);
    float ld = fminf(dx, dy);
    return 0.5*(bd+ld);    
}

CGFloat regular_distance_between_points(CGPoint p1, CGPoint p2) {
    return sqrtf((p2.x-p1.x)*(p2.x-p1.x) + (p2.y-p1.y)*(p2.y-p1.y));
}

CGPoint bezierCurvePoint(float t, CGPoint p0, CGPoint cp1, CGPoint cp2, CGPoint p1) {
    CGPoint bp;
    bp.x = p1.x*t*t*t + 3.0*cp2.x*t*t*(1.0-t) + 3.0*cp1.x*t*(1.0-t)*(1.0-t) + p0.x*(1.0-t)*(1.0-t)*(1.0-t);
    bp.y = p1.y*t*t*t + 3.0*cp2.y*t*t*(1.0-t) + 3.0*cp1.y*t*(1.0-t)*(1.0-t) + p0.y*(1.0-t)*(1.0-t)*(1.0-t);
    return bp;
}

void splitBezier(float t, CGPoint p0, CGPoint cp1, CGPoint cp2, CGPoint p1, CGPoint *points) {
    float s = 1.0 - t;
    CGPoint f00t, f01t, f11t, f0tt, f1tt, fttt;
    
    f00t.x = s * p0.x + t * cp1.x;
    f00t.y = s * p0.y + t * cp1.y;
    f01t.x = s * cp1.x + t * cp2.x;
    f01t.y = s * cp1.y + t * cp2.y;
    f11t.x = s * cp2.x + t * p1.x;
    f11t.y = s * cp2.y + t * p1.y;
    f0tt.x = s * f00t.x + t * f01t.x;
    f0tt.y = s * f00t.y + t * f01t.y;
    f1tt.x = s * f01t.x + t * f11t.x;
    f1tt.y = s * f01t.y + t * f11t.y;
    fttt.x = s * f0tt.x + t * f1tt.x;
    fttt.y = s * f0tt.y + t * f1tt.y;
    
    points[0] = p0;
    points[1] = f00t;
    points[2] = f0tt;
    points[3] = fttt;
    points[4] = fttt;
    points[5] = f1tt;
    points[6] = f11t;
    points[7] = p1;
}

CGFloat angle_between_points(CGPoint p1, CGPoint p2) {
    return atan2(p2.y - p1.y, p2.x - p1.x);
}

CGPoint translatePoint(CGPoint p, float distance, float angle) {
    CGPoint q;
    q.x = p.x + cosf(angle)*distance;
    q.y = p.y + sinf(angle)*distance;
    return q;
}

@implementation CoordinateTransverser

@synthesize translateDistanceLeft, translateDistanceRight;

- (id)initWith:(int)num_coords coordinates:(struct TDPoly *)coords withPath:(CGMutablePathRef)path {
    if ((self = [super init])) {
        _coords = coords;
        _path = path;
        _num_coords = num_coords;
        
        [self reset];
        [self setPath:path];
    }
    return self;
}

- (void)dealloc {
    if (_path != NULL) {
        CGPathRelease(_path);
    }
    if (_leftPath != NULL) {
        CGPathRelease(_leftPath);
    }
    if (_rightPath != NULL) {
        CGPathRelease(_rightPath);
    }
}

- (void)reset {
    currentIndex = 0;
    currentFraction = 0.0;
    [self setPath:NULL];
    [self setRightPath:NULL];
    [self setLeftPath:NULL];
}

- (void)setPath:(CGMutablePathRef)newPath {
    if (_path != NULL) {
        CGPathRelease(_path);
        _path = NULL;
    }
    _path = newPath;
    if (_path != NULL) {
        CGPathRetain(_path);
        CGPoint p0 = [self coordinateAtIndex:0];
        CGPathMoveToPoint(_path, NULL, p0.x, p0.y);
    }
}

- (void)setLeftPath:(CGMutablePathRef)newPath {
    if (_leftPath != NULL) {
        CGPathRelease(_leftPath);
        _leftPath = NULL;
    }
    _leftPath = newPath;
    if (_leftPath != NULL) {
        int j = currentIndex;
        currentIndex = 0;
        CGPoint p0 = [self coordinateAtIndex:0];
        CGFloat a = [self currentAngle];
        p0 = translatePoint(p0, self.translateDistanceLeft, a + M_PI/2);
        CGPathMoveToPoint(_leftPath, NULL, p0.x, p0.y);
        currentIndex = j;
        CGPathRetain(_leftPath);
    }
}

- (void)setRightPath:(CGMutablePathRef)newPath {
    if (_rightPath != NULL) {
        CGPathRelease(_rightPath);
        _rightPath = NULL;
    }
    _rightPath = newPath;
    if (_rightPath != NULL) {
        int j = currentIndex;
        currentIndex = 0;
        CGPoint p0 = [self coordinateAtIndex:0];
        CGFloat a = [self currentAngle];
        p0 = translatePoint(p0, self.translateDistanceRight, a - M_PI/2);
        CGPathMoveToPoint(_rightPath, NULL, p0.x, p0.y);
        currentIndex = j;
        CGPathRetain(_rightPath);
    }
}

- (CGPoint)coordinateAtIndex:(int)i {
    return CGPointMake(XVAL(i), YVAL(i));
}

- (BOOL)endHasBeenReached {
    return currentIndex >= _num_coords - 1;
}

- (void)goToEnd {
    currentIndex = _num_coords - 1;
    currentFraction = 0.0;
}

- (BOOL)onFirstSegment {
    return currentIndex == 0;
}

- (BOOL)onLastSegment {
    int i;
    for (i = currentIndex + 1; i < _num_coords; i++) {
        if (CORNERPOINT(i)) return NO;
    }
    return YES;
}

- (CGFloat)lengthOfElementAtIndex:(int)i nextElement:(int *)next {
    // Calculate the length of a single element (straight line or bezier curve).
    int steps;
    CGPoint p0, p1;
    CGFloat d;
    int bezierIndex;
    
    p0 = [self coordinateAtIndex:i];
    p1 = [self coordinateAtIndex:i+1];

    if (BEZIERCONTROLPOINT(i+1)) {
        CGPoint cp1, cp2, pa, pb;
        float bezierParameter;
        cp1 = p1;
        cp2 = [self coordinateAtIndex:i+2];
        p1 = [self coordinateAtIndex:i+3];
        
        pa = p0;
        d = 0;        
        for (bezierIndex = 1; bezierIndex < BEZIER_STEPS; bezierIndex++) {
            bezierParameter = ((CGFloat)bezierIndex)/(BEZIER_STEPS - 1);
            pb = bezierCurvePoint(bezierParameter, p0, cp1, cp2, p1);
            d += regular_distance_between_points(pa, pb);
            pa = pb;
        }        
        steps = 3;
    } else {
        d = regular_distance_between_points(p1, p0);
        steps = 1;
    }
    
    if (next != NULL) {
        *next = i + steps;
    }
    
    return d; 
}


- (CGFloat)lengthOfCurrentSegment {
    return [self lengthOfSegmentAtIndex:currentIndex nextSegment:NULL];
}

- (CGFloat)lengthOfSegmentAtIndex:(int)i nextSegment:(int *)next {
    // Calculate the length of a single segment (up until the next corner point).
    CGFloat d = 0.0;
    int j;
    
    do {
        d += [self lengthOfElementAtIndex:i nextElement:&j];
        i = j;
    } while (i < _num_coords - 1 && !CORNERPOINT(i));
    
    if (next != NULL) {
        *next = i;
    }
    
    return d;
    
}

- (float)lengthOfEntirePath {
    int i, j;
    float d = 0.0;
    
    for (i = 0; i < _num_coords - 1; i = j) {
        d += [self lengthOfElementAtIndex:i nextElement:&j];
    }
    
    return d;
}

- (BOOL)atCornerPoint {
    if (currentIndex == _num_coords) return NO;
    return CORNERPOINT(currentIndex);
}

- (CGPoint)currentPoint {
    CGPoint p0, p1, cp1, cp2;
    p0 = [self coordinateAtIndex:currentIndex];
    
    if (currentFraction == 0.0) {
        return p0;
    }
    
    NSAssert(currentIndex < _num_coords - 1, @"If we're at the last point, current fraction should have been zero.");
    
    if (BEZIERCONTROLPOINT(currentIndex + 1)) {
        p1 = [self coordinateAtIndex:currentIndex + 3];
        cp1 = [self coordinateAtIndex:currentIndex + 1];
        cp2 = [self coordinateAtIndex:currentIndex + 2];
        return bezierCurvePoint(currentFraction, p0, cp1, cp2, p1);
    } else {
        p1 = [self coordinateAtIndex:currentIndex + 1];        
    }
    
    return CGPointMake(p0.x*(1.0-currentFraction) + p1.x*currentFraction, p0.y*(1.0-currentFraction)+p1.y*currentFraction);
}

- (CGFloat)currentAngle {
    CGFloat angle;
    CGPoint p0, pm, pp;
    
    p0 = [self coordinateAtIndex:currentIndex];
    
    if (currentIndex == _num_coords - 1) {
        if (currentIndex == 0) {
            return 0.0;
        } else {
            pm = [self coordinateAtIndex:currentIndex-1];
            angle = angle_between_points(pm, p0);
        }
    } else if (currentIndex == 0) {
        pp = [self coordinateAtIndex:currentIndex+1];
        angle = angle_between_points(p0, pp);
    } else {
        float oangle;
        pm = [self coordinateAtIndex:currentIndex-1];
        pp = [self coordinateAtIndex:currentIndex+1];
        angle = angle_between_points(p0, pp);
        oangle = angle_between_points(pm, p0);
        angle = atan2(sin(angle)+sin(oangle), cos(angle) + cos(oangle));
    }
    
    return angle;
}

- (CGPoint)advanceSegmentWhileStroking:(BOOL)stroke {
    CGPoint p1 = CGPointMake(0.0, 0.0), cp1, cp2;
    BOOL atNextCornerPoint = NO;
    
    // Assumes that the current point is at p0.
    
    while (!atNextCornerPoint && currentIndex < _num_coords - 1) {
        if (BEZIERCONTROLPOINT(currentIndex + 1)) {
            p1 = [self coordinateAtIndex:currentIndex+3];
            if (stroke) {
                cp1 = [self coordinateAtIndex:currentIndex + 1];
                cp2 = [self coordinateAtIndex:currentIndex + 2];
                CGPathAddCurveToPoint(_path, NULL, cp1.x, cp1.y, cp2.x, cp2.y, p1.x, p1.y);
                if (_leftPath != NULL || _rightPath != NULL) {
                    CGFloat startAngle = [self currentAngle], stopAngle;
                    
                    currentIndex += 3;
                    stopAngle = [self currentAngle];
                    currentIndex -= 3;
                    
                    // Translate p0 and cp1 according to the start angle, and cp2 and p1 according to the stop angle.
                    if (_leftPath != NULL) {
                        CGPoint p1l, cp1l, cp2l;
                        cp1l = translatePoint(cp1, translateDistanceLeft, startAngle + M_PI/2);
                        cp2l = translatePoint(cp2, translateDistanceLeft, stopAngle + M_PI/2);
                        p1l = translatePoint(p1, translateDistanceLeft, stopAngle + M_PI/2);
                        CGPathAddCurveToPoint(_leftPath, NULL, cp1l.x, cp1l.y, cp2l.x, cp2l.y, p1l.x, p1l.y);
                    }
                    if (_rightPath != NULL) {
                        CGPoint p1r, cp1r, cp2r;
                        cp1r = translatePoint(cp1, translateDistanceRight, startAngle - M_PI/2);
                        cp2r = translatePoint(cp2, translateDistanceRight, stopAngle - M_PI/2);
                        p1r = translatePoint(p1, translateDistanceRight, stopAngle - M_PI/2);
                        CGPathAddCurveToPoint(_rightPath, NULL, cp1r.x, cp1r.y, cp2r.x, cp2r.y, p1r.x, p1r.y);                       
                    }
                }
            }
            currentIndex += 3;
        } else {
            currentIndex ++;
            p1 = [self coordinateAtIndex:currentIndex];
            if (stroke) {
                CGPathAddLineToPoint(_path, NULL, p1.x, p1.y);    
                if (_leftPath != NULL || _rightPath != NULL) {
                    CGFloat a;
                    a = [self currentAngle];
                    CGPoint pt;
                    if (_leftPath != NULL) {
                        pt = translatePoint(p1, translateDistanceLeft, a + M_PI/2);
                        CGPathAddLineToPoint(_leftPath, NULL, pt.x, pt.y);
                    }
                    if (_rightPath != NULL) {
                        pt = translatePoint(p1, translateDistanceRight, a - M_PI/2);
                        CGPathAddLineToPoint(_rightPath, NULL, pt.x, pt.y);
                    }
                }
            }
        }
        atNextCornerPoint = ((currentIndex < _num_coords) && CORNERPOINT(currentIndex));
    }
    
    if (!stroke) {
        if (_path != NULL) {
            CGPathMoveToPoint(_path, NULL, p1.x, p1.y);
        }
        if (_leftPath != NULL || _rightPath != NULL) {
            CGFloat a = [self currentAngle];
            CGPoint pt;

            if (_leftPath != NULL) {
                pt = translatePoint(p1, translateDistanceLeft, a + M_PI/2);
                CGPathMoveToPoint(_leftPath, NULL, pt.x, pt.y);
            }
            if (_rightPath != NULL) {
                pt = translatePoint(p1, translateDistanceRight, a - M_PI/2);
                CGPathMoveToPoint(_rightPath, NULL, pt.x, pt.y);
            }
        }
    }
    
    return p1;
}

// 
// Advance distances. These methods do not yet support double lines. That might be a lot of work. The main
// reason why it isn't done is that I don't have a file with this feature to test on.
//

- (CGPoint)advanceDistance:(CGFloat)distance {
    return [self advanceDistance:distance stroke:NO];
}

- (CGPoint)advanceDistance:(CGFloat)distance stroke:(BOOL)stroke {
    CGFloat remaining_distance = distance;
    CGFloat t;
    CGPoint p0, p1, cp1, cp2;
    CGPoint buffer1[8], buffer2[8];
    CGPoint stop;
    int j;
    
    if (distance == 0.0) return [self currentPoint];
        
    while (remaining_distance > 0 && currentIndex < _num_coords - 1) {
        p0 = [self coordinateAtIndex:currentIndex];
        if (BEZIERCONTROLPOINT(currentIndex + 1)) {
            p1 = [self coordinateAtIndex:currentIndex + 3];
            cp1 = [self coordinateAtIndex:currentIndex + 1];
            cp2 = [self coordinateAtIndex:currentIndex + 2];
            CGPoint bp = CGPointMake(0.0, 0.0), p;
            CGFloat stepDist;
            
            p = bezierCurvePoint(currentFraction, p0, cp1, cp2, p1);
            
            for (t = currentFraction + BEZIER_STEP; t <= 1.0 && remaining_distance > 0.0; t += BEZIER_STEP) {
                bp = bezierCurvePoint(t, p0, cp1, cp2, p1);
                stepDist = regular_distance_between_points(p, bp);
                if (remaining_distance < stepDist) {
                    t -= BEZIER_STEP * (stepDist - remaining_distance) / stepDist;
                    bp = bezierCurvePoint(t, p0, cp1, cp2, p1);
                    remaining_distance = 0.0;
                } else {
                    remaining_distance -= stepDist;
                    p = bp;
                }
            }
            
            if (_path != NULL) {
                if (stroke) {
                    // Construct a new bezier curve from currentFraction to t.
                    if (currentFraction > 0.0) {
                        splitBezier(currentFraction, p0, cp1, cp2, p1, buffer1);
                    } else {
                        buffer1[4] = p0;
                        buffer1[5] = cp1;
                        buffer1[6] = cp2;
                        buffer1[7] = p1;                        
                    }
                    if (t < 1.0) {
                        splitBezier((t - currentFraction)/(1.0-currentFraction), buffer1[4], buffer1[5],buffer1[6],buffer1[7], buffer2);
                    } else {
                        for (j = 0; j < 4; j++) buffer2[j] = buffer1[j+4];
                    }
                    CGPathAddCurveToPoint(_path, NULL, buffer2[1].x, buffer2[1].y, buffer2[2].x, buffer2[2].y, buffer2[3].x, buffer2[3].y);
                } else {
                    CGPathMoveToPoint(_path, NULL, bp.x, bp.y);
                }
            }
            if (remaining_distance == 0.0) {
                currentFraction = t;
                stop = bezierCurvePoint(currentFraction, p0, cp1, cp2, p1);
            } else {
                // Entire element consumed.
                currentFraction = 0.0;
                currentIndex += 3;
            }
        } else {
            p1 = [self coordinateAtIndex:currentIndex+1];
            CGFloat d = regular_distance_between_points(p0,p1);
            if ((1.0 - currentFraction)*d < remaining_distance) {
                // The entire element will be consumed.
                if (_path != NULL) {
                    if (stroke) {
                        CGPathAddLineToPoint(_path, NULL, p1.x, p1.y);
                    } else {
                        CGPathMoveToPoint(_path, NULL, p1.x, p1.y);
                    }
                }
                remaining_distance -= (1.0 - currentFraction)*d;
                currentFraction = 0.0;
                currentIndex ++;
            } else {
                // There will be some left.
                float newFraction = remaining_distance / d + currentFraction;
                stop.x = p0.x*(1.0-newFraction) + p1.x*newFraction;
                stop.y = p0.y*(1.0-newFraction) + p1.y*newFraction;
                if (_path != NULL) {
                    if (stroke) {
                        CGPathAddLineToPoint(_path, NULL, stop.x, stop.y);
                    } else {
                        CGPathMoveToPoint(_path, NULL, stop.x, stop.y);
                    }
                }
                remaining_distance = 0.0;
                currentFraction = newFraction;
            }
        }
    }
    
    return stop;
}


@end