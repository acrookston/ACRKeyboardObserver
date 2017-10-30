//
//  NotificationCenterExtensions.swift
//  ACRKeyboardObserver
//
//  Created by Andrew C on 10/29/17.
//  Copyright © 2017 Andrew Crookston. All rights reserved.
//

import Foundation

extension NotificationCenter {
    func add(observer: Any, selector: Selector, name: NSNotification.Name, object: Any? = nil) {
        addObserver(observer, selector: selector, name: name, object: object)
    }

    func remove(observer: Any, name: NSNotification.Name, object: Any? = nil) {
        removeObserver(observer, name: name, object: object)
    }
}
