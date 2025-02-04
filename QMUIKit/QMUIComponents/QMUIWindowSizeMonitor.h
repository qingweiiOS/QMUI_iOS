//
//  QMUIWindowSizeMonitor.h
//  qmuidemo
//
//  Created by ziezheng on 2019/5/27.
//  Copyright © 2019 QMUI Team. All rights reserved.
//

#import <UIKit/UIkit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol QMUIWindowSizeMonitorProtocol <NSObject>

@optional

/**
 当继承自 UIResponder 的对象，比如 UIView 或 UIViewController 实现了这个方法时，其所属的 window 在大小发生改变后在这个方法回调。
 @note 类似系统的 [-viewWillTransitionToSize:withTransitionCoordinator:]，但是系统这个方法回调时 window 的大小实际上还未发生改变，如果你需要在 window 大小发生之后且在 layout 之前来处理一些逻辑时，可以放到这个方法去实现。
 @param size 所属窗口的新大小
 */

- (void)windowDidTransitionToSize:(CGSize)size;

@end

typedef void (^QMUIWindowSizeObserverHandler)(CGSize newWindowSize);

@interface NSObject (QMUIWindowSizeMonitor)

/**
 为当前对象添加主窗口 (UIApplication Delegate Window)的大小变化的监听，同一对象可重复添加多个监听，当对象销毁时监听自动失效。

 @param handler 窗口大小发生改变时的回调
 */
- (void)qmui_addSizeObserverForMainWindow:(QMUIWindowSizeObserverHandler)handler;
/**
 为当前对象添加指定窗口的大小变化监听，同一对象可重复添加多个监听，当对象销毁时监听自动失效。

 @param window 要监听的窗口
 @param handler 窗口大小发生改变时的回调
 */
- (void)qmui_addSizeObserverForWindow:(UIWindow *)window handler:(QMUIWindowSizeObserverHandler)handler;

@end

NS_ASSUME_NONNULL_END
