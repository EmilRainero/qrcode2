//
//  SettingsView.swift
//  qrcode2
//
//  Created by Emil V Rainero on 2/10/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isRightHanded") private var isRightHanded = true
    
    var body: some View {
        Form {
            Section(header: Text("Handedness")) {
                Toggle(isOn: $isRightHanded) {
                    Text("Right Handed")
                }
            }
            
        }
        .navigationTitle("Settings")
    }
}
