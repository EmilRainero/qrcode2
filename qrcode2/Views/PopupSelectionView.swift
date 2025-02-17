//
//  PopupSelectionView.swift
//  qrcode2
//
//  Created by Emil V Rainero on 2/16/25.
//


import SwiftUI

struct PopupSelectionView: View {
    @Binding var selectedOption: String?
    @Binding var isPresented: Bool

    let options = ["Option 1", "Option 2", "Option 3", "Option 4"]

    var body: some View {
        VStack {
            Text("Choose Firearm and Start Session")
                .font(.headline)
                .padding()

            Picker("Select an option", selection: $selectedOption) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.wheel)
            .padding()

            Spacer()

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("Start Session") {
                    selectedOption = "Option 1"
                    isPresented = false
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
    }
}
