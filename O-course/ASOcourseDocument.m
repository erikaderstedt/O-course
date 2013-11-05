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

#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

int cp(const char *to, const char *from)
{
    int fd_to, fd_from;
    char buf[4096];
    ssize_t nread;
    int saved_errno;
    
    fd_from = open(from, O_RDONLY);
    if (fd_from < 0)
        return -1;
    
    fd_to = open(to, O_WRONLY | O_CREAT | O_EXCL, 0666);
    if (fd_to < 0)
        goto out_error;
    
    while (nread = read(fd_from, buf, sizeof buf), nread > 0)
    {
        char *out_ptr = buf;
        ssize_t nwritten;
        
        do {
            nwritten = write(fd_to, out_ptr, nread);
            
            if (nwritten >= 0)
            {
                nread -= nwritten;
                out_ptr += nwritten;
            }
            else if (errno != EINTR)
            {
                goto out_error;
            }
        } while (nread > 0);
    }
    
    if (nread == 0)
    {
        if (close(fd_to) < 0)
        {
            fd_to = -1;
            goto out_error;
        }
        close(fd_from);
        
        /* Success! */
        return 0;
    }
    
out_error:
    saved_errno = errno;
    
    close(fd_from);
    if (fd_to >= 0)
        close(fd_to);
    
    errno = saved_errno;
    return -1;
}

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

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_6
    [[aController window] setCollectionBehavior:([[aController window] collectionBehavior] | NSWindowCollectionBehaviorFullScreenPrimary)];
#endif 
}

+ (BOOL)autosavesInPlace {
    return YES;
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

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
	//
	// Copy absolute URL to a temporary file, private to our application.
	//
	NSURL *tempURL = [self suitableURLForTemporaryStoreForBaseURL:absoluteURL error:outError];
	if (tempURL == nil) return NO;
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:[tempURL path]] && ![fm removeItemAtURL:tempURL error:outError]) return NO;
    if (cp([[tempURL path] cStringUsingEncoding:NSUTF8StringEncoding], [[absoluteURL path] cStringUsingEncoding:NSUTF8StringEncoding])) {
        NSLog(@"no copy!");
        return NO;
    }
    
	//
	// Add a persistent store at that URL to our store coordinator
	//
    NSDictionary *options = @{ NSSQLitePragmasOption : @{@"journal_mode" : @"DELETE"} };
	NSPersistentStore *addedPS = [[self persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType
                                                                                 configuration:nil
                                                                                           URL:tempURL
                                                                                       options:options
                                                                                         error:outError];
	BOOL success = (addedPS != nil);

	if (success)
        [self performSelectorOnMainThread:@selector(updateMap:) withObject:nil waitUntilDone:NO];

	return success;
}

- (NSURL *)temporaryStoreURL {
	NSURL *u = nil;
    NSArray *stores = [[self persistentStoreCoordinator] persistentStores];
    if ([stores count] != 0 && [stores[0] URL] != nil) {
		u = [stores[0] URL];
	}
	return u;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	if (_psc == nil) {
		_psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	}
	return _psc;
}

- (NSManagedObjectContext *)managedObjectContext {
	if (_context == nil) {
		_context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
		[_context setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
		[self setUndoManager:[_context undoManager]];
	}
	return _context;
}

- (NSManagedObjectModel *)managedObjectModel {
	if (_model) return _model;
    
    _model = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle mainBundle]]];
	return _model;
}

- (NSURL *)suitableURLForTemporaryStoreForBaseURL:(NSURL *)base error:(NSError **)outError {
	NSURL *tempURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
															inDomain:NSUserDomainMask
												   appropriateForURL:base
															  create:YES
															   error:outError];
	if (tempURL == nil) return nil;
	
	NSString *fileName = [NSString stringWithFormat:@"%ld", (long)[[base path] hash]];
	tempURL = [tempURL URLByAppendingPathComponent:fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[tempURL path]]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:[tempURL path] error:outError]) {
            tempURL = [tempURL URLByAppendingPathExtension:[NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:[tempURL path]]) {
                return nil;
            }
        }
    }
	
	return tempURL;
}

- (void)duplicateDocumentWithDelegate:(id)delegate didDuplicateSelector:(SEL)didDuplicateSelector contextInfo:(void *)contextInfo {
    [super duplicateDocumentWithDelegate:delegate didDuplicateSelector:@selector(document:didDuplicate:contextInfo:) contextInfo:contextInfo];
}

- (void)document:(ASOcourseDocument *)document didDuplicate:(BOOL)didDuplicate contextInfo:(void *)contextInfo {
    [document updateMap:nil];
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
    
	//
	// Does a persistent store exist on disk?
	//
	NSURL *tempStore = [self temporaryStoreURL];
	if (tempStore == nil) {
		tempStore = [self suitableURLForTemporaryStoreForBaseURL:absoluteURL error:outError];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[tempStore path]]) {
            if (![[NSFileManager defaultManager] removeItemAtURL:tempStore error:outError]) {
                return NO;
            }
        }
        
        NSDictionary *options = @{ NSSQLitePragmasOption : @{@"journal_mode" : @"DELETE"} };
		if ([[self persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType
															configuration:nil
																	  URL:tempStore
																  options:options
																	error:outError] == nil) {
			return NO;
		}
	}
	
	//
	// Save the context (to our private URL).
	//
	if (![[self managedObjectContext] save:outError]) {
		return NO;
	}
    
    if (absoluteURL == nil) {
        return YES;
    }
	
	[self unblockUserInteraction];
	
	//
	// Copy the store to the file url.
	//
    BOOL success = [[NSFileManager defaultManager] copyItemAtURL:tempStore toURL:absoluteURL error:outError];
    
	//
	// Set the metadata.
	//
	NSDictionary *metadata;
	if (success) {
		metadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:absoluteURL error:outError];
		success = (metadata != nil);
        
        if (success) {
            // Check that all keys exist and have the correct values
            NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:3];
            md[(NSString *)kMDItemCreator] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
			md[@"O-course version"] = @"1.0";
            
            BOOL change = NO;
            for (NSString *key in [md allKeys]) {
                if (![metadata[key] isEqual:md[key]]) {
                    change = YES;
                }
            }
            
            if (change) {
                NSMutableDictionary * mutableMetadata = [metadata mutableCopy];
                [mutableMetadata addEntriesFromDictionary:md];
                success = [NSPersistentStoreCoordinator setMetadata:mutableMetadata forPersistentStoreOfType:nil URL:absoluteURL error:outError];
            }
        }
	}
	return success;
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
        const int32_t *hiddenSymbols = [self.mapView.mapProvider hiddenSymbolNumbers:&numberOfHiddenSymbols];
        [pv.mapProvider setHiddenSymbolNumbers:hiddenSymbols count:numberOfHiddenSymbols];
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

- (NSUndoManager *)undoManager {
    return [self.managedObjectContext undoManager];
}

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
