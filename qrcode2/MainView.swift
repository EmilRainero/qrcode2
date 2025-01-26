//
//  ViewsExample.swift
//  qrcode2
//
//  Created by Emil V Rainero on 11/14/24.
//

import SwiftUI
import Foundation


struct MainView: View {
    let onLogout: () -> Void
    
    @State private var navigationPath = NavigationPath()  // Define a navigation path
    @State public var appStateMachine = AppStateMachine(initialState: .initial)

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                Text("Home Laser Range")
                    .font(.largeTitle)
                    .padding(.vertical)
                
                Spacer().frame(height: 40)
                
                Button(action: {
                        navigationPath.append("calibrate")
                }) {
                    Text("Calibrate")
                        .frame(width: 200)
                        .padding(.vertical, 10) // Adds vertical padding around the text
                        .padding(.horizontal, 20) // Adds horizontal padding for a wider button
                        .background(Color.blue) // Background color for the button
                        .foregroundColor(.white) // Text color for the button
                        .cornerRadius(25)
                }
                
                Spacer().frame(height: 20)

                Button(action: {
                        navigationPath.append("start")
                }) {
                    Text("Session")
                        .frame(width: 200)
                        .padding(.vertical, 10) // Adds vertical padding around the text
                        .padding(.horizontal, 20) // Adds horizontal padding for a wider button
                        .background(Color.blue) // Background color for the button
                        .foregroundColor(.white) // Text color for the button
                        .cornerRadius(25)
                }
                
                Spacer().frame(height: 20)

                Button(action: {
                        navigationPath.append("reports")
                }) {
                    Text("History")
                        .frame(width: 200)
                        .padding(.vertical, 10) // Adds vertical padding around the text
                        .padding(.horizontal, 20) // Adds horizontal padding for a wider button
                        .background(Color.blue) // Background color for the button
                        .foregroundColor(.white) // Text color for the button
                        .cornerRadius(25)
                }
                
                Spacer().frame(height: 20)

                Button(action: {
                    onLogout()
                }) {
                    Text("Logout")
                        .frame(width: 200)
                        .padding(.vertical, 10) // Adds vertical padding around the text
                        .padding(.horizontal, 20) // Adds horizontal padding for a wider button
                        .background(Color.red) // Background color for the button
                        .foregroundColor(.white) // Text color for the button
                        .cornerRadius(25)
                }
                
                Spacer()
            }
            .padding()
            
            .navigationDestination(for: String.self) { value in
                if value == "calibrate" {
                    IContentView()
                }
                if value == "start" {
                    CameraView(navigationPath: $navigationPath, appStateMachine: $appStateMachine)
                }
                if value == "reports" {
//                    ReportsView(navigationPath: $navigationPath)
                    SessionHistoryView(navigationPath: $navigationPath)
                }
            }
        }
        .onAppear {
            deleteAllTemporaryFiles()
            testDB()
            
            // Navigate to CameraView immediately when the view appears - DEBUGGING
//            navigationPath.append("start")
        }
    }
    
}
//
//func displayNumber(on view: UIView, number: Int) {
//    // Create the label
//    let label = UILabel()
//    label.text = "\(number)"
//    label.font = UIFont.systemFont(ofSize: 100, weight: .bold) // Large font
//    label.textColor = .black
//    label.textAlignment = .center
//    label.backgroundColor = UIColor.white.withAlphaComponent(0.8)
//    label.layer.cornerRadius = 10
//    label.layer.masksToBounds = true
//
//    // Set the size and position of the label
//    label.translatesAutoresizingMaskIntoConstraints = false
//    view.addSubview(label)
//    NSLayoutConstraint.activate([
//        label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//        label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//        label.widthAnchor.constraint(equalToConstant: 200),
//        label.heightAnchor.constraint(equalToConstant: 150)
//    ])
//
//    // Animate the label to fade out after 1 second
//    UIView.animate(withDuration: 0.5, delay: 1, options: [], animations: {
//        label.alpha = 0
//    }) { _ in
//        // Remove the label after the animation
//        label.removeFromSuperview()
//    }
//}



