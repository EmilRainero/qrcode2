//
//  qrcode2App.swift
//  qrcode2
//
//  Created by Emil V Rainero on 11/11/24.
//

import SwiftUI


@main
struct qrcode2App: App {

    var body: some Scene {
        WindowGroup {
//            LoginView()
            FirearmListView()
        }
    }
    
    init() {
        LoggerManager.setup()
    }
}
