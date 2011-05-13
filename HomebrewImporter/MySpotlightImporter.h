//
//  MySpotlightImporter.h
//  HomebrewImporter
//
//  Created by travisjeffery on 11-05-13.
//  Copyright 2011 Travis Jeffery. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MySpotlightImporter : NSObject {
@private
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    
    NSURL *modelURL;
    NSURL *storeURL;
}

@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

- (BOOL)importFileAtPath:(NSString *)filePath attributes:(NSMutableDictionary *)attributes error:(NSError **)error;

@end
