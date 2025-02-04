//
//  QMUIWindowSizeMonitor.m
//  qmuidemo
//
//  Created by ziezheng on 2019/5/27.
//  Copyright © 2019 QMUI Team. All rights reserved.
//

#import "QMUIWindowSizeMonitor.h"
#import "QMUICore.h"
#import "NSPointerArray+QMUI.h"

@interface NSObject (QMUIWindowSizeMonitor_Private)

@property(nonatomic, readonly) NSMutableArray <QMUIWindowSizeObserverHandler> *qwsm_windowSizeChangeHandlers;

@end

@interface UIResponder (QMUIWindowSizeMonitor_Private)

@property(nonatomic, weak) UIWindow *qwsm_previousWindow;

@end


@interface UIWindow (QMUIWindowSizeMonitor_Private)

@property(nonatomic, assign) CGSize qwsm_previousSzie;
@property(nonatomic, readonly) NSPointerArray *qwsm_sizeObservers;
@property(nonatomic, readonly) NSPointerArray *qwsm_canReceiveWindowDidTransitionToSizeResponders;

- (void)qwsm_addSizeObserver:(NSObject *)observer;

@end



@implementation NSObject (QMUIWindowSizeMonitor)

- (void)qmui_addSizeObserverForMainWindow:(QMUIWindowSizeObserverHandler)handler {
    [self qmui_addSizeObserverForWindow:[UIApplication sharedApplication].delegate.window handler:handler];
}

- (void)qmui_addSizeObserverForWindow:(UIWindow *)window handler:(QMUIWindowSizeObserverHandler)handler {
    NSAssert(window != nil, @"window is nil!");
    
    struct Block_literal {
        void *isa;
        int flags;
        int reserved;
        void (*__FuncPtr)(void *, ...);
    };
    
    void * blockFuncPtr = ((__bridge struct Block_literal *)handler)->__FuncPtr;
    for (QMUIWindowSizeObserverHandler handler in self.qwsm_windowSizeChangeHandlers) {
        // 由于利用 block 的 __FuncPtr 指针来判断同一个实现的 block 过滤掉，防止重复添加监听
        if (((__bridge struct Block_literal *)handler)->__FuncPtr == blockFuncPtr) {
            return;
        }
    }
    
    [self.qwsm_windowSizeChangeHandlers addObject:handler];
    [window qwsm_addSizeObserver:self];
}

- (NSMutableArray<QMUIWindowSizeObserverHandler> *)qwsm_windowSizeChangeHandlers {
    NSMutableArray *_handlers = objc_getAssociatedObject(self, _cmd);
    if (!_handlers) {
        _handlers = [NSMutableArray array];
        objc_setAssociatedObject(self, _cmd, _handlers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return _handlers;
}

@end

@implementation UIWindow (QMUIWindowSizeMonitor)

QMUISynthesizeCGSizeProperty(qwsm_previousSzie, setQwsm_previousSzie)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        OverrideImplementation([UIWindow class], @selector(layoutSubviews), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^void(UIWindow *selfObject) {
                
                // call super
                void (*originSelectorIMP)(id, SEL);
                originSelectorIMP = (void (*)(id, SEL))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD);
                
                CGSize newSize = selfObject.bounds.size;
                if (!CGSizeEqualToSize(newSize, selfObject.qwsm_previousSzie)) {
                    if (!CGSizeEqualToSize(selfObject.qwsm_previousSzie, CGSizeZero)) {
                        NSLog(@"%@ :change size from %@ to %@",NSStringFromClass(selfObject.class), NSStringFromCGSize(selfObject.qwsm_previousSzie),NSStringFromCGSize(newSize));
                        [selfObject qwsm_notifyObserversWithNewSize:newSize];
                    }
                    selfObject.qwsm_previousSzie = selfObject.bounds.size;
                    
                }
                
            };
        });
        
        OverrideImplementation([UIView class], @selector(willMoveToWindow:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^void(UIView *selfObject, UIWindow *newWindow) {
                
                // call super
                void (*originSelectorIMP)(id, SEL, UIWindow *);
                originSelectorIMP = (void (*)(id, SEL, UIWindow *))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, newWindow);
                
                if (newWindow) {
                    if ([selfObject respondsToSelector:@selector(windowDidTransitionToSize:)]) {
                        [newWindow qwsm_addDidTransitionToSizeMethodReceiver:selfObject];
                    }
                    UIResponder *nextResponder = [selfObject nextResponder];
                    if ([nextResponder isKindOfClass:[UIViewController class]] && [nextResponder respondsToSelector:@selector(windowDidTransitionToSize:)]) {
                        [newWindow qwsm_addDidTransitionToSizeMethodReceiver:nextResponder];
                    }
                    
                }
                
            };
        });
    });
}

