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

    @State private var options: [String] = []
    @State private var tempSelection: String? // Local selection state
    @State private var defaultFirearmID: UUID? // Store default firearm ID

    func loadDefaultFirearm() {
        if let idString = UserDefaults.standard.string(forKey: "defaultFirearmID"),
           let id = UUID(uuidString: idString) {
            defaultFirearmID = id
        }
    }
    
    func loadData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let dataAccess = DB.DataAccess("db.sqlite3")
            let firearms = dataAccess.getAllFirearms()
            
            loadDefaultFirearm() // Load the default firearm ID

            var options: [String] = []
            var defaultOption: String? = nil

            for firearm in firearms {
                options.append(firearm.title)
                
                // Check if this firearm matches the defaultFirearmID
                if firearm.id == defaultFirearmID {
                    defaultOption = firearm.title
                }
            }

            self.options = options // Update state variable
            if let defaultOption = defaultOption {
                self.tempSelection = defaultOption // Set the default selection if found
            }
        }
    }

    var body: some View {
        VStack {
            Text("Choose Firearm and Start Session")
                .font(.headline)
                .padding()

            if !options.isEmpty {
                Picker("Select an option", selection: $tempSelection) {
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.wheel)
                .padding()
            } else {
                ProgressView()
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    isPresented = false // Close modal without saving selection
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("Start Session") {
                    if let tempSelection = tempSelection {
                        selectedOption = tempSelection // Save selected option
                        isPresented = false // Close modal
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(tempSelection == nil || options.isEmpty) // Disable if nothing is selected
            }
            .padding()
        }
        .onAppear {
            loadData()
        }
    }
}
