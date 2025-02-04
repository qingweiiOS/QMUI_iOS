//
//  QMUIAnimationHelper.h
//  WeRead
//
//  Created by zhoonchen on 2018/9/3.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QMUIEasings.h"

@interface QMUIAnimationHelper : NSObject

typedef NS_ENUM(NSInteger, QMUIAnimationEasings) {
    QMUIAnimationEasingsLinear,
    QMUIAnimationEasingsEaseInSine,
    QMUIAnimationEasingsEaseOutSine,
    QMUIAnimationEasingsEaseInOutSine,
    QMUIAnimationEasingsEaseInQuad,
    QMUIAnimationEasingsEaseOutQuad,
    QMUIAnimationEasingsEaseInOutQuad,
    QMUIAnimationEasingsEaseInCubic,
    QMUIAnimationEasingsEaseOutCubic,
    QMUIAnimationEasingsEaseInOutCubic,
    QMUIAnimationEasingsEaseInQuart,
    QMUIAnimationEasingsEaseOutQuart,
    QMUIAnimationEasingsEaseInOutQuart,
    QMUIAnimationEasingsEaseInQuint,
    QMUIAnimationEasingsEaseOutQuint,
    QMUIAnimationEasingsEaseInOutQuint,
    QMUIAnimationEasingsEaseInExpo,
    QMUIAnimationEasingsEaseOutExpo,
    QMUIAnimationEasingsEaseInOutExpo,
    QMUIAnimationEasingsEaseInCirc,
    QMUIAnimationEasingsEaseOutCirc,
    QMUIAnimationEasingsEaseInOutCirc,
    QMUIAnimationEasingsEaseInBack,
    QMUIAnimationEasingsEaseOutBack,
    QMUIAnimationEasingsEaseInOutBack,
    QMUIAnimationEasingsEaseInElastic,
    QMUIAnimationEasingsEaseOutElastic,
    QMUIAnimationEasingsEaseInOutElastic,
    QMUIAnimationEasingsEaseInBounce,
    QMUIAnimationEasingsEaseOutBounce,
    QMUIAnimationEasingsEaseInOutBounce,
    QMUIAnimationEasingsSpring, // 自定义任意弹簧曲线
    QMUIAnimationEasingsSpringKeyboard // 系统键盘动画曲线
};

/**
 * 动画插值器
 * 根据给定的 easing 曲线，计算出初始值和结束值在当前的时间 time 对应的值。value 目前现在支持 NSNumber、UIColor 以及 NSValue 类型的 CGPoint、CGSize、CGRect、CGAffineTransform、UIEdgeInsets
 * @param fromValue 初始值
 * @param toValue 结束值
 * @param time 当前帧时间
 * @param easing 曲线，见`QMUIAnimationEasings`
 */
+ (id)interpolateFromValue:(id)fromValue
                   toValue:(id)toValue
                      time:(CGFloat)time
                    easing:(QMUIAnimationEasings)easing;
/**
 * 动画插值器，支持弹簧参数
 * mass|damping|stiffness|initialVelocity 仅在 QMUIAnimationEasingsSpring 的时候才生效
 */
+ (id)interpolateSpringFromValue:(id)fromValue
                         toValue:(id)toValue
                            time:(CGFloat)time
                            mass:(CGFloat)mass
                         damping:(CGFloat)damping
                       stiffness:(CGFloat)stiffness
                 initialVelocity:(CGFloat)initialVelocity
                          easing:(QMUIAnimationEasings)easing;

@end
