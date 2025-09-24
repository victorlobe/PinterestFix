#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Helper function to find and fix Pinterest Info.plist
void findAndFixPinterest() {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationsPath = @"/var/mobile/Applications";
    
    if (![fileManager fileExistsAtPath:applicationsPath]) {
        return;
    }
    
    NSError *error;
    NSArray *appDirs = [fileManager contentsOfDirectoryAtPath:applicationsPath error:&error];
    
    if (error) {
        return;
    }
    
    // Quick check: if Pinterest is already fixed, skip scanning
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"PinterestFixApplied"]) {
        return;
    }
    
    // Look for Pinterest app
    for (NSString *appDir in appDirs) {
        NSString *fullAppPath = [applicationsPath stringByAppendingPathComponent:appDir];
        NSString *infoPlistPath = [fullAppPath stringByAppendingPathComponent:@"Info.plist"];
        
        if ([fileManager fileExistsAtPath:infoPlistPath]) {
            NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
            if (infoDict) {
                NSString *bundleID = [infoDict objectForKey:@"CFBundleIdentifier"];
                NSString *appName = [infoDict objectForKey:@"CFBundleDisplayName"];
                
                // Check if this is Pinterest
                if ([bundleID isEqualToString:@"com.coldbrewlabs.pinterest"] || 
                    [bundleID isEqualToString:@"com.pinterest"] ||
                    [bundleID isEqualToString:@"com.pinterest.app"] ||
                    (appName && [appName hasPrefix:@"Pinterest"]) ||
                    (bundleID && [bundleID hasPrefix:@"com.pinterest"])) {
                    
                    // Check if already fixed
                    NSString *currentVersion = [infoDict objectForKey:@"CFBundleVersion"];
                    NSString *currentShortVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
                    if ([currentVersion isEqualToString:@"13.28"] && [currentShortVersion isEqualToString:@"13.28"]) {
                        return;
                    }
                    
                    // Apply the fix
                    NSMutableDictionary *mutableInfoDict = [infoDict mutableCopy];
                    [mutableInfoDict setObject:@"13.28" forKey:@"CFBundleVersion"];
                    [mutableInfoDict setObject:@"13.28" forKey:@"CFBundleShortVersionString"];
                    [mutableInfoDict writeToFile:infoPlistPath atomically:YES];
                    
                    // Mark as fixed to avoid future scans
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    [defaults setBool:YES forKey:@"PinterestFixApplied"];
                    [defaults synchronize];
                    return;
                }
            }
        } else {
            // Check if there are subdirectories (app bundles)
            NSArray *subdirs = [fileManager contentsOfDirectoryAtPath:fullAppPath error:nil];
            if (subdirs && [subdirs count] > 0) {
                // Look for .app bundle in subdirectories
                for (NSString *subdir in subdirs) {
                    if ([subdir hasSuffix:@".app"]) {
                        NSString *appBundlePath = [fullAppPath stringByAppendingPathComponent:subdir];
                        NSString *appInfoPlistPath = [appBundlePath stringByAppendingPathComponent:@"Info.plist"];
                        
                        if ([fileManager fileExistsAtPath:appInfoPlistPath]) {
                            NSDictionary *appInfoDict = [NSDictionary dictionaryWithContentsOfFile:appInfoPlistPath];
                            if (appInfoDict) {
                                NSString *bundleID = [appInfoDict objectForKey:@"CFBundleIdentifier"];
                                NSString *appName = [appInfoDict objectForKey:@"CFBundleDisplayName"];
                                
                                if ([bundleID isEqualToString:@"com.coldbrewlabs.pinterest"] || 
                                    [bundleID isEqualToString:@"com.pinterest"] ||
                                    [bundleID isEqualToString:@"com.pinterest.app"] ||
                                    (appName && [appName hasPrefix:@"Pinterest"]) ||
                                    (bundleID && [bundleID hasPrefix:@"com.pinterest"])) {
                                    
                                    NSString *currentVersion = [appInfoDict objectForKey:@"CFBundleVersion"];
                                    NSString *currentShortVersion = [appInfoDict objectForKey:@"CFBundleShortVersionString"];
                                    if ([currentVersion isEqualToString:@"13.28"] && [currentShortVersion isEqualToString:@"13.28"]) {
                                        return;
                                    }
                                    
                                    NSMutableDictionary *mutableInfoDict = [appInfoDict mutableCopy];
                                    [mutableInfoDict setObject:@"13.28" forKey:@"CFBundleVersion"];
                                    [mutableInfoDict setObject:@"13.28" forKey:@"CFBundleShortVersionString"];
                                    [mutableInfoDict writeToFile:appInfoPlistPath atomically:YES];
                                    
                                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                    [defaults setBool:YES forKey:@"PinterestFixApplied"];
                                    [defaults synchronize];
                                    return;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    %orig;
    
    // Apply fix immediately on SpringBoard launch
    findAndFixPinterest();
    
    // Monitor for Pinterest launches
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(pinterestLaunched:) 
                                                 name:@"UIApplicationDidFinishLaunchingNotification" 
                                               object:nil];
}

- (void)pinterestLaunched:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSString *bundleID = [userInfo objectForKey:@"UIApplicationLaunchOptionsBundleIdentifierKey"];
    
    if ([bundleID isEqualToString:@"com.coldbrewlabs.pinterest"]) {
        findAndFixPinterest();
    }
}

%end
