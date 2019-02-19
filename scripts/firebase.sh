if [ ! -d ./Firebase ]; then
  echo "Downloading Firebase 5.4.1..."

  curl -O "https://cdn.criptext.com/ios/Firebase-5.4.1.zip"
  unzip Firebase-5.4.1.zip

  echo "Copying Files..."

  cp -a ./Firebase/Analytics/. ./
  cp -a ./Firebase/Messaging/. ./
  cp ./Firebase/Firebase.h ./iOS-Email-Client
  cp ./Firebase/module.modulemap ./iOS-Email-Client

  echo "Firebase Script Completed!"
else 
  echo "Firebase already exists!"
fi