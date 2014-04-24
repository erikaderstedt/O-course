//
//  ASOcourseDocument.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-02-06.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASOcourseDocument.h"
#import "ASOCADController.h"
#import "ASGenericImageController.h"
#import "ASMapView.h"
#import "ASMapView+Layout.h"
#import "Project.h"
#import "OverprintObject.h"
#import "CourseObject.h"
#import "Course.h"
#import "ASMapPrintingView.h"
#import "BackgroundMap.h"

#import "ASOverprintController.h"
#import "ASCourseController.h"
#import "ASControlDescriptionView.h"
#import "MyDocumentController.h"
#import "ASControlDescriptionProvider.h"

@implementation ASOcourseDocument

@synthesize mapView;
@synthesize overprintController, courseController;
@synthesize projectController;
@synthesize mapURL;

- (Project *)project {
    Project *p = [Project projectInManagedObjectContext:[self managedObjectContext]];
    if (p == nil) {
        NSLog(@"No project!");
    }
    return p;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"ASOcourseDocument";
}

+ (NSWindow *)windowForManagedObjectContext:(NSManagedObjectContext *)context {
    for (ASOcourseDocument *doc in [[NSDocumentController sharedDocumentController] documents]) {
        if ([doc managedObjectContext] == context) {
            if ([[doc windowControllers] count] > 0)
                return [[doc windowControllers][0] window];
            return nil;
        }
    }
    return nil;
}

#pragma mark -
#pragma mark Map loading

- (void)clearMapBookmarks {
    NSFetchRequest *f = [NSFetchRequest fetchRequestWithEntityName:@"BackgroundMap"];
    NSArray *a = [self.managedObjectContext executeFetchRequest:f error:nil];
    for (BackgroundMap *map in a) {
        map.project = nil;
        [self.managedObjectContext deleteObject:map];
    }
}

- (IBAction)chooseBackgroundMap:(id)sender {
    NSOpenPanel *op = [MyDocumentController openPanelForBackgroundMap];

    [op beginSheetModalForWindow:[mapView window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [self setMapURL:[op URL]];
        }
    }];
}

- (void)setMapURL:(NSURL *)u {
    // Requires that the url has been added to our sandbox.
    [[self undoManager] disableUndoRegistration];
    [self clearMapBookmarks];
    [self addMapURL:u filename:nil];
    [[self undoManager] enableUndoRegistration];
    
    [self updateMap:nil];
}

- (id <ASMapProvider>)mapProviderForURL:(NSURL *)u primaryTransform:(CGAffineTransform)primary secondaryTransform:(CGAffineTransform)secondary {
    id <ASMapProvider> provider = nil;
    // This may trigger the loading of background images, too.
    // The
    if (u != nil) {
        [u startAccessingSecurityScopedResource];
        
        NSString *s = [u path];
        if ([[[s pathExtension] lowercaseString] isEqualToString:@"ocd"]) {
            ASOCADController *o = [[ASOCADController alloc] initWithOCADFile:s];
            [o prepareCacheWithAreaTransform:primary secondaryTransform:secondary];
            [o loadAdditionalResourcesWithDelegate:self];
            provider = o;
        } else {
            ASGenericImageController *i = [[ASGenericImageController alloc] initWithContentsOfFile:s];
            provider = i;
        }
        
        [u stopAccessingSecurityScopedResource];
    }
    return provider;
}

- (void)updateMap:(NSNotification *)n {
    if (self.mapView == nil) {
        return;
    }

    NSURL *u = [[BackgroundMap topInManagedObjectContext:self.managedObjectContext] resolvedURL];
    if (u == nil || [u isEqual:self.loadedURL]) return;
    
    self.mapView.mapProvider = [self mapProviderForURL:u primaryTransform:CGAffineTransformIdentity secondaryTransform:CGAffineTransformMakeScale(GLASS_SIZE/ACROSS_GLASS, GLASS_SIZE/ACROSS_GLASS)];
    [[self project] setValue:@([self.mapView.mapProvider nativeScale]) forKey:@"scale"];
    
    self.loadedURL = u;
    
    if (self.mapView.mapProvider != nil) {
        Project *p = [self project];
        CGRect r = [self.mapView.mapProvider mapBounds];

        CGFloat x = round(CGRectGetMidX(r));
        CGFloat y = round(CGRectGetMidY(r));
        CGPoint op = p.centerPosition;
        if (op.x != x || op.y != y) {
            p.centerPosition = CGPointMake(x, y);
        }
    }
    [self.mapView mapLoaded];
}

