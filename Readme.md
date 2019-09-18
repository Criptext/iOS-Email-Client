# Criptext iOS Client

Finally, an email service that's built around your privacy. Get your @criptext.com email address and see what it's like to have peace of mind and privacy in every email you send.

Currently available on the App store.

<a href="https://itunes.apple.com/gt/app/criptext-secure-email/id1377890297?l=en&mt=8" target="_blank"><img src="https://cdn.criptext.com/Email/images/emailhome/go-apple.png" width="180px"/></a>

## Features

- End-to-end Encryption: Criptext uses the open source Signal Protocol library to encrypt your emails. Your emails are locked with a unique key that‘s generated and stored on your device alone, which means only you and your intended recipient can read the emails you send.
- No data collection: unlike every other email service out there, Criptext doesn't store your emails in its servers. Instead, your entire inbox is stored exclusively on your device.
- Easy to use: our app is designed to work as simple as any other email app — so much so, you'll forget how secure it is.

## Contributing Bug reports

We use GitHub for bug tracking. Please search the existing issues for your bug and create a new one if the issue is not yet tracked!

## Contributing Translations

<a href="https://lokalise.co/" target="_blank"><img src="https://lokalise.co/img/lokalise_logo_black.png" width="120px"/></a>

We use Lokalise for translations. If you are interested in helping please write us at <a href="mailto:support@criptext.com">support@criptext.com</a>

## Contributing Code

Firebase dependencies are not included within the repo. you should be able to add them manually downloading the [SDK](https://cdn.criptext.com/ios/Firebase-5.4.1.zip) and reading the instructions in the Readme. Or you can follow this steps:
- Download the SDK
- Import everything inside `Analytics/` and `Messaging/` in the root dir of your project (when importing, don't forget to check *Copy items if needed*)
- Go to App -> Build Settings -> Other Linker Flags, double-click it, double-click `+` and add `-ObjC`
- Import `Firebase.h` and `module.modulemap`
- Go to App -> Build Settings -> User Header Search Paths, double-click it, double-click `+` and add `${SRCROOT}/app_name`
- Run `carthage bootstrap --platform iOS --no-use-binaries --cache-builds`

Now you are ready to build and run the project

## Support

For troubleshooting and questions, please write us at <a href="mailto:support@criptext.com">support@criptext.com</a>

## License 

Copyright 2018 Criptext Inc.

Licensed under the GPLv2: http://www.gnu.org/licenses/gpl-2.0.html

App Store and the App Store logo are trademarks of Apple Inc.
