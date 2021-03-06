Pod::Spec.new do |s|
  s.name         = "ACRKeyboardObserver"
  s.version      = "0.4.0"
  s.summary      = "Swift iOS keyboard observer helping you manage keyboard notifications, frame changes and simplifies animations"

  s.description  = <<-DESC
ACRKeyboardObserver makes it easy to handle iOS keyboard state changes like WillShow or DidHide. It also does a better job at providing an accurate keyboard frame size, rather than the native callbacks. It's especially useful when dismissing a keyboard interactively.
                   DESC

  s.homepage         = "https://github.com/acrookston/ACRKeyboardObserver"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.source           = { :git => "https://github.com/acrookston/ACRKeyboardObserver.git", :tag => s.version.to_s }
  s.author           = { "Andrew Crookston" => "andrew@caoos.com" }
  s.social_media_url = "http://twitter.com/acr"

s.ios.deployment_target = '8.0'

  s.source_files = "ACRKeyboardObserver/*.swift"
end
