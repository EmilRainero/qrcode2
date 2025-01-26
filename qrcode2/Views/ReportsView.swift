//
//  ReportsView.swift
//  qrcode2
//
//  Created by Emil V Rainero on 11/14/24.
//
import SwiftUI


struct ReportsView: View {
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack {
            Spacer().frame(height: 40)

            Text("Coming soon")
//
//            Button("Go Back") {
//                navigationPath.removeLast()  // Remove the last item from the path to go back
//            }
        }
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
        Spacer()
    }
}
