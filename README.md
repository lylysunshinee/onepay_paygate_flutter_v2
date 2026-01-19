# onepay_paygate_flutter

A new flutter plugin project for OnePay Paygate.


## Example

You can find the sdk's sample in **example** folder.

## Requirements

iOS >= 12.0, Objc or Swift
Android >= SDK 19+, Java or Kotlin

## Installation

Insert these lines to your pubspec.yaml, and then upgrade your pub. 

### From git

```ruby
onepay_paygate_flutter:
    git:
      url: {GIT_STORES_SOURCE_CODE}
```

or download the source 

### From local source
```ruby
onepay_paygate_flutter:
    path: {PATH_TO_FOLDER_STORES_SOURCE_CODE}
```

## Implement code

Open paygate.
```dart

var ACCESS_CODE_PAYGATE = "6BEB2546"; // Onepay send for merchant
var MERCHANT_PAYGATE = "TESTONEPAY"; //  Merchant register with onepay
var HASH_KEY = "6D0870CDE5F24F34F3915FB0045120DB"; // Onepay send for merchant
var URL_SCHEMES = "merchantappscheme"; // get CFBundleURLSchemes in Info.plist
var entity = OPPaymentEntity(
    amount: double.parse(_amount),
    orderInformation: "$MERCHANT_PAYGATE test",
    currency: OnepayCurrency.vnd,
    accessCode: ACCESS_CODE_PAYGATE,
    merchant: MERCHANT_PAYGATE,
    hashKey: HASH_KEY,
    urlSchemes: URL_SCHEMES);
OnePayPaygate.open(context: context, entity: entity,
  onPayResult: (OPPaymentResult result) {
      if (result.isSuccess) {
        showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Thông báo"), content: Text("Thanh toán thành công"),));
      } else {
        showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Thông báo"), content: Text(result.message ?? "Thanh toán không thành công"),));
      }
    },
  onPayFail: (error) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Lỗi"), content: Text(error.errorCase.name),));
  });
  
```

Add to AndroidManifest in your **android** folder:
```xml

    <intent-filter>
        <action android:name="android.intent.action.VIEW" />

        <category android:name="android.intent.category.BROWSABLE" />
        <category android:name="android.intent.category.DEFAULT" />
        <!--deep link open your app from website, provided by OnePAY-->
        <data android:scheme="{YOUR_MERCHANT_APP_SCHEME}" />
    </intent-filter>

    <intent-filter>
        <action android:name="android.intent.action.VIEW" />

        <category android:name="android.intent.category.BROWSABLE" />
        <category android:name="android.intent.category.DEFAULT" />
        <!--deep link open your app from bank app-->
        <data
            android:host="onepay.vn"
            android:pathPrefix="/paygate/apps/{YOUR_MERCHANT_APP_SCHEME}"
            android:scheme="https" />
    </intent-filter>
</activity>

```

Add to Info.plist in your **ios** folder:
```xml

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>{YOUR_MERCHANT_APP_SCHEME}</string>
        </array>
    </dict>
</array>
</plist>


```

Add permission in Info.plist for downloading qr code
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Allow the application to save images to the Gallery</string>

```xml 


## Authors

* **BinhNT77** - *FTEL DSC HN*
