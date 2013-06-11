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
#import "Project.h"
#import "ASOverprintProvider.h"
#import "CourseObject.h"

#import "ASOverprintController.h"
#import "ASCourseController.h"
#import "MyDocumentController.h"

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
@synthesize controlDefinitionsPopover;
@synthesize showControlDefinitionsToolbarItem;

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
                return [[[doc windowControllers] objectAtIndex:0] window];
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

- (IBAction)chooseBackgroundMap:(id)sender {
    NSOpenPanel *op = [MyDocumentController openPanelForBackgroundMap];

    [op beginSheetModalForWindow:[mapView window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [self setMapURL:[op URL]];
        }
    }];
}

- (void)setMapURL:(NSURL *)u {
    
    Project *p = [self project];
    NSError *error = nil;
    
    [[self undoManager] disableUndoRegistration];
    if (![p setMapURL:u error:&error]) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
    }
    [[self undoManager] enableUndoRegistration];
    
    [self updateMap:nil];
}

- (void)updateMap:(NSNotification *)n {
    NSURL *u = [[self project] mapURL];

    if (u != nil) {
        [u startAccessingSecurityScopedResource];
        
        NSString *s = [u path];
        if ([[s pathExtension] isEqualToString:@"ocd"]) {
            ASOCADController *o = [[ASOCADController alloc] initWithOCADFile:s];
            [o prepareCacheWithAreaTransform:CGAffineTransformIdentity secondaryTransform:CGAffineTransformMakeScale(0.15, 0.15)];
            mapView.mapProvider = o;
            [o autorelease];
        } else {
            ASGenericImageController *i = [[ASGenericImageController alloc] initWithContentsOfFile:s];
            mapView.mapProvider = i;
        }
        
        [u stopAccessingSecurityScopedResource];
    } else {
        mapView.mapProvider = nil;
    }
    
    [mapView mapLoaded];
}

- (void)awakeFromNib {
    [self.courseController setManagedObjectContext:[self managedObjectContext]];
    [self.courseController willAppear];
    
    [self.overprintController updateCache];
    mapView.overprintProvider = self.overprintController;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(undoOrRedo:) name:NSUndoManagerDidUndoChangeNotification object:[[self managedObjectContext] undoManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(undoOrRedo:) name:NSUndoManagerDidRedoChangeNotification object:[[self managedObjectContext] undoManager]];
}

- (void)undoOrRedo:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ASCourseChanged" object:[self managedObjectContext]];
}

- (void)windowWillClose:(NSNotification *)notification {
    
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
    [mapURL release];
    
    [super dealloc];
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
	NSPersistentStore *addedPS = [[self persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType
                                                                                 configuration:nil
                                                                                           URL:tempURL
                                                                                       options:nil
                                                                                         error:outError];
	BOOL success = (addedPS != nil);

	if (success)
        [self performSelectorOnMainThread:@selector(updateMap:) withObject:nil waitUntilDone:NO];

	return success;
}

- (NSURL *)temporaryStoreURL {
	NSURL *u = nil;
    NSArray *stores = [[self persistentStoreCoordinator] persistentStores];
    if ([stores count] != 0 && [[stores objectAtIndex:0] URL] != nil) {
		u = [[stores objectAtIndex:0] URL];
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
    
    _model = [[NSManagedObjectModel mergedModelFromBundles:@[[NSBundle mainBundle]]] retain];
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
		if ([[self persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType
															configuration:nil
																	  URL:tempStore
																  options:nil
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
            [md setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] forKey:(NSString *)kMDItemCreator];
			[md setObject:@"1.0" forKey:@"O-course version"];
            
            BOOL change = NO;
            for (NSString *key in [md allKeys]) {
                if (![[metadata objectForKey:key] isEqual:[md objectForKey:key]]) {
                    change = YES;
                }
            }
            
            if (change) {
                NSMutableDictionary * mutableMetadata = [metadata mutableCopy];
                [mutableMetadata addEntriesFromDictionary:md];
                success = [NSPersistentStoreCoordinator setMetadata:mutableMetadata forPersistentStoreOfType:nil URL:absoluteURL error:outError];
                [mutableMetadata release];
            }
        }
	}
	return success;
}

- (IBAction)showControlDefinitionsPopover:(id)sender {
    if ([self.controlDefinitionsPopover isShown]) {
        [self.controlDefinitionsPopover performClose:sender];
        return;
    }
    [self.controlDefinitionsPopover showRelativeToRect:[[self.showControlDefinitionsToolbarItem view] bounds] ofView:[self.showControlDefinitionsToolbarItem view] preferredEdge:NSMinYEdge];
}

@end
