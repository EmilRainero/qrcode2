//
//  SettingsView.swift
//  qrcode2
//
//  Created by Emil V Rainero on 2/10/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isRightHanded") private var isRightHanded = true
    @AppStorage("ammunitionSize") private var ammunitionSize = ".22 LR"
    @AppStorage("firearmType") private var firearmType = "Handgun"
    
    let ammunitionSizeMap: [String: [String]] = [
        "Handgun": [".22 LR", ".380 ACP", "9mm", ".40 S&W", ".45 ACP"],
        "Rifle": [".223 Rem", ".308 Win", ".30-06", ".50 BMG"],
        "Shotgun": ["12 Gauge", "20 Gauge", "10 Gauge", "28 Gauge", ".410 Bore"]
    ]
    
    var body: some View {
        Form {
            Section(header: Text("Handedness")) {
                Toggle(isOn: $isRightHanded) {
                    Text("Right Handed")
                }
            }
            
            Section() {
                Picker("Firearm Type", selection: $firearmType) {
                    Text("Handgun").tag("Handgun")
                    Text("Rifle").tag("Rifle")
                    Text("Shotgun").tag("Shotgun")
                }
                .onChange(of: firearmType) { _, newCategory in
                    // Ensure valid shot size when category changes
                    if !(ammunitionSizeMap[newCategory]?.contains(ammunitionSize) ?? false) {
                        ammunitionSize = ammunitionSizeMap[newCategory]?.first ?? ""
                    }
                }
            }
            
            Section() {
                Picker("Ammunition Type", selection: $ammunitionSize) {
                    ForEach(ammunitionSizeMap[firearmType] ?? [], id: \.self) { size in
                        Text(size).tag(size)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            // Validate initial shot size
            if !(ammunitionSizeMap[firearmType]?.contains(ammunitionSize) ?? false) {
                ammunitionSize = ammunitionSizeMap[firearmType]?.first ?? ""
            }
        }
    }
}
