//
//  ACRKeyboardObserver.swift
//  ACRKeyboardObserver
//
//  Created by Andrew C on 1/30/16.
//  Copyright © 2016 Andrew Crookston. All rights reserved.
//

import Foundation

public enum KeyboardState {
    case Hidden, Visible, FrameChanged, WillHide, DidHide, WillShow, DidShow
}

public struct KeyboardStatus {
    public var state: KeyboardState
    public var frame: CGRect?
    public var animation: KeyboardAnimation?
    public var view: UIView?
}

public struct KeyboardAnimation {
    public var top : CGFloat
    public var curve : UIViewAnimationCurve
    public var duration : NSTimeInterval
    public var option : UIViewAnimationOptions
}

public protocol ACRKeyboardObserverDelegate : class {
    func keyboardChanged(status: KeyboardStatus)
}

public class ACRKeyboardObserver : NSObject {

    public static var observer = ACRKeyboardObserver()

    public var animation : KeyboardAnimation?

    public var keyboardStatus = KeyboardStatus(state: .Hidden, frame: nil, animation: nil, view: nil) {
        didSet { updateDelegates() }
    }

    public func start() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardDidChange:"), name: UIKeyboardDidChangeFrameNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardDidHide:"), name: UIKeyboardDidHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardDidShow:"), name: UIKeyboardDidShowNotification, object: nil)
    }

    public func stop() {
        unregisterKeyboardObserver()
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidChangeFrameNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object:nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
    }

    public func addDelegate(delegate: ACRKeyboardObserverDelegate) {
        delegates.append(DelegateWrapper(delegate: delegate))
    }

    public func removeDelegate(delegate: ACRKeyboardObserverDelegate) {
        var updated = [DelegateWrapper]()
        for wrapper in delegates {
            if wrapper.delegate !== delegate {
                updated.append(wrapper)
            }
        }
        delegates = updated
    }

    // MARK: - Private variables and structs

    private struct DelegateWrapper {
        weak var delegate : ACRKeyboardObserverDelegate?

        func isValid() -> Bool {
            return delegate != nil
        }
    }

    private let KVOKey = "position"
    private let InputViewPrefix = "<UIInput"
    private let InputHostPrefix = "<UIInputSetHostView"

    private var delegates = [DelegateWrapper]()
    private var keyboard : UIView?

    private override init() {
        super.init()
        registerKeyboardObserver()
    }

    deinit {
        unregisterKeyboardObserver()
    }

    // MARK: - Notification callbacks

    func keyboardDidChange(notification: NSNotification) {
        // Since we handle the keyboard frame KVO-style we don't want to send multiple FrameChanged
        guard keyboard == nil else { return }
        registerKeyboardObserver()
        status(.FrameChanged, notification: notification)
    }

    func keyboardWillShow(notification: NSNotification) {
        status(.WillShow, notification: notification)
    }

    func keyboardDidShow(notification: NSNotification) {
        status(.DidShow, notification: notification)
    }

    func keyboardWillHide(notification: NSNotification) {
        status(.WillHide, notification: notification)
    }

    func keyboardDidHide(notification: NSNotification) {
        status(.DidHide, notification: notification)
    }

    private func status(status: KeyboardState, notification: NSNotification?) {
        animation = extractAnimation(notification)
        keyboardStatus = KeyboardStatus(state: status, frame: keyboard?.layer.frame, animation: animation, view: keyboard)
    }

    private func extractAnimation(notification: NSNotification?) -> KeyboardAnimation? {
        guard notification != nil else { return nil }

        if let info = notification!.userInfo {
            let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue()
            let curveValue = info[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let durationValue = info[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber

            if keyboardFrame == nil || curveValue == nil || durationValue == nil {
                return nil
            }

            let portrait = UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation)
            let height = portrait ? keyboardFrame!.size.height : keyboardFrame!.size.width;
            let screenHeight = UIScreen.mainScreen().bounds.size.height

            let app = UIApplication.sharedApplication()
            let statusBarHeight = app.statusBarHidden ? 0 : app.statusBarFrame.size.height

            let animateToHeight = screenHeight - height - statusBarHeight
            let animationCurve = UIViewAnimationCurve(rawValue: Int(curveValue!.intValue)) ?? .EaseInOut
            let animationDuration = Double(durationValue!.doubleValue)
            let animationOption = UIViewAnimationOptions(rawValue: UInt(curveValue!.intValue << 16))
            // We bitshift animation curve << 16 to convert it from a view animation curve to a view animation option.
            // The result is the secret undeclared animation curve that Apple introduced in iOS8.

            return KeyboardAnimation(top: animateToHeight, curve: animationCurve, duration: animationDuration, option: animationOption)
        }
        return nil
    }

    // MARK: - Handle delegates

    private func updateDelegates() {
        removeInvalidDelegates()
        for wrapper in delegates {
            if wrapper.isValid() {
                wrapper.delegate?.keyboardChanged(keyboardStatus)
            }
        }
    }

    private func removeInvalidDelegates() {
        var updated = [DelegateWrapper]()
        for wrapper in delegates {
            if wrapper.isValid() {
                updated.append(wrapper)
            }
        }
        delegates = updated
    }

    // MARK: - Handle keyboard view

    private func getKeyboardView() -> UIView? {
        guard UIApplication.sharedApplication().windows.count > 0 else { return nil }

        for window in UIApplication.sharedApplication().windows {
            // Because we cant get access to the UIPeripheral throught the SDK we use its UIView.
            // UIPeripheral is a subclass of UIView anyway.
            // Our keyboard will end up as a UIView reference to the UIPeripheral / UIInput we want.
            // For iOS 8+ we have to look a level deeper than 4-7.
            // UIPeripheral should work for iOS 4-7 (only confirmed in iOS 7). In 3.0 you would use "<UIKeyboard"
            for view in window.subviews {
                // If anybody needs iOS 7 support (does Swift even work on 7?) and wants to patch this, go ahead.
                // if view.description.hasPrefix("<UIPeripheral") {
                //     registerKeyboardObserver(view)
                // }

                // iOS 8+
                if view.description.hasPrefix(InputViewPrefix) {
                    for subview in view.subviews {
                        if subview.description.hasPrefix(InputHostPrefix) {
                            return subview
                        }
                    }
                }
            }
        }
        return nil
    }

    private func registerKeyboardObserver() {
        unregisterKeyboardObserver()
        keyboard = getKeyboardView()
        keyboard?.layer.addObserver(self, forKeyPath: KVOKey, options: .Initial, context: nil)
    }

    private func unregisterKeyboardObserver() {
        guard let keyboard = keyboard else { return }
        keyboard.layer.removeObserver(self, forKeyPath: KVOKey)
    }

    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyboard != nil && object != nil && keyPath != nil {
            if keyboard!.layer == (object as? CALayer) && KVOKey == keyPath! {
                status(.FrameChanged, notification: nil)
                return
            }
        }

        super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
    }
}
