#### 目录结构说明

Release/iphoneos - 真机framework包
Release/iphone-simulator - 模拟器framework包
SDK Demo - SDK使用例子


#### API 接口说明
##### 初始化接口
```swift
//
// 地图初始化参数选项
// 
//  @param uuid  项目UUID
//  @param app_id 项目app_id
//  @param app_secret 项目密钥
//  @param signature_version 签名版本
// 
var options = MTMapOptions.test_default_options(
            uuid: "4012",
            app_id: "999",
            app_secret: "testsecret",
            signature_version: "999"
        )
var map = MTMap(options: MTMapOptions)
```

##### 获取id接口
```swift
//
// 获取ID
// 
//  @param third_slug  第三方用户标识，可空
// 
func fetch_identifier(_ third_slug: String = "") async throws -> String
```

##### 开始扫描beacon
```swift
//
// 开始扫描beacon
// 
//  @param uuids  可自定义扫描beacon的uuid
//  @param callback 扫到beacon回调
// 
func startBeaconScanning(uuids: [String]? = nil, callback: @escaping ([CLBeacon]) -> Void) async throws -> Void
```

##### 停止扫描beacon
```swift
//
// 停止扫描beacon
// 
func stopBeaconScanning()
```


##### 获取地图Mapview
```swift
//
// 获取地图Mapview
// 
func getMapview()
```