- (void)qwsm_notifyObserversWithNewSize:(CGSize)newSize {
    for (NSUInteger i = 0, count = self.qwsm_sizeObservers.count; i < count; i++) {
        NSObject *object = [self.qwsm_sizeObservers pointerAtIndex:i];
        for (NSUInteger i = 0, count = object.qwsm_windowSizeChangeHandlers.count; i < count; i++) {
            QMUIWindowSizeObserverHandler handler = object.qwsm_windowSizeChangeHandlers[i];
            handler(newSize);
        }
    }
    
    for (NSUInteger i = 0, count = self.qwsm_canReceiveWindowDidTransitionToSizeResponders.count; i < count; i++) {
        UIResponder <QMUIWindowSizeMonitorProtocol>*responder = [self.qwsm_canReceiveWindowDidTransitionToSizeResponders pointerAtIndex:i];
        [responder windowDidTransitionToSize:self.bounds.size];
    }
}

- (void)qwsm_removeSizeObserver:(NSObject *)observer {
    NSUInteger index = [self.qwsm_sizeObservers qmui_indexOfPointer:(__bridge void *)observer];
    if (index != NSNotFound) {
        [self.qwsm_sizeObservers removePointerAtIndex:index];
    }
}

- (void)qwsm_addDidTransitionToSizeMethodReceiver:(UIResponder *)receiver {
    if ([self.qwsm_canReceiveWindowDidTransitionToSizeResponders qmui_containsPointer:(__bridge void *)(receiver)]) return;
    if (receiver.qwsm_previousWindow && receiver.qwsm_previousWindow != self) {
        [receiver.qwsm_previousWindow qwsm_removeSizeObserver:receiver];
    }
    receiver.qwsm_previousWindow = self;
    [self.qwsm_canReceiveWindowDidTransitionToSizeResponders addPointer:(__bridge void *)(receiver)];
}

- (void)qwsm_addSizeObserver:(NSObject *)observer {
    if ([self.qwsm_sizeObservers qmui_containsPointer:(__bridge void *)(observer)]) return;
    [self.qwsm_sizeObservers addPointer:(__bridge void *)(observer)];
}

- (NSPointerArray *)qwsm_sizeObservers {
    NSPointerArray *qwsm_sizeObservers = objc_getAssociatedObject(self, _cmd);
    if (!qwsm_sizeObservers) {
        qwsm_sizeObservers = [NSPointerArray weakObjectsPointerArray];
        objc_setAssociatedObject(self, _cmd, qwsm_sizeObservers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return qwsm_sizeObservers;
}

- (NSPointerArray *)qwsm_canReceiveWindowDidTransitionToSizeResponders {
    NSPointerArray *qwsm_responders = objc_getAssociatedObject(self, _cmd);
    if (!qwsm_responders) {
        qwsm_responders = [NSPointerArray weakObjectsPointerArray];
        objc_setAssociatedObject(self, _cmd, qwsm_responders, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return qwsm_responders;
}

@end

@implementation UIResponder (QMUIWindowSizeMonitor)

QMUISynthesizeIdWeakProperty(qwsm_previousWindow, setQwsm_previousWindow)

@end
