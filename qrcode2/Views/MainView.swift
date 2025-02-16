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

    let messageSender = MessageSender(dbPath: "messages.db", url: "http://192.168.5.6:5001/updates") 

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                Text("Home Laser Range")
                    .font(.largeTitle)
                    .padding(.vertical)
                
                Spacer().frame(height: 40)
                
                Button(action: {
                        navigationPath.append("settings")
                }) {
                    Text("Settings")
                        .frame(width: 200)
                        .padding(.vertical, 10) // Adds vertical padding around the text
                        .padding(.horizontal, 20) // Adds horizontal padding for a wider button
                        .background(Color.blue) // Background color for the button
                        .foregroundColor(.white) // Text color for the button
                        .cornerRadius(25)
                }
                
                Spacer().frame(height: 20)

                Button(action: {
                        navigationPath.append("firearms")
                }) {
                    Text("Firearms")
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
                if value == "settings" {
                    SettingsView()
                }
                if value == "start" {
                    CameraView(navigationPath: $navigationPath, appStateMachine: $appStateMachine)
                }
                if value == "reports" {
                    SessionHistoryView(navigationPath: $navigationPath)
                }
                if value == "firearms" {
                    FirearmListView(navigationPath: $navigationPath)
                }
               

            }
        }
        .onAppear {
            deleteAllTemporaryFiles()
            testDB()
//            testPost()
//            testMessageSender(messageSender: messageSender)
            // Navigate to CameraView immediately when the view appears - DEBUGGING
//            navigationPath.append("start")
        }
    }
    
}
