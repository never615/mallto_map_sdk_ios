//
//  ContentView.swift
//  SDK Demo
//
//  Created by Silence on 2025/2/19.
//

import SwiftUI
import MapSDK

struct ContentView: View {
    var map = MTMap(
        options: MTMapOptions.test_default_options(
            uuid: "4012",
            app_id: "999",
            app_secret: "testsecret",
            signature_version: "999"
        )
    )
    
   
    @State var start = false
    @State var ble_start = false
    @State var identifier = ""
    
    var body: some View {
            NavigationView {
                VStack {
                    Button(action: {
                        Task {
                            do {
                                let token = try await self.map.fetch_identifier()
                                self.identifier = token
                            } catch {}
                        }
                    }) { Text(identifier.isEmpty ? "获取用户登录" : "[\(self.identifier)] 已登录") }
                        .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                    
                    Button(action: {
                        self.ble_start = !self.ble_start
                        if self.ble_start {
                            self.map.startBleAdvertising()
                        } else {
                            self.map.stopBleAdvertising()
                        }
                    }) { Text(self.ble_start ? "停止广播" : "开始广播") }
                        .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                    
                    Button(action: {
                        self.start = !self.start
                        if self.start {
                            Task {
                                do {
                                    try await self.map.startBeaconScanning { beacons in
                                        print(beacons)
                                    }
                                } catch {}
                            }
                        } else {
                            self.map.stopBeaconSacnning()
                        }
                    }) { Text(self.start ? "停止扫描Beacon" : "开始扫描Beacon") }
                        .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                    
                    NavigationLink {
                        MapView(view: self.map.getMapview())
                    } label: {
                        Text("跳转地图")
                    }

                   
                }
                .padding()
            }
        }
}

struct MapView: UIViewRepresentable {
    let view: MTMapView
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
    func makeUIView(context: Context) -> some UIView {
        return view
    }
}
