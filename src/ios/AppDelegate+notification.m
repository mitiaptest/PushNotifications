//
//  AppDelegate+notification.m
//  pushtest
//
//  Created by Robert Easterday on 10/26/12.
//
//

#import "AppDelegate+notification.h"
#import <objc/runtime.h>

@implementation AppDelegate (notification)

// its dangerous to override a method from within a category.
// Instead we will use method swizzling. we set this up in the load call.
+ (void)load
{
    Method original, swizzled;

    original = class_getInstanceMethod(self, @selector(init));
    swizzled = class_getInstanceMethod(self, @selector(swizzled_init));
    method_exchangeImplementations(original, swizzled);
}

- (AppDelegate *)swizzled_init
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createNotificationChecker:)
               name:@"UIApplicationDidFinishLaunchingNotification" object:nil];

	// This actually calls the original init method over in AppDelegate. Equivilent to calling super
	// on an overrided method, this is not recursive, although it appears that way. neat huh?
	return [self swizzled_init];
}

// This code will be called immediately after application:didFinishLaunchingWithOptions:. We need
// to process notifications in cold-start situations
- (void)createNotificationChecker:(NSNotification *)notification
{
	if (notification) {
		NSDictionary *launchOptions = [notification userInfo];
        if (launchOptions){

            NSMutableDictionary* notification = [NSMutableDictionary dictionaryWithDictionary:
                                                 [launchOptions objectForKey: @"UIApplicationLaunchOptionsRemoteNotificationKey"]];

            [notification setObject:[NSNumber numberWithBool:NO] forKey:@"foreground"];
            [notification setObject:[NSNumber numberWithBool:YES] forKey:@"userAction"];

            [[NotificationService instance] receivedNotification:notification];

        }
	}
}

-(void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {

    [[NotificationService instance] didRegisterUserNotificationSettings:notificationSettings];

}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {

    [[NotificationService instance] onRegistered:deviceToken];

}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {

    [[NotificationService instance] failToRegister:error];

}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {

    if(application.applicationState == UIApplicationStateInactive) {

        NSLog(@"Inactive");

        //Show the view with the content of the push

        completionHandler(UIBackgroundFetchResultNewData);

    } else if (application.applicationState == UIApplicationStateBackground) {

        NSLog(@"Background");

        //Refresh the local model

        completionHandler(UIBackgroundFetchResultNewData);

    } else {

        NSLog(@"Active");

        //Show an in-app banner

        completionHandler(UIBackgroundFetchResultNewData);

    }
}

- (NSString*) getCurrentDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

    NSDate *now = [NSDate date];
    NSString *iso8601String = [dateFormatter stringFromDate:now];
    return iso8601String;
}

- (NSString*) getUUID {
    NSString* UUID = [[NSUUID UUID] UUIDString];
    return UUID;
}

@end
