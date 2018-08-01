# iOS Email Client

## Getting Started

Firebase dependencies are not included within the repo. you should be able to add them manually downloading the [SDK](https://firebase.google.com/download/ios) and reading the instructions in the Readme. Or you can follow this steps:
- Download the SDK
- Import everything inside `Analytics/` and `Messaging/` in the root dir of your porject (when importing, don't forget to check *Copy items if needed*)
- Go to App -> Build Settings -> Other Linker Flags, double-click it, double-click `+` and add `-ObjC`
- Import `Firebase.h` and `module.modulemap`
- Go to App -> Build Settings -> User Header Search Paths, double-click it, double-click `+` and add `${SRCROOT}/app_name`
Now you are ready to build and run the project