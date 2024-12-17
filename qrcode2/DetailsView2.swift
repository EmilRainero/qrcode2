//
//  DetailsView2.swift
//  qrcode2
//
//  Created by Emil V Rainero on 11/14/24.
//
import SwiftUI


struct DetailsView2: View {
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack {
            Text("Start")
                .font(.largeTitle)

            Button("Go Back") {
                navigationPath.removeLast()  // Remove the last item from the path to go back
            }
        }
        .navigationTitle("Details") // Inline title on the detail screen as well
        .navigationBarTitleDisplayMode(.inline)
    }
}
