//
//  ACRKeyboardObserver.swift
//  ACRKeyboardObserver
//
//  Created by Andrew C on 1/30/16.
//  Copyright © 2016 Andrew Crookston. All rights reserved.
//

import Foundation

public enum KeyboardState {
    case hidden, visible, frameChanged, willHide, didHide, willShow, didShow
}

public struct KeyboardStatus {
    public var state: KeyboardState
    public var frame: CGRect?
    public var animation: KeyboardAnimation?
    public var view: UIView?
}

public struct KeyboardAnimation {
    public var top: CGFloat
    public var curve: UIViewAnimationCurve
    public var duration: Double
    public var option: UIViewAnimationOptions
}

public protocol ACRKeyboardObserverDelegate : class {
    func keyboardChanged(_ status: KeyboardStatus)
}

public class ACRKeyboardObserver: NSObject {

    public static var observer = ACRKeyboardObserver()

    public var animation: KeyboardAnimation?

    public var keyboardStatus = KeyboardStatus(state: .hidden, frame: nil, animation: nil, view: nil) {
        didSet { updateDelegates() }
    }

    public func start() {
        NotificationCenter.default.add(observer: self,
                                       selector: #selector(keyboardDidChange),
                                       name: .UIKeyboardDidChangeFrame)
        NotificationCenter.default.add(observer: self,
                                       selector: #selector(keyboardWillHide),
                                       name: .UIKeyboardWillHide)
        NotificationCenter.default.add(observer: self,
                                       selector: #selector(keyboardDidHide),
                                       name: .UIKeyboardDidHide)
        NotificationCenter.default.add(observer: self,
                                       selector: #selector(keyboardWillShow),
                                       name: .UIKeyboardWillShow)
        NotificationCenter.default.add(observer: self,
                                       selector: #selector(keyboardDidShow),
                                       name: .UIKeyboardDidShow)
    }

    public func stop() {
        unregisterKeyboardObserver()
        NotificationCenter.default.remove(observer: self, name: .UIKeyboardDidChangeFrame)
        NotificationCenter.default.remove(observer: self, name: .UIKeyboardWillHide)
        NotificationCenter.default.remove(observer: self, name: .UIKeyboardDidHide)
        NotificationCenter.default.remove(observer: self, name: .UIKeyboardWillShow)
        NotificationCenter.default.remove(observer: self, name: .UIKeyboardDidShow)
    }

    public func addDelegate(_ delegate: ACRKeyboardObserverDelegate) {
        delegates.append(DelegateWrapper(delegate: delegate))
    }

    public func removeDelegate(_ delegate: ACRKeyboardObserverDelegate) {
        var updated = [DelegateWrapper]()
        for wrapper in delegates where wrapper.delegate !== delegate {
            updated.append(wrapper)
        }
        delegates = updated
    }

    // MARK: - Private variables and structs

    private struct DelegateWrapper {
        weak var delegate: ACRKeyboardObserverDelegate?

        func isValid() -> Bool {
            return delegate != nil
        }
    }

    private let KVOKey = "position"
    private let inputViewPrefix = "<UIInput"
    private let inputHostPrefix = "<UIInputSetHostView"

    private var delegates = [DelegateWrapper]()
    private var keyboard: UIView?

    private override init() {
        super.init()
        registerKeyboardObserver()
    }

    deinit {
        unregisterKeyboardObserver()
    }

    // MARK: - Notification callbacks

    @objc func keyboardDidChange(_ notification: Notification) {
        // Since we handle the keyboard frame KVO-style we don't want to send multiple FrameChanged
        guard keyboard == nil else { return }
        registerKeyboardObserver()
        status(.frameChanged, notification: notification)
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        status(.willShow, notification: notification)
    }

    @objc func keyboardDidShow(_ notification: Notification) {
        status(.didShow, notification: notification)
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        status(.willHide, notification: notification)
    }

    @objc func keyboardDidHide(_ notification: Notification) {
        status(.didHide, notification: notification)
    }

    private func status(_ status: KeyboardState, notification: Notification?) {
        animation = extractAnimation(notification)
        keyboardStatus = KeyboardStatus(state: status,
                                        frame: keyboard?.layer.frame,
                                        animation: animation,
                                        view: keyboard)
    }

    private func extractAnimation(_ notification: Notification?) -> KeyboardAnimation? {
        guard notification != nil else { return nil }

        if let info = (notification! as NSNotification).userInfo {
            let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let curveValue = info[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let durationValue = info[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber

            if keyboardFrame == nil || curveValue == nil || durationValue == nil {
                return nil
            }

            let app = UIApplication.shared
            let height = keyboardFrame!.size.height
            let screenHeight = UIScreen.main.bounds.size.height
            let statusBarHeight = app.isStatusBarHidden ? 0 : app.statusBarFrame.size.height

            let animateToHeight = screenHeight - height - statusBarHeight
            let animationCurve = UIViewAnimationCurve(rawValue: Int(curveValue!.int32Value)) ?? .easeInOut
            let animationDuration = Double(durationValue!.doubleValue)
            let animationOption = UIViewAnimationOptions(rawValue: UInt(curveValue!.int32Value << 16))
            // We bitshift animation curve << 16 to convert it from a view animation curve to a view animation option.
            // The result is the secret undeclared animation curve that Apple introduced in iOS8.

            return KeyboardAnimation(top: animateToHeight,
                                     curve: animationCurve,
                                     duration: animationDuration,
                                     option: animationOption)
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
        guard UIApplication.shared.windows.count > 0 else { return nil }

        for window in UIApplication.shared.windows {
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
                if view.description.hasPrefix(inputViewPrefix) {
                    for subview in view.subviews {
                        if subview.description.hasPrefix(inputHostPrefix) {
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
        keyboard?.layer.addObserver(self, forKeyPath: KVOKey, options: .initial, context: nil)
    }

    private func unregisterKeyboardObserver() {
        guard let keyboard = keyboard else { return }
        keyboard.layer.removeObserver(self, forKeyPath: KVOKey)
    }

    public override func observeValue(forKeyPath keyPath: String?,
                                      of object: Any?,
                                      change: [NSKeyValueChangeKey : Any]?,
                                      context: UnsafeMutableRawPointer?) {
        if keyboard != nil && object != nil && keyPath != nil {
            if keyboard!.layer == (object as? CALayer) && KVOKey == keyPath! {
                status(.frameChanged, notification: nil)
                return
            }
        }

        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
}
