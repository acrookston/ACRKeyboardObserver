## ACRKeyboardObserver

Swift iOS keyboard observer helping you manage keyboard notifications, frame changes and simplifies animations.

ACRKeyboardObserver makes it easy to handle iOS keyboard state changes like `willShow` or `didHide`. It also does a better job at providing an accurate keyboard frame size, rather than the native callbacks. It's especially useful when dismissing a keyboard interactively.


### Installation

Install with **CocoaPods**.

```ruby
platform :ios, '8.0'
use_frameworks!
pod 'ACRKeyboardObserver'
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
    func keyboardChanged(_ status: KeyboardStatus) {
        // 3.1.
        if let animation = status.animation {
            UIView.animate(withDuration: animation.duration, delay: 0, options: animation.option, animations: { () -> Void in
                self.updateFrameFromKeyboard(top: animation.top)
            }, completion: nil)
        } else if let frame = status.frame {
            // 3.2.
            updateFrameFromKeyboard(top: frame.origin.y)
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
textView.keyboardDismissMode = .interactive
```

You will get `status.state == .frameChanged` notifications when the user starts dragging to dismiss. When the drag is completed and keyboard is technically dismissed, you will also get the `.WillHide` and `.DidHide` calls. These calls, as always, include the keyboard frame but it's not reporting the real frame / origin. I haven't decided on how to handle this but leaning towards not trusting iOS on the keyboard size and instead figure out the real keyboard frame.

One workaround is looking at your views, if they are in the "keyboard is hidden" state, ignore the `.willHide` and `.didHide` calls.

### License

MIT

## Contributing

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

Bug reports and pull requests are welcome via GitHub at https://github.com/acrookston/ACRAutoComplete.

You will need [SwiftLint](https://github.com/realm/SwiftLint) installed for the build process to pass.

Unfortunately there are no tests or example app.

If you're making a big change, please open an Issue first, so we can discuss. Otherwise:

- Fork the repo
- Open `ACRKeyboardObserver.xcodeproj`
- Make your changes
- Write tests if possible
- Confirm that SwiftLint passes (no Xcode warnings).
- Create a pull-request on Github.

### Thanks?

I love hearing when my stuff works (or not) so please let me know if you find this library helpful. I'm [@acr](http://twitter.com/acr) on Twitter or ping me here on Github.

Enjoy!
