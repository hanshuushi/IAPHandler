#IAPHandler
[![Platform](https://img.shields.io/cocoapods/p/IAPHandler.svg?style=flat)](https://cocoapods.org/pods/IAPHandler)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/IAPHandler.svg?style=flat)](https://cocoapods.org/pods/IAPHandler)

IAPHandler 是一款轻量级用于应用内购买的辅助框架。

```objective-c
    /// 第一次购买
    [[IAPHandler shareIAPHandlerWithProductId:@"InAppPurcharse's ID"] buyProductWithResponse:^(NSError *error) {
        if (error == nil) {
            NSLog(@"内购成功");
            } else {
            NSLog(@"内购失败，错误原因为 %@", [error localizedDescription]);
            }
    }];

    /// 恢复购买
    [[IAPHandler shareIAPHandlerWithProductId:@"InAppPurcharse's ID"]   restoreProductWithResponse:^(NSError *error) {
        if (error == nil) {
            NSLog(@"内购成功");
        } else {
            NSLog(@"恢复内购失败，错误原因为 %@", [error localizedDescription]);
        }
        }];
```

## 需要
- iOS 6.0 +

## 安装
### CocoaPods
```ruby
 pod 'IAPHandler', '~> 0.9.0'
```
