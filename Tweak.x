#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Helper function to verify if previously fixed Pinterest still exists
BOOL verifyPinterestFix() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *savedPath = [defaults objectForKey:@"PinterestFixPath"];
    NSString *savedVersion = [defaults objectForKey:@"PinterestFixVersion"];
    
    if (!savedPath || !savedVersion) {
        NSLog(@"[PinterestFix] No saved Pinterest fix data found");
        return NO;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:savedPath]) {
        NSLog(@"[PinterestFix] Previously fixed Pinterest no longer exists at: %@", savedPath);
        // Clear the saved data since Pinterest was uninstalled/reinstalled
        [defaults removeObjectForKey:@"PinterestFixPath"];
        [defaults removeObjectForKey:@"PinterestFixVersion"];
        [defaults setBool:NO forKey:@"PinterestFixApplied"];
        [defaults synchronize];
        return NO;
    }
    
    // Verify the fix is still applied
    NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile:savedPath];
    if (infoDict) {
        NSString *currentVersion = [infoDict objectForKey:@"CFBundleVersion"];
        NSString *currentShortVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
        
        if ([currentVersion isEqualToString:@"13.28"] && [currentShortVersion isEqualToString:@"13.28"]) {
            NSLog(@"[PinterestFix] Previously fixed Pinterest still has correct versions");
            return YES;
        } else {
            NSLog(@"[PinterestFix] Previously fixed Pinterest versions changed - Version: %@, Short: %@", currentVersion, currentShortVersion);
            // Clear the saved data since Pinterest was updated/downgraded
            [defaults removeObjectForKey:@"PinterestFixPath"];
            [defaults removeObjectForKey:@"PinterestFixVersion"];
            [defaults setBool:NO forKey:@"PinterestFixApplied"];
            [defaults synchronize];
            return NO;
        }
    }
    
    return NO;
}