- (void)loadCoursesFromMap {
    [self.mapView.mapProvider loadOverprintObjects:^id(CGFloat position_x, CGFloat position_y, enum ASOverprintObjectType otp, NSInteger controlCode, enum ASWhichOfAnySimilarFeature which, enum ASFeature feature, enum ASAppearance appearance, enum ASDimensionsOrCombination dim, enum ASLocationOfTheControlFlag flag, enum ASOtherInformation other) {
        NSLog(@"adding overprint objects %d", [NSThread isMainThread]);
        OverprintObject *o = [NSEntityDescription insertNewObjectForEntityForName:@"OverprintObject" inManagedObjectContext:self.managedObjectContext];
        o.position_x = @(position_x);
        o.position_y = @(position_y);
        o.objectType = otp;
        o.controlCode = @(controlCode);
        o.whichOfAnySimilarFeature = @(which);
        o.controlFeature = @(feature);
        o.appearanceOrSecondControlFeature = @(appearance);
        o.combinationSymbol = @(dim);
        o.locationOfTheControlFlag = @(flag);
        o.otherInformation = @(other);
        return o;
    } courses:^(NSString *name, NSArray *overprintObjects) {
        NSLog(@"adding course %d", [NSThread isMainThread]);
        Course *c = [NSEntityDescription insertNewObjectForEntityForName:@"Course" inManagedObjectContext:self.managedObjectContext];
        [c setValue:self.project forKey:@"project"];
        c.name = name;
        for (OverprintObject *o in overprintObjects) {
            CourseObject *co = [NSEntityDescription insertNewObjectForEntityForName:@"CourseObject" inManagedObjectContext:self.managedObjectContext];
            co.overprintObject = o;
            co.course = c;
        }
        [c recalculateControlNumberPositions];
    }];
    [self.courseController updateCoursePopup];
    [self.overprintController updateOverprint];
}

- (BackgroundMap *)mapInfoForFile:(NSString *)file {
    NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName:@"BackgroundMap"];
    [r setPredicate:[NSPredicate predicateWithFormat:@"filename == %@", file]];
    NSArray *a = [self.managedObjectContext executeFetchRequest:r error:nil];
    if ([a count] == 0) return nil;
    
    BackgroundMap *map = a[0];
    return map;
}

#pragma mark -
#pragma mark ASBackgroundImageLoaderDelegate

- (NSNotification *)mapChangeNotification {
    if (self.mapView.state == kASMapViewLayout) {
        return nil;
    }
    return [NSNotification notificationWithName:@"ASMapChanged" object:self.managedObjectContext];
}

- (dispatch_semaphore_t)imageLoaderSequentializer {
    if (loader == NULL) {
        loader = dispatch_semaphore_create(1);
    }
    return loader;
}

- (dispatch_queue_t)imageLoaderQueue {
    if (queue == NULL) {
        queue = dispatch_queue_create("imageLoader", DISPATCH_QUEUE_PRIORITY_DEFAULT);
    }
    return queue;
}

- (NSWindow *)modalWindow {
    NSArray *a = [self windowControllers];
    if ([a count] == 0) return nil;
    NSWindowController *wc = [a objectAtIndex:0];
    if ([wc isWindowLoaded]) return [wc window];
    return nil;
}

- (NSURL *)resolvedURLBookmarkForFilename:(NSString *)name {
    return [[self mapInfoForFile:name] resolvedURL];
}

- (void)addMapURL:(NSURL *)url filename:(NSString *)filename {
    BackgroundMap *map = [self mapInfoForFile:filename];
    if (map == nil) {
        map = [NSEntityDescription insertNewObjectForEntityForName:@"BackgroundMap" inManagedObjectContext:self.managedObjectContext];
        map.project = self.project;
        map.filename = filename;
        map.ignored = NO;
        [map setURL:url];
    } else {
        map.ignored = NO;
        [map setURL:url];
    }
}
- (BOOL)isIgnoringFilename:(NSString *)path {
    BackgroundMap *map = [self mapInfoForFile:path];
    return map.ignored;
}

- (void)ignoreFurtherRequestsForFile:(NSString *)file {
    BackgroundMap *map = [self mapInfoForFile:file];
    if (map == nil) {
        map = [NSEntityDescription insertNewObjectForEntityForName:@"BackgroundMap" inManagedObjectContext:self.managedObjectContext];
        map.project = self.project;
        map.filename = file;
        map.ignored = YES;
        map.bookmark = nil;
    } else {
        map.ignored = YES;
        map.bookmark = nil;
    }
}

#pragma mark -

- (void)awakeFromNib {
    [self.courseController setManagedObjectContext:[self managedObjectContext]];
    [self.courseController willAppear];
    
    self.mapView.overprintProvider = self.overprintController;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(undoOrRedo:) name:NSUndoManagerDidUndoChangeNotification object:[[self managedObjectContext] undoManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(undoOrRedo:) name:NSUndoManagerDidRedoChangeNotification object:[[self managedObjectContext] undoManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showEventInfoPopupForNotification:) name:@"ASEditEventName" object:[self managedObjectContext]];

    if (self.mapView.mapProvider == nil) [self updateMap:nil];
}

- (void)undoOrRedo:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ASCourseChanged" object:self.managedObjectContext userInfo:nil];;
    [self.mapView.controlDescriptionView setNeedsDisplay:YES];
    [self.mapView decorChanged:nil];
    [self.mapView maskedAreasChanged:nil];
}

