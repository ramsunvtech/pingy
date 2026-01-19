# Step 1: Create a Release Keystore

## On Windows

```
keytool -genkey -v -keystore %userprofile%\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias steppy
```

## On macOS / Linux

```
keytool -genkey -v -keystore ~/steppy-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias steppy
```

# Step 2: Create a key.properties file

```
storePassword=YOUR_KEY_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=steppy
storeFile=/Users/YOUR_NAME/steppy-keystore.jks
```

# Step 3: Configure Gradle to use the Key

1. Before the android { ... } block, add this:
2. Update the signingConfigs and buildTypes sections

# Step 4: Build and Upload

```
flutter clean
flutter build appbundle
```