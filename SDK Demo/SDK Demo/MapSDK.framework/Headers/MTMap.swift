//
//  MTMap.swift
//  
//
//  Created by Silence on 2025/2/11.
//

import Foundation
import AdSupport
import AppTrackingTransparency
import CoreLocation

enum IDFAError: Error {
    case UserRejection
    case NotDetermined
    case NotTurnIDFA
    case Unknown
}

public class MTMapOptions: NSObject {
    var uuid: String;
    var app_id: String;
    var app_secret: String;
    var signature_version: String;
    var host: String;
    var h5_url: String;
    
    static public func production_default_options(uuid: String,
                                                  app_id: String,
                                                  app_secret: String,
                                                  signature_version: String) -> MTMapOptions {
        return MTMapOptions(
            host: "https://m.mall-to.com",
            h5_url: "https://h5-test.mall-to.com/test/map/",
            uuid: uuid,
            app_id: app_id,
            app_secret: app_secret,
            signature_version: signature_version
        );
    }
    
    static public func test_default_options(uuid: String,
                                            app_id: String,
                                            app_secret: String,
                                            signature_version: String) -> MTMapOptions {
        return MTMapOptions(
            host: "https://test-easy.mall-to.com",
            h5_url: "https://h5-test.mall-to.com/test/map/",
            uuid: uuid,
            app_id: app_id,
            app_secret: app_secret,
            signature_version: signature_version
        );
    }
    
    public init(host: String,
                h5_url: String,
                uuid: String,
                app_id: String,
                app_secret: String,
                signature_version: String
    ) {
        self.h5_url = h5_url;
        self.host = host;
        self.uuid = uuid;
        self.app_id = app_id;
        self.app_secret = app_secret;
        self.signature_version = signature_version;
    }
}



public class MTMap {
    private var options: MTMapOptions;
    private var net: MTNet;
    private var beaconManager: MTBeaconManager;
    private var identifier: String;
    private var bleAdvertising: MTBleAdvertising;
    
    public var didStateChange: ((CLAuthorizationStatus) throws -> Void)?;
    
    public init(options: MTMapOptions) {
        self.options = options;
        self.net = MTNet(host: options.host,
                         uuid: options.uuid,
                         app_id: options.app_id,
                         app_secret: options.app_secret,
                         signature_version: options.signature_version)
        self.beaconManager = MTBeaconManager()
        self.bleAdvertising = MTBleAdvertising()
        self.identifier = ""
        
        self.beaconManager.status_callback = { status in
            try self.didStateChange?(status);
        }
    }
    
    ///
    ///  Fetch Identifier
    ///
    /// - Parameters:
    ///   - third_slug:            Third slug
    ///
    public func fetch_identifier(_ third_slug: String = "") async throws -> String {
        var slug: String;
        let idfa = try await getIDFA();
        if third_slug.isEmpty {
            slug = try await getSortIdentifier(device_id: idfa)
        } else {
            slug = try await getSortIdentifier(device_id: idfa, third_slug: third_slug)
        }
        self.identifier = slug
        return slug
    }
    
    ///
    /// Get a unique identifier through the device ID
    ///
    ///
    /// - Parameters:
    ///   - device_id:            `Device ID
    ///   - third_slug:            Third slug
    ///
    private func getSortIdentifier(device_id: String,  third_slug: String? = nil) async throws -> String {
        let model = try await self.net.getSortIdentifier(device_id: device_id, third_slug: third_slug)
        return model.slug
    }
    
    ///
    /// Get system idfa
    ///
    private func getIDFA() async throws -> String {
        if #available(iOS 14, *) {
            return try await withCheckedThrowingContinuation { continuation in
                ATTrackingManager.requestTrackingAuthorization { status in
                    switch status {
                    case .denied:
                        continuation.resume(throwing: IDFAError.UserRejection)
                    case .authorized:
                        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                        continuation.resume(returning: idfa)
                    case .notDetermined:
                        continuation.resume(throwing: IDFAError.NotDetermined)
                    case .restricted:
                        continuation.resume(throwing: IDFAError.UserRejection)
                    @unknown default:
                        continuation.resume(throwing: IDFAError.Unknown)
                    }
                }
            }
        } else {
            if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                return ASIdentifierManager.shared().advertisingIdentifier.uuidString
            } else {
                throw IDFAError.NotTurnIDFA
            }
        }
    }
    
    
    ///
    ///   Start Beacon Scanning
    ///
    ///   - Parameters:
    ///   - short_identifier:   use "getSortIdentifier" or "getSortIdentifierByIDFA" method
    ///
    ///
    public func startBeaconScanning(uuids: [String]? = nil, callback: @escaping ([CLBeacon]) -> Void) async throws -> Void {
        var start_uuids = uuids?.map({ uuid in
            return UUID(uuidString: uuid)!
        });
        
        if start_uuids == nil {
            start_uuids = try await self.net.getProjectBeaconUUIDS().map { uuid in
                return UUID(uuidString: uuid)!
            };
        }
        self.beaconManager.startRangeBeacons(uuids: start_uuids!) { beacons in
            // 如果扫描不到beacon，则不返回
            if (beacons.count == 0) { return }
            // 上报beacon数据到服务器
            Task {
                do {
                    let reportBeacons = beacons.map { beacon in
                        MTBeacon(
                            uuid: beacon.uuid.uuidString,
                            major: Int(truncating: beacon.major),
                            minor: Int(truncating: beacon.minor),
                            rssi: beacon.rssi,
                            accuracy: Float(beacon.accuracy)
                        )
                    }
                    try await self.net.reportBeacons(beacons: reportBeacons, identifier: self.identifier)
                    
                } catch {
                    print("上报beacon数据失败")
                }
            }
            
            // 返回数据给调用者
            callback(beacons)
            
        }
    }
    
    ///
    ///   Stop Beacon Scanning
    ///
    public func stopBeaconSacnning() {
        self.beaconManager.stopRangeBeacons();
    }
    
    ///
    ///   Get Mapview
    ///
    public func getMapview() -> MTMapView {
        let url: String
        if (!identifier.isEmpty) {
            url = "\(self.options.h5_url)?uuid=\(self.options.uuid)&type=mac&type_id=\(String(describing: identifier))"
        } else {
            url = "\(self.options.h5_url)?uuid=\(self.options.uuid)"
        }
        return MTMapView(uuid: options.uuid, url: url)
    }
    
    ///
    ///   Start Ble Advertising
    ///
    public func startBleAdvertising() {
        self.bleAdvertising.startAdvertising(short_id: self.identifier)
    }
    
    ///
    ///   Stop Ble Advertising
    ///
    public func stopBleAdvertising() {
        self.bleAdvertising.stopAdvertising();
    }
}