- (void)windowWillClose:(NSNotification *)notification {
    [self.overprintController teardown];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUndoManagerDidRedoChangeNotification object:[[self managedObjectContext] undoManager]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUndoManagerDidUndoChangeNotification object:[[self managedObjectContext] undoManager]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ASEditEventName" object:nil];
    
    [self.courseController setManagedObjectContext:nil];
    [self.courseController willDisappear];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == projectController) {
        [self updateMap:nil];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)zoomIn:(id)sender {
    mapView.zoom = (1.1)* mapView.zoom;
}
- (IBAction)zoomOut:(id)sender {
    mapView.zoom = (1.0/1.1)* mapView.zoom;
}

- (void)duplicateDocumentWithDelegate:(id)delegate didDuplicateSelector:(SEL)didDuplicateSelector contextInfo:(void *)contextInfo {
    [super duplicateDocumentWithDelegate:delegate didDuplicateSelector:@selector(document:didDuplicate:contextInfo:) contextInfo:contextInfo];
}

- (void)document:(ASOcourseDocument *)document didDuplicate:(BOOL)didDuplicate contextInfo:(void *)contextInfo {
    [document updateMap:nil];
}

- (IBAction)printDocument:(id)sender {
    if (self.mapView.state != kASMapViewLayout) {
        [self.mapView enterLayoutMode:sender];
    } else {
        // Start a printing operation based on the orientation in the base view.
        NSPrintInfo *pi = [[NSPrintInfo alloc] initWithDictionary:[[NSPrintInfo sharedPrintInfo] dictionary]];
        ASMapPrintingView *pv = [[ASMapPrintingView alloc] initWithBaseView:self.mapView];
        pv.mapProvider = [self mapProviderForURL:self.loadedURL primaryTransform:CGAffineTransformIdentity secondaryTransform:[pv patternTransform]];
        NSString *jobTitle = self.project.event;
        if ([self.courseController specificCourseSelected]) {
            jobTitle = [jobTitle stringByAppendingFormat:@" %@", [self.courseController classNames]];
        }
        size_t numberOfHiddenSymbols;
        const int32_t *hiddenSymbols = [[self.mapView.mapProvider layoutProxy] hiddenSymbolNumbers:&numberOfHiddenSymbols];
        [[pv.mapProvider layoutProxy] setHiddenSymbolNumbers:hiddenSymbols count:numberOfHiddenSymbols];
        [pi setTopMargin:0.0];
        [pi setBottomMargin:0.0];
        [pi setLeftMargin:0.0];
        [pi setRightMargin:0.0];
        [pi setOrientation:self.mapView.orientation];
        [pi setPaperSize:[pv rectForPage:1].size];
        [pi setHorizontalPagination:NSClipPagination];
        [pi setVerticalPagination:NSClipPagination];
        [pi setHorizontallyCentered:YES];
        [pi setVerticallyCentered:YES];
        
        PMPrintSettings ps = [pi PMPrintSettings];
        NSNumber *colorMode = @(3);
        NSNumber *quality = @(2);
        NSNumber *pmOrientation = @(1+((int)self.mapView.orientation));
        PMPrintSettingsSetValue(ps, (CFStringRef)(@"com.apple.print.PrintSettings.PMColorMode"), (__bridge CFNumberRef)colorMode, YES);
        PMPrintSettingsSetValue(ps, (CFStringRef)(@"com.apple.print.PrintSettings.PMQuality"), (__bridge CFNumberRef)quality, YES);
        PMPrintSettingsSetValue(ps, (CFStringRef)(@"com.apple.print.PageFormat.PMOrientation"), (__bridge CFNumberRef)pmOrientation, YES);
        [pi updateFromPMPrintSettings];

        NSPrintOperation *po = [NSPrintOperation printOperationWithView:pv printInfo:pi];
        [po setCanSpawnSeparateThread:YES];
        [po setJobTitle:jobTitle];
        [po runOperation];
    }
}
/*
- (NSUndoManager *)undoManager {
    return [self.managedObjectContext undoManager];
}
*/
- (IBAction)changeEventInfoOK:(id)sender {
    [self.eventInfoPopover close];
    [[self.managedObjectContext undoManager] endUndoGrouping];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ASCourseChanged" object:self.managedObjectContext];
}

- (IBAction)changeEventInfoCancel:(id)sender {
    [self.eventInfoPopover close];
    [[self.managedObjectContext undoManager] endUndoGrouping];
    [[self.managedObjectContext undoManager] undo];
    self.eventInfoPopover = nil;
}

- (void)showEventInfoPopupForNotification:(NSNotification *)n {
    [self.undoManager beginUndoGrouping];

    [self.eventInfoPopover showRelativeToRect:[[[n userInfo] valueForKey:@"rect"] rectValue] ofView:[[n userInfo] valueForKey:@"view"] preferredEdge:NSMaxXEdge];
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem {
    if ([anItem action] == @selector(addWhiteArea:)) {
        return self.mapView.state == kASMapViewLayout;
    }
    if ([anItem action] == @selector(goIntoAddControlsMode:) || [anItem action] == @selector(goIntoAddFinishMode:) || [anItem action] == @selector(goIntoAddStartMode:)) {
        return  self.mapView.state != kASMapViewLayout;
    }
    return [super validateUserInterfaceItem:anItem];
}


@end
