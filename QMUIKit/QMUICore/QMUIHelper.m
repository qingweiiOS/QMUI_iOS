/*****
 * Tencent is pleased to support the open source community by making QMUI_iOS available.
 * Copyright (C) 2016-2019 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 * http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 *****/

//
//  QMUIHelper.m
//  qmui
//
//  Created by QMUI Team on 14/10/25.
//

#import "QMUIHelper.h"
#import "QMUICore.h"
#import "NSNumber+QMUI.h"
#import "UIViewController+QMUI.h"
#import "NSString+QMUI.h"
#import "UIInterface+QMUI.h"
#import "NSObject+QMUI.h"
#import <AVFoundation/AVFoundation.h>
#import <math.h>
#import <sys/utsname.h>

NSString *const QMUIResourcesMainBundleName = @"QMUIResources.bundle";

@implementation QMUIHelper (Bundle)

+ (NSBundle *)resourcesBundle {
    return [QMUIHelper resourcesBundleWithName:QMUIResourcesMainBundleName];
}

+ (NSBundle *)resourcesBundleWithName:(NSString *)bundleName {
    NSBundle *bundle = [NSBundle bundleWithPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:bundleName]];
    if (!bundle) {
        // 动态framework的bundle资源是打包在framework里面的，所以无法通过mainBundle拿到资源，只能通过其他方法来获取bundle资源。
        NSBundle *frameworkBundle = [NSBundle bundleForClass:[self class]];
        NSDictionary *bundleData = [self parseBundleName:bundleName];
        if (bundleData) {
            bundle = [NSBundle bundleWithPath:[frameworkBundle pathForResource:[bundleData objectForKey:@"name"] ofType:[bundleData objectForKey:@"type"]]];
        }
    }
    return bundle;
}

+ (UIImage *)imageWithName:(NSString *)name {
    NSBundle *bundle = [QMUIHelper resourcesBundle];
    return [QMUIHelper imageInBundle:bundle withName:name];
}