// Helper function to find and fix Pinterest Info.plist
void findAndFixPinterest() {
    NSLog(@"[PinterestFix] Starting Pinterest fix scan...");
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationsPath = @"/var/mobile/Applications";
    
    if (![fileManager fileExistsAtPath:applicationsPath]) {
        NSLog(@"[PinterestFix] Applications path not found: %@", applicationsPath);
        return;
    }
    
    NSLog(@"[PinterestFix] Scanning applications directory: %@", applicationsPath);
    
    NSError *error;
    NSArray *appDirs = [fileManager contentsOfDirectoryAtPath:applicationsPath error:&error];
    
    if (error) {
        NSLog(@"[PinterestFix] Error reading applications directory: %@", error);
        return;
    }
    
    NSLog(@"[PinterestFix] Found %lu application directories", (unsigned long)[appDirs count]);
    
    // First, verify if previously fixed Pinterest still exists and is still fixed
    if (verifyPinterestFix()) {
        NSLog(@"[PinterestFix] Previously fixed Pinterest verified, skipping scan");
        return;
    }
    
    NSLog(@"[PinterestFix] Pinterest needs fixing, scanning for installations...");
    
    // Look for Pinterest app
    for (NSString *appDir in appDirs) {
        NSString *fullAppPath = [applicationsPath stringByAppendingPathComponent:appDir];
        NSString *infoPlistPath = [fullAppPath stringByAppendingPathComponent:@"Info.plist"];
        
        NSLog(@"[PinterestFix] Checking app directory: %@", appDir);
        
        if ([fileManager fileExistsAtPath:infoPlistPath]) {
            NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
            if (infoDict) {
                NSString *bundleID = [infoDict objectForKey:@"CFBundleIdentifier"];
                NSString *appName = [infoDict objectForKey:@"CFBundleDisplayName"];
                
                NSLog(@"[PinterestFix] Found app: %@ (%@)", appName ?: @"Unknown", bundleID ?: @"Unknown");
                
                // Check if this is Pinterest
                if ([bundleID isEqualToString:@"com.coldbrewlabs.pinterest"] || 
                    [bundleID isEqualToString:@"com.pinterest"] ||
                    [bundleID isEqualToString:@"com.pinterest.app"] ||
                    (appName && [appName hasPrefix:@"Pinterest"]) ||
                    (bundleID && [bundleID hasPrefix:@"com.pinterest"])) {
                    
                    NSLog(@"[PinterestFix] Found Pinterest! Bundle ID: %@, Name: %@", bundleID, appName);
                    
                    // Check if already fixed
                    NSString *currentVersion = [infoDict objectForKey:@"CFBundleVersion"];
                    NSString *currentShortVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
                    NSLog(@"[PinterestFix] Current versions - Version: %@, Short: %@", currentVersion, currentShortVersion);
                    
                    if ([currentVersion isEqualToString:@"13.28"] && [currentShortVersion isEqualToString:@"13.28"]) {
                        NSLog(@"[PinterestFix] Pinterest already fixed at: %@", infoPlistPath);
                        // Mark this specific Pinterest installation as fixed
                        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                        [defaults setObject:infoPlistPath forKey:@"PinterestFixPath"];
                        [defaults setObject:currentVersion forKey:@"PinterestFixVersion"];
                        [defaults setBool:YES forKey:@"PinterestFixApplied"];
                        [defaults synchronize];
                        return;
                    }
                    
                    // Apply the fix
                    NSLog(@"[PinterestFix] Applying fix to Pinterest Info.plist");
                    NSMutableDictionary *mutableInfoDict = [infoDict mutableCopy];
                    [mutableInfoDict setObject:@"13.28" forKey:@"CFBundleVersion"];
                    [mutableInfoDict setObject:@"13.28" forKey:@"CFBundleShortVersionString"];
                    
                    BOOL success = [mutableInfoDict writeToFile:infoPlistPath atomically:YES];
                    if (success) {
                        NSLog(@"[PinterestFix] Successfully applied fix to Pinterest!");
                    } else {
                        NSLog(@"[PinterestFix] Failed to write Info.plist file");
                    }
                    
                    // Mark this specific Pinterest installation as fixed
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    [defaults setObject:infoPlistPath forKey:@"PinterestFixPath"];
                    [defaults setObject:@"13.28" forKey:@"PinterestFixVersion"];
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
                                    NSLog(@"[PinterestFix] App bundle versions - Version: %@, Short: %@", currentVersion, currentShortVersion);
                                    
                                    if ([currentVersion isEqualToString:@"13.28"] && [currentShortVersion isEqualToString:@"13.28"]) {
                                        NSLog(@"[PinterestFix] Pinterest app bundle already fixed at: %@", appInfoPlistPath);
                                        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                        [defaults setObject:appInfoPlistPath forKey:@"PinterestFixPath"];
                                        [defaults setObject:currentVersion forKey:@"PinterestFixVersion"];
                                        [defaults setBool:YES forKey:@"PinterestFixApplied"];
                                        [defaults synchronize];
                                        return;
                                    }
                                    
                                    NSLog(@"[PinterestFix] Applying fix to Pinterest app bundle Info.plist");
                                    NSMutableDictionary *mutableInfoDict = [appInfoDict mutableCopy];
                                    [mutableInfoDict setObject:@"13.28" forKey:@"CFBundleVersion"];
                                    [mutableInfoDict setObject:@"13.28" forKey:@"CFBundleShortVersionString"];
                                    
                                    BOOL success = [mutableInfoDict writeToFile:appInfoPlistPath atomically:YES];
                                    if (success) {
                                        NSLog(@"[PinterestFix] Successfully applied fix to Pinterest app bundle!");
                                    } else {
                                        NSLog(@"[PinterestFix] Failed to write app bundle Info.plist file");
                                    }
                                    
                                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                    [defaults setObject:appInfoPlistPath forKey:@"PinterestFixPath"];
                                    [defaults setObject:@"13.28" forKey:@"PinterestFixVersion"];
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
    
    NSLog(@"[PinterestFix] Pinterest not found in applications directory");
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    %orig;
    
    NSLog(@"[PinterestFix] SpringBoard launched, applying Pinterest fix...");
    
    // Apply fix immediately on SpringBoard launch
    findAndFixPinterest();
    
    NSLog(@"[PinterestFix] Pinterest fix scan completed");
}

%end
