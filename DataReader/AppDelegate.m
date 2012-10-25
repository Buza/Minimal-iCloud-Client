//
//  AppDelegate.m
//  DataReader
//
//  Created by buza on 10/22/12.
//  Copyright (c) 2012 buzamoto. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"

#import "MyDocument.h"

@interface AppDelegate()
@property(nonatomic, strong) NSMetadataQuery *myquery;
@end

@implementation AppDelegate

@synthesize myquery;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.myquery = nil;
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.viewController = [[ViewController alloc] initWithNibName:@"ViewController_iPhone" bundle:nil];
    } else {
        self.viewController = [[ViewController alloc] initWithNibName:@"ViewController_iPad" bundle:nil];
    }
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    
    //Start running our NSMetadataQuery to discover iCloud files.
    [self startQuery];
    
    return YES;
}

- (void)stopQuery
{
    if (myquery)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidUpdateNotification object:nil];
        [myquery stopQuery];
        myquery = nil;
    }
}

- (void)finishedGathering:(NSNotification *)notification
{
    [myquery disableUpdates];

    NSArray * queryResults = [myquery results];
    
    for (NSMetadataItem * result in queryResults) {
        
        NSURL *fileURL = [result valueForAttribute:NSMetadataItemURLKey];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *err;
        err = nil;
        id res;
        [fileURL getResourceValue:&res forKey:NSURLUbiquitousItemIsDownloadedKey error:&err];
        
        if(![res boolValue])
        {
            DLog(@" Not downloaded. Initiating download.");
            [fm startDownloadingUbiquitousItemAtURL:fileURL error:&err];
            continue;
        }
        
        DLog(@"File is downloaded. %@", fileURL);
        if([res boolValue])
        {
            MyDocument * doc = [[MyDocument alloc] initWithFileURL:fileURL];
            [doc openWithCompletionHandler:^(BOOL success) {
                
                DLog(@"Got updated doc title %@", doc.title);

                [doc closeWithCompletionHandler:^(BOOL success) {
                    DLog(@"Doc closed");
                }];
                
            }];
        }
    }
    
    [myquery enableUpdates];
}

- (void)startQuery
{
    [self stopQuery];
    
    NSMetadataQuery * query = [NSMetadataQuery new];
    if (query)
    {
        [query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
        NSString * filePattern = [NSString stringWithFormat:@"*.skt"];
        [query setPredicate:[NSPredicate predicateWithFormat:@"%K LIKE %@", NSMetadataItemFSNameKey, filePattern]];
    }
    
    self.myquery = query;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(finishedGathering:)
                                                 name:NSMetadataQueryDidFinishGatheringNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(finishedGathering:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:nil];
    
    [myquery startQuery];
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
