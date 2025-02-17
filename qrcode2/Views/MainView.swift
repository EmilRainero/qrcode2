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
    
    @State private var navigationPath = NavigationPath()
    @State private var isPopupSelectFirearmVisible = false
    @State private var selectedFirearmTitle: String? = nil
    @State private var selectedFirearm: Models.Firearm? = nil
    @State private var appStateMachine = AppStateMachine(initialState: .initial)

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                Text("Home Laser Range")
                    .font(.largeTitle)
                    .padding(.vertical)
                
                Spacer().frame(height: 40)
                
                Button(action: {
                    isPopupSelectFirearmVisible = true
                }) {
                    Text("Start Session")
                        .frame(width: 200)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                
                Spacer().frame(height: 20)

                Button(action: {
                    navigationPath.append("firearms")
                }) {
                    Text("Firearms")
                        .frame(width: 200)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                
                Spacer().frame(height: 20)

                Button(action: {
                    navigationPath.append("history")
                }) {
                    Text("History")
                        .frame(width: 200)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                
                Spacer()

                
                Button(action: {
                    navigationPath.append("settings")
                }) {
                    Text("Settings")
                        .frame(width: 200)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                
                Spacer().frame(height: 20)
                
                Button(action: {
                    onLogout()
                }) {
                    Text("Logout")
                        .frame(width: 200)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                
                Spacer()
            }
            .padding()
            .navigationDestination(for: String.self) { value in
                switch value {
                case "settings":
                    SettingsView()
                case "start":
                    CameraView(navigationPath: $navigationPath, appStateMachine: $appStateMachine, firearm: $selectedFirearm)
                case "history":
                    SessionHistoryView(navigationPath: $navigationPath)
                case "firearms":
                    FirearmListView(navigationPath: $navigationPath)
                default:
                    EmptyView()
                }
            }
        }
        .sheet(isPresented: $isPopupSelectFirearmVisible) {
            ChooseFirearmView(
                selectedFirearmTitle: $selectedFirearmTitle,
                selectedFirearm: $selectedFirearm,
                isPresented: $isPopupSelectFirearmVisible
            )
        }
        .onChange(of: selectedFirearmTitle) { newSelection in
            if let selected = newSelection {
                isPopupSelectFirearmVisible = false // Dismiss the sheet *before* navigating
                navigationPath.append("start") // Navigate only ONCE
                selectedFirearmTitle = nil // Reset selectedOption to prevent multiple triggers
            }
        }
    }
}
