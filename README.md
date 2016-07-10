## ACRKeyboardObserver

Swift iOS keyboard observer helping you manage keyboard notifications, frame changes and simplifies animations.

ACRKeyboardObserver makes it easy to handle iOS keyboard state changes like WillShow or DidHide. It also does a better job at providing an accurate keyboard frame size, rather than the native callbacks. It's especially useful when dismissing a keyboard interactively.


#### Swift 3

There is an experimental Swift 3 branch located called [swift-3](/acrookston/ACRKeyboardObserver/tree/swift-3).

### Installation

Install with **CocoaPods**.

```ruby
platform :ios, '8.0'
use_frameworks!
pod 'ACRKeyboardObserver', '>= 0.1.0'
```


### Usage

Start/stop the observer in your AppDelegate:

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {

    …

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        ACRKeyboardObserver.observer.start()
        return true
    }

    …

    func applicationWillTerminate(application: UIApplication) {
        ACRKeyboardObserver.observer.stop()
    }
}
```

UIViewController example:

1. First add the controller as a delegate to the observer.
2. Implement the delegate method `keyboardChanged(status: KeyboardStatus)`.
3. In the delegate method update views:
  1. Either by using the optional animation object.
  2. By directly updating the frame.

```swift

import UIKit
import ACRKeyboardObserver

class SomeKeyboardController: UIViewController, ACRKeyboardObserverDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // 1.
        ACRKeyboardObserver.observer.addDelegate(self)
    }

    // 2.
    func keyboardChanged(status: KeyboardStatus) {
        if let animation = status.animation {
            // 3.1.
            UIView.animateWithDuration(animation.duration, delay: 0, options: animation.option, animations: { () -> Void in
                self.updateFrameFromKeyboard(animation.top)
            }, completion: nil)
        } else if let frame = status.frame {
            // 3.2.
            updateFrameFromKeyboard(frame.origin.y)
        }
    }

    func updateFrameFromKeyboard(top: CGFloat) {
        // update some views
    }
}
```


I'll expand the documentation but the code is pretty simple and it should be fairly easy to read through it.

### Known issue(s)

If you're allowing the user to dismiss the keyboard interactively, eg:

```swift
textView.keyboardDismissMode = .Interactive
```

You will get `status.state == .FrameChanged` notifications when the user starts dragging to dismiss. When the drag is completed and keyboard is technically dismissed, you will also get the `.WillHide` and `.DidHide` calls. These calls, as always, include the keyboard frame but it's not reporting the real frame / origin. I haven't decided on how to handle this but leaning towards not trusting iOS on the keyboard size and instead figure out the real keyboard frame.

One workaround is looking at your views, if they are in the "keyboard is hidden" state, ignore the `.WillHide` and `.DidHide` calls.

### License

MIT


### Contributions

I'm happy to include any improvements. There's no tests or demo app so I'll have to manually test any contributions, but please don't let that stop you. Those items might be a good place to help out. ;)

I haven't done extensive bug testing but the basics are working in my app. If you discover something, post an issue and I'll take a look at it. I'm usually good at responding quickly.


### Thanks?

I love hearing when my stuff works (or not) so please let me know if you find this library helpful. I'm [@acr](http://twitter.com/acr) on Twitter or ping me here on Github.

Enjoy!