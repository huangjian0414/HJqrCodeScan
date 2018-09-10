//
//  AppDelegate.m
//  HJqrCodeScan
//
//  Created by 黄坚 on 2018/2/3.
//  Copyright © 2018年 黄坚. All rights reserved.
//

#import "AppDelegate.h"
#import "HJScanViewController.h"
#import "HJScanViewStyle.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window=[[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    HJScanViewStyle *style=[[HJScanViewStyle alloc]init];
    style.xScanRetangleOffset=100;
    style.colorRetangleLine = [UIColor whiteColor];
    
    style.centerUpOffset = -100;
    
    style.photoframeAngleStyle = HJScanViewPhotoframeAngleStyle_Inner;
    style.colorAngle = [UIColor redColor];
    style.retangleW = 14;
    style.notRecoginitonArea = [UIColor colorWithRed:0. green:.0 blue:.0 alpha:.5];
    
    style.photoframeAngleW = 20;
    
    style.photoframeLineW = 2;
    style.scanLineH= 8;
    HJScanViewController *vc = [[HJScanViewController alloc]init];
    //vc.scanStyle=style;
    //HJScanViewController *vc=[[HJScanViewController alloc]initWithHJScanViewStyle:style];
    self.window.rootViewController=vc;
    [self.window makeKeyAndVisible];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
