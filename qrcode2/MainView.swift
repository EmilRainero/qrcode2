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
                    Text("Reports")
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
                    ReportsView(navigationPath: $navigationPath)
                }
            }
        }
        .onAppear {
            deleteAllTemporaryFiles()
            // Navigate to CameraView immediately when the view appears - DEBUGGING
//            navigationPath.append("start")
        }
    }
}

func deleteAllTemporaryFiles() {
    let fileManager = FileManager.default
    let tempDirectory = NSTemporaryDirectory()

    do {
        // Get the list of all files in the temporary directory
        let tempFiles = try fileManager.contentsOfDirectory(atPath: tempDirectory)
        
        for file in tempFiles {
            let filePath = (tempDirectory as NSString).appendingPathComponent(file)
            
            do {
                // Delete each file
                try fileManager.removeItem(atPath: filePath)
//                print("Deleted: \(filePath)")
            } catch let error {
                print("Failed to delete \(filePath): \(error)")
            }
        }
//        print("All temporary files deleted successfully.")
    } catch let error {
        print("Failed to get contents of temp directory: \(error)")
    }
}