+ (UIImage *)imageInBundle:(NSBundle *)bundle withName:(NSString *)name {
    if (bundle && name) {
        if ([UIImage respondsToSelector:@selector(imageNamed:inBundle:compatibleWithTraitCollection:)]) {
            return [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
        } else {
            NSString *imagePath = [[bundle resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", name]];
            return [UIImage imageWithContentsOfFile:imagePath];
        }
    }
    return nil;
}

+ (NSDictionary *)parseBundleName:(NSString *)bundleName {
    NSArray *bundleData = [bundleName componentsSeparatedByString:@"."];
    if (bundleData.count == 2) {
        return @{@"name":bundleData[0], @"type":bundleData[1]};
    }
    return nil;
}

@end


@implementation QMUIHelper (DynamicType)

+ (NSNumber *)preferredContentSizeLevel {
    NSNumber *index = nil;
    if ([UIApplication instancesRespondToSelector:@selector(preferredContentSizeCategory)]) {
        NSString *contentSizeCategory = [[UIApplication sharedApplication] preferredContentSizeCategory];
        if ([contentSizeCategory isEqualToString:UIContentSizeCategoryExtraSmall]) {
            index = [NSNumber numberWithInt:0];
        } else if ([contentSizeCategory isEqualToString:UIContentSizeCategorySmall]) {
            index = [NSNumber numberWithInt:1];
        } else if ([contentSizeCategory isEqualToString:UIContentSizeCategoryMedium]) {
            index = [NSNumber numberWithInt:2];
        } else if ([contentSizeCategory isEqualToString:UIContentSizeCategoryLarge]) {
            index = [NSNumber numberWithInt:3];
        } else if ([contentSizeCategory isEqualToString:UIContentSizeCategoryExtraLarge]) {
            index = [NSNumber numberWithInt:4];
        } else if ([contentSizeCategory isEqualToString:UIContentSizeCategoryExtraExtraLarge]) {
            index = [NSNumber numberWithInt:5];
        } else if ([contentSizeCategory isEqualToString:UIContentSizeCategoryExtraExtraExtraLarge]) {
            index = [NSNumber numberWithInt:6];
        } else if ([contentSizeCategory isEqualToString:UIContentSizeCategoryAccessibilityMedium]) {
            index = [NSNumber numberWithInt:6];
        } else if ([contentSizeCategory isEqualToString:UIContentSizeCategoryAccessibilityLarge]) {
            index = [NSNumber numberWithInt:6];
        } else if ([contentSizeCategory isEqualToString:UIContentSizeCategoryAccessibilityExtraLarge]) {
            index = [NSNumber numberWithInt:6];
        } else if ([contentSizeCategory isEqualToString:UIContentSizeCategoryAccessibilityExtraExtraLarge]) {
            index = [NSNumber numberWithInt:6];
        } else if ([contentSizeCategory isEqualToString:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge]) {
            index = [NSNumber numberWithInt:6];
        } else{
            index = [NSNumber numberWithInt:6];
        }
    } else {
        index = [NSNumber numberWithInt:3];
    }
    
    return index;
}

+ (CGFloat)heightForDynamicTypeCell:(NSArray *)heights {
    NSNumber *index = [QMUIHelper preferredContentSizeLevel];
    return [((NSNumber *)[heights objectAtIndex:[index intValue]]) qmui_CGFloatValue];
}
@end

@implementation QMUIHelper (Keyboard)

QMUISynthesizeBOOLProperty(keyboardVisible, setKeyboardVisible)
QMUISynthesizeCGFloatProperty(lastKeyboardHeight, setLastKeyboardHeight)

- (void)handleKeyboardWillShow:(NSNotification *)notification {
    self.keyboardVisible = YES;
    self.lastKeyboardHeight = [QMUIHelper keyboardHeightWithNotification:notification];
}

- (void)handleKeyboardWillHide:(NSNotification *)notification {
    self.keyboardVisible = NO;
}

+ (BOOL)isKeyboardVisible {
    BOOL visible = [QMUIHelper sharedInstance].keyboardVisible;
    return visible;
}

+ (CGFloat)lastKeyboardHeightInApplicationWindowWhenVisible {
    return [QMUIHelper sharedInstance].lastKeyboardHeight;
}

+ (CGRect)keyboardRectWithNotification:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    CGRect keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    // 注意iOS8以下的系统在横屏时得到的rect，宽度和高度相反了，所以不建议直接通过这个方法获取高度，而是使用<code>keyboardHeightWithNotification:inView:</code>，因为在后者的实现里会将键盘的rect转换坐标系，转换过程就会处理横竖屏旋转问题。
    return keyboardRect;
}

+ (CGFloat)keyboardHeightWithNotification:(NSNotification *)notification {
    return [QMUIHelper keyboardHeightWithNotification:notification inView:nil];
}

+ (CGFloat)keyboardHeightWithNotification:(nullable NSNotification *)notification inView:(nullable UIView *)view {
    CGRect keyboardRect = [self keyboardRectWithNotification:notification];
    if (!view) {
        return CGRectGetHeight(keyboardRect);
    }
    CGRect keyboardRectInView = [view convertRect:keyboardRect fromView:view.window];
    CGRect keyboardVisibleRectInView = CGRectIntersection(view.bounds, keyboardRectInView);
    CGFloat resultHeight = CGRectIsValidated(keyboardVisibleRectInView) ? CGRectGetHeight(keyboardVisibleRectInView) : 0;
    return resultHeight;
}

+ (NSTimeInterval)keyboardAnimationDurationWithNotification:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    return animationDuration;
}

+ (UIViewAnimationCurve)keyboardAnimationCurveWithNotification:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    UIViewAnimationCurve curve = (UIViewAnimationCurve)[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    return curve;
}

+ (UIViewAnimationOptions)keyboardAnimationOptionsWithNotification:(NSNotification *)notification {
    UIViewAnimationOptions options = [QMUIHelper keyboardAnimationCurveWithNotification:notification]<<16;
    return options;
}

@end


@implementation QMUIHelper (AudioSession)

+ (void)redirectAudioRouteWithSpeaker:(BOOL)speaker temporary:(BOOL)temporary {
    if (![[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
        return;
    }
    if (temporary) {
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:speaker ? AVAudioSessionPortOverrideSpeaker : AVAudioSessionPortOverrideNone error:nil];
    } else {
        [[AVAudioSession sharedInstance] setCategory:[AVAudioSession sharedInstance].category withOptions:speaker ? AVAudioSessionCategoryOptionDefaultToSpeaker : 0 error:nil];
    }
}

+ (void)setAudioSessionCategory:(nullable NSString *)category {
    
    // 如果不属于系统category，返回
    if (category != AVAudioSessionCategoryAmbient &&
        category != AVAudioSessionCategorySoloAmbient &&
        category != AVAudioSessionCategoryPlayback &&
        category != AVAudioSessionCategoryRecord &&
        category != AVAudioSessionCategoryPlayAndRecord &&
        category != AVAudioSessionCategoryAudioProcessing)
    {
        return;
    }
    
    [[AVAudioSession sharedInstance] setCategory:category error:nil];
}

+ (UInt32)categoryForLowVersionWithCategory:(NSString *)category {
    if ([category isEqualToString:AVAudioSessionCategoryAmbient]) {
        return kAudioSessionCategory_AmbientSound;
    }
    if ([category isEqualToString:AVAudioSessionCategorySoloAmbient]) {
        return kAudioSessionCategory_SoloAmbientSound;
    }
    if ([category isEqualToString:AVAudioSessionCategoryPlayback]) {
        return kAudioSessionCategory_MediaPlayback;
    }
    if ([category isEqualToString:AVAudioSessionCategoryRecord]) {
        return kAudioSessionCategory_RecordAudio;
    }
    if ([category isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
        return kAudioSessionCategory_PlayAndRecord;
    }
    if ([category isEqualToString:AVAudioSessionCategoryAudioProcessing]) {
        return kAudioSessionCategory_AudioProcessing;
    }
    return kAudioSessionCategory_AmbientSound;
}

@end


@implementation QMUIHelper (UIGraphic)

static CGFloat pixelOne = -1.0f;
+ (CGFloat)pixelOne {
    if (pixelOne < 0) {
        pixelOne = 1 / [[UIScreen mainScreen] scale];
    }
    return pixelOne;
}

+ (void)inspectContextSize:(CGSize)size {
    if (!CGSizeIsValidated(size)) {
        NSAssert(NO, @"QMUI CGPostError, %@:%d %s, 非法的size：%@\n%@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, __PRETTY_FUNCTION__, NSStringFromCGSize(size), [NSThread callStackSymbols]);
    }
}

+ (void)inspectContextIfInvalidatedInDebugMode:(CGContextRef)context {
    if (!context) {
        // crash了就找zhoon或者molice
        NSAssert(NO, @"QMUI CGPostError, %@:%d %s, 非法的context：%@\n%@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, __PRETTY_FUNCTION__, context, [NSThread callStackSymbols]);
    }
}

+ (BOOL)inspectContextIfInvalidatedInReleaseMode:(CGContextRef)context {
    if (context) {
        return YES;
    }
    return NO;
}

@end

@implementation QMUIHelper (Device)

+ (NSString *)deviceModel {
    if (IS_SIMULATOR) {
        // Simulator doesn't return the identifier for the actual physical model, but returns it as an environment variable
        // 模拟器不返回物理机器信息，但会通过环境变量的方式返回
        return [NSString stringWithFormat:@"%s", getenv("SIMULATOR_MODEL_IDENTIFIER")];
    }
    
    // See https://www.theiphonewiki.com/wiki/Models for identifiers
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

static NSInteger isIPad = -1;
+ (BOOL)isIPad {
    if (isIPad < 0) {
        // [[[UIDevice currentDevice] model] isEqualToString:@"iPad"] 无法判断模拟器 iPad，所以改为以下方式
        isIPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 1 : 0;
    }
    return isIPad > 0;
}

static NSInteger isIPod = -1;
+ (BOOL)isIPod {
    if (isIPod < 0) {
        NSString *string = [[UIDevice currentDevice] model];
        isIPod = [string rangeOfString:@"iPod touch"].location != NSNotFound ? 1 : 0;
    }
    return isIPod > 0;
}

static NSInteger isIPhone = -1;
+ (BOOL)isIPhone {
    if (isIPhone < 0) {
        NSString *string = [[UIDevice currentDevice] model];
        isIPhone = [string rangeOfString:@"iPhone"].location != NSNotFound ? 1 : 0;
    }
    return isIPhone > 0;
}

static NSInteger isSimulator = -1;
+ (BOOL)isSimulator {
    if (isSimulator < 0) {
#if TARGET_OS_SIMULATOR
        isSimulator = 1;
#else
        isSimulator = 0;
#endif
    }
    return isSimulator > 0;
}

static NSInteger isNotchedScreen = -1;
+ (BOOL)isNotchedScreen {
    if (@available(iOS 11, *)) {
        if (isNotchedScreen < 0) {
            if (@available(iOS 12.0, *)) {
                /*
                 检测方式解释/测试要点：
                 1. iOS 11 与 iOS 12 可能行为不同，所以要分别测试。
                 2. 与触发 [QMUIHelper isNotchedScreen] 方法时的进程有关，例如 https://github.com/Tencent/QMUI_iOS/issues/482#issuecomment-456051738 里提到的 [NSObject performSelectorOnMainThread:withObject:waitUntilDone:NO] 就会导致较多的异常。
                 3. iOS 12 下，在非第2点里提到的情况下，iPhone、iPad 均可通过 UIScreen -_peripheryInsets 方法的返回值区分，但如果满足了第2点，则 iPad 无法使用这个方法，这种情况下要依赖第4点。
                 4. iOS 12 下，不管是否满足第2点，不管是什么设备类型，均可以通过一个满屏的 UIWindow 的 rootViewController.view.frame.origin.y 的值来区分，如果是非全面屏，这个值必定为20，如果是全面屏，则可能是24或44等不同的值。但由于创建 UIWindow、UIViewController 等均属于较大消耗，所以只在前面的步骤无法区分的情况下才会使用第4点。
                 5. 对于第4点，经测试与当前设备的方向、是否有勾选 project 里的 General - Hide status bar、当前是否处于来电模式的状态栏这些都没关系。
                 */
                SEL peripheryInsetsSelector = NSSelectorFromString([NSString stringWithFormat:@"_%@%@", @"periphery", @"Insets"]);
                UIEdgeInsets peripheryInsets = UIEdgeInsetsZero;
                [[UIScreen mainScreen] qmui_performSelector:peripheryInsetsSelector withPrimitiveReturnValue:&peripheryInsets];
                if (peripheryInsets.bottom <= 0) {
                    UIWindow *window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
                    peripheryInsets = window.safeAreaInsets;
                    if (peripheryInsets.bottom <= 0) {
                        UIViewController *viewController = [UIViewController new];
                        [viewController loadViewIfNeeded];
                        window.rootViewController = viewController;
                        if (CGRectGetMinY(viewController.view.frame) > 20) {
                            peripheryInsets.bottom = 1;
                        }
                    }
                }
                isNotchedScreen = peripheryInsets.bottom > 0 ? 1 : 0;
            } else {
                isNotchedScreen = [QMUIHelper is58InchScreen] ? 1 : 0;
            }
        }
    } else {
        isNotchedScreen = 0;
    }
    
    return isNotchedScreen > 0;
}

+ (BOOL)isRegularScreen {
    return [self isIPad] || (!IS_ZOOMEDMODE && ([self is65InchScreen] || [self is61InchScreen] || [self is55InchScreen]));
}

static NSInteger is65InchScreen = -1;
+ (BOOL)is65InchScreen {
    if (is65InchScreen < 0) {
        // Since iPhone XS Max and iPhone XR share the same resolution, we have to distinguish them using the model identifiers
        // 由于 iPhone XS Max 和 iPhone XR 的屏幕宽高是一致的，我们通过机器 Identifier 加以区别
        is65InchScreen = (DEVICE_WIDTH == self.screenSizeFor65Inch.width && DEVICE_HEIGHT == self.screenSizeFor65Inch.height && ([[QMUIHelper deviceModel] isEqualToString:@"iPhone11,4"] || [[QMUIHelper deviceModel] isEqualToString:@"iPhone11,6"])) ? 1 : 0;
    }
    return is65InchScreen > 0;
}

static NSInteger is61InchScreen = -1;
+ (BOOL)is61InchScreen {
    if (is61InchScreen < 0) {
        is61InchScreen = (DEVICE_WIDTH == self.screenSizeFor61Inch.width && DEVICE_HEIGHT == self.screenSizeFor61Inch.height && [[QMUIHelper deviceModel] isEqualToString:@"iPhone11,8"]) ? 1 : 0;
    }
    return is61InchScreen > 0;
}

static NSInteger is58InchScreen = -1;
+ (BOOL)is58InchScreen {
    if (is58InchScreen < 0) {
        // Both iPhone XS and iPhone X share the same actual screen sizes, so no need to compare identifiers
        // iPhone XS 和 iPhone X 的物理尺寸是一致的，因此无需比较机器 Identifier
        is58InchScreen = (DEVICE_WIDTH == self.screenSizeFor58Inch.width && DEVICE_HEIGHT == self.screenSizeFor58Inch.height) ? 1 : 0;
    }
    return is58InchScreen > 0;
}

static NSInteger is55InchScreen = -1;
+ (BOOL)is55InchScreen {
    if (is55InchScreen < 0) {
        is55InchScreen = (DEVICE_WIDTH == self.screenSizeFor55Inch.width && DEVICE_HEIGHT == self.screenSizeFor55Inch.height) ? 1 : 0;
    }
    return is55InchScreen > 0;
}

static NSInteger is47InchScreen = -1;
+ (BOOL)is47InchScreen {
    if (is47InchScreen < 0) {
        is47InchScreen = (DEVICE_WIDTH == self.screenSizeFor47Inch.width && DEVICE_HEIGHT == self.screenSizeFor47Inch.height) ? 1 : 0;
    }
    return is47InchScreen > 0;
}

static NSInteger is40InchScreen = -1;
+ (BOOL)is40InchScreen {
    if (is40InchScreen < 0) {
        is40InchScreen = (DEVICE_WIDTH == self.screenSizeFor40Inch.width && DEVICE_HEIGHT == self.screenSizeFor40Inch.height) ? 1 : 0;
    }
    return is40InchScreen > 0;
}

static NSInteger is35InchScreen = -1;
+ (BOOL)is35InchScreen {
    if (is35InchScreen < 0) {
        is35InchScreen = (DEVICE_WIDTH == self.screenSizeFor35Inch.width && DEVICE_HEIGHT == self.screenSizeFor35Inch.height) ? 1 : 0;
    }
    return is35InchScreen > 0;
}

+ (CGSize)screenSizeFor65Inch {
    return CGSizeMake(414, 896);
}

+ (CGSize)screenSizeFor61Inch {
    return CGSizeMake(414, 896);
}

+ (CGSize)screenSizeFor58Inch {
    return CGSizeMake(375, 812);
}

+ (CGSize)screenSizeFor55Inch {
    return CGSizeMake(414, 736);
}

+ (CGSize)screenSizeFor47Inch {
    return CGSizeMake(375, 667);
}

+ (CGSize)screenSizeFor40Inch {
    return CGSizeMake(320, 568);
}

+ (CGSize)screenSizeFor35Inch {
    return CGSizeMake(320, 480);
}

static CGFloat preferredLayoutWidth = -1;
+ (CGFloat)preferredLayoutAsSimilarScreenWidthForIPad {
    if (preferredLayoutWidth < 0) {
        NSArray<NSNumber *> *widths = @[@([self screenSizeFor65Inch].width),
                                        @([self screenSizeFor58Inch].width),
                                        @([self screenSizeFor40Inch].width)];
        preferredLayoutWidth = SCREEN_WIDTH;
        UIWindow *window = [UIApplication sharedApplication].delegate.window ?: [[UIWindow alloc] init];// iOS 9 及以上的系统，新 init 出来的 window 自动被设置为当前 App 的宽度
        CGFloat windowWidth = CGRectGetWidth(window.bounds);
        for (NSInteger i = 0; i < widths.count; i++) {
            if (windowWidth <= widths[i].qmui_CGFloatValue) {
                preferredLayoutWidth = widths[i].qmui_CGFloatValue;
                continue;
            }
        }
    }
    return preferredLayoutWidth;
}

+ (UIEdgeInsets)safeAreaInsetsForDeviceWithNotch {
    if (![self isNotchedScreen]) {
        return UIEdgeInsetsZero;
    }
    
    if ([self isIPad]) {
        return UIEdgeInsetsMake(0, 0, 20, 0);
    }
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return UIEdgeInsetsMake(44, 0, 34, 0);
            
        case UIInterfaceOrientationPortraitUpsideDown:
            return UIEdgeInsetsMake(34, 0, 44, 0);
            
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            return UIEdgeInsetsMake(0, 44, 21, 44);
            
        case UIInterfaceOrientationUnknown:
        default:
            return UIEdgeInsetsMake(44, 0, 34, 0);
    }
}

static NSInteger isHighPerformanceDevice = -1;
+ (BOOL)isHighPerformanceDevice {
    if (isHighPerformanceDevice < 0) {
        NSString *model = [QMUIHelper deviceModel];
        NSString *identifier = [model qmui_stringMatchedByPattern:@"\\d+"];
        NSInteger version = identifier.integerValue;
        if (IS_IPAD) {
            isHighPerformanceDevice = version >= 5 ? 1 : 0;// iPad Air 2
        } else {
            isHighPerformanceDevice = version >= 10 ? 1 : 0;// iPhone 8
        }
    }
    return isHighPerformanceDevice > 0;
}

+ (BOOL)isZoomedMode {
    if (!IS_IPHONE) {
        return NO;
    }
    
    CGFloat nativeScale = UIScreen.mainScreen.nativeScale;
    CGFloat scale = UIScreen.mainScreen.scale;
    
    // 对于所有的 Plus 系列 iPhone，屏幕物理像素低于软件层面的渲染像素，不管标准模式还是放大模式，nativeScale 均小于 scale，所以需要特殊处理才能准确区分放大模式
    // https://www.paintcodeapp.com/news/ultimate-guide-to-iphone-resolutions
    BOOL shouldBeDownsampledDevice = CGSizeEqualToSize(UIScreen.mainScreen.nativeBounds.size, CGSizeMake(1080, 1920));
    if (shouldBeDownsampledDevice) {
        scale /= 1.15;
    }
    
    return nativeScale > scale;
}

- (void)handleAppSizeWillChange:(NSNotification *)notification {
    preferredLayoutWidth = -1;
}

+ (CGSize)applicationSize {
    /// applicationFrame 在 iPad 下返回的 size 要比 window 实际的 size 小，这个差值体现在 origin 上，所以用 origin + size 修正得到正确的大小。
    BeginIgnoreDeprecatedWarning
    CGRect applicationFrame = [UIScreen mainScreen].applicationFrame;
    EndIgnoreDeprecatedWarning
    return CGSizeMake(applicationFrame.size.width + applicationFrame.origin.x, applicationFrame.size.height + applicationFrame.origin.y);
}

@end

@implementation QMUIHelper (UIApplication)

+ (void)renderStatusBarStyleDark {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

+ (void)renderStatusBarStyleLight {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

+ (void)dimmedApplicationWindow {
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    window.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
    [window tintColorDidChange];
}

+ (void)resetDimmedApplicationWindow {
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    window.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
    [window tintColorDidChange];
}

@end

@implementation QMUIHelper (Animation)

+ (void)executeAnimationBlock:(__attribute__((noescape)) void (^)(void))animationBlock completionBlock:(__attribute__((noescape)) void (^)(void))completionBlock {
    if (!animationBlock) return;
    [CATransaction begin];
    [CATransaction setCompletionBlock:completionBlock];
    animationBlock();
    [CATransaction commit];
}

@end

@implementation QMUIHelper (SystemVersion)

+ (NSInteger)numbericOSVersion {
    NSString *OSVersion = [[UIDevice currentDevice] systemVersion];
    NSArray *OSVersionArr = [OSVersion componentsSeparatedByString:@"."];
    
    NSInteger numbericOSVersion = 0;
    NSInteger pos = 0;
    
    while ([OSVersionArr count] > pos && pos < 3) {
        numbericOSVersion += ([[OSVersionArr objectAtIndex:pos] integerValue] * pow(10, (4 - pos * 2)));
        pos++;
    }
    
    return numbericOSVersion;
}

+ (NSComparisonResult)compareSystemVersion:(NSString *)currentVersion toVersion:(NSString *)targetVersion {
    NSArray *currentVersionArr = [currentVersion componentsSeparatedByString:@"."];
    NSArray *targetVersionArr = [targetVersion componentsSeparatedByString:@"."];
    
    NSInteger pos = 0;
    
    while ([currentVersionArr count] > pos || [targetVersionArr count] > pos) {
        NSInteger v1 = [currentVersionArr count] > pos ? [[currentVersionArr objectAtIndex:pos] integerValue] : 0;
        NSInteger v2 = [targetVersionArr count] > pos ? [[targetVersionArr objectAtIndex:pos] integerValue] : 0;
        if (v1 < v2) {
            return NSOrderedAscending;
        }
        else if (v1 > v2) {
            return NSOrderedDescending;
        }
        pos++;
    }
    
    return NSOrderedSame;
}

+ (BOOL)isCurrentSystemAtLeastVersion:(NSString *)targetVersion {
    return [QMUIHelper compareSystemVersion:[[UIDevice currentDevice] systemVersion] toVersion:targetVersion] == NSOrderedSame || [QMUIHelper compareSystemVersion:[[UIDevice currentDevice] systemVersion] toVersion:targetVersion] == NSOrderedDescending;
}

+ (BOOL)isCurrentSystemLowerThanVersion:(NSString *)targetVersion {
    return [QMUIHelper compareSystemVersion:[[UIDevice currentDevice] systemVersion] toVersion:targetVersion] == NSOrderedAscending;
}

@end

@implementation QMUIHelper

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [QMUIHelper sharedInstance];// 确保内部的变量、notification 都正确配置
    });
}

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static QMUIHelper *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
        // 先设置默认值，不然可能变量的指针地址错误
        instance.keyboardVisible = NO;
        instance.lastKeyboardHeight = 0;
        instance.orientationBeforeChangingByHelper = UIDeviceOrientationUnknown;
        
        [[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(handleAppSizeWillChange:) name:QMUIAppSizeWillChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(handleDeviceOrientationNotification:) name:UIDeviceOrientationDidChangeNotification object:nil];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone{
    return [self sharedInstance];
}

- (void)dealloc {
    // QMUIHelper 若干个分类里有用到消息监听，所以在 dealloc 的时候注销一下
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
