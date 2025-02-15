//
//  Firearm.swift
//  qrcode2
//
//  Created by Emil V Rainero on 2/15/25.
//
// Firearm.swift
import SwiftUI

struct Firearm: Identifiable, Codable {
    let id = UUID()
    let title: String
    let type: String
    let caliber: String
}

struct FirearmListView: View {
    @State private var firearms: [Firearm] = [] // Start with an empty list
    @State private var isAddingFirearm: Bool = false // Control the sheet presentation

    var body: some View {
        NavigationView {
            List {
                ForEach(firearms) { firearm in
                    Text("\(firearm.title) (\(firearm.type): \(firearm.caliber))")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onDelete(perform: deleteFirearm)
            }
            .navigationTitle("Firearms")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddingFirearm = true }) { // Show Add view
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                initializeFirearms() // Initialize the list when the view appears
            }
            .sheet(isPresented: $isAddingFirearm) { // Present the AddFirearmView when isAddingFirearm is true
                AddFirearmView(firearms: $firearms, isPresented: $isAddingFirearm, onFirearmAdded: addFirearm) // Pass the callback function
            }
        }
    }

    func initializeFirearms() {
        firearms = [
            Firearm(title: "Glock 19", type: "Handgun", caliber: "9mm"),
            Firearm(title: "Colt M4", type: "Rifle", caliber: ".223 Rem"),
            Firearm(title: "Remington 870", type: "Shotgun", caliber: "12 Gauge")
        ]
        sortFirearms()
    }

    func deleteFirearm(at offsets: IndexSet) {
        firearms.remove(atOffsets: offsets)
        print("Deleted firearm \(offsets)")
    }

    func addFirearm(_ newFirearm: Firearm) {
        firearms.append(newFirearm) // Add the new firearm to the list
        print("Added firearm: \(newFirearm.title)") // You can also perform additional actions here
        sortFirearms()
    }
    
    func sortFirearms() {
        firearms.sort { $0.title < $1.title } // Sort in ascending order by title
    }
}

struct AddFirearmView: View {
    @Binding var firearms: [Firearm]
    @Binding var isPresented: Bool
    @State private var firearmTitle = ""
    @State private var selectedFirearmType = "Handgun"
    @State private var selectedCaliber = ""
    @State private var calibers: [String] = []

    let categories = ["Handgun", "Rifle", "Shotgun"]
    let handgunCalibers = [".22 LR", ".380 ACP", "9mm", ".40 S&W", ".45 ACP"]
    let rifleCalibers = [".223 Rem", ".308 Win", ".30-06", ".50 BMG"]
    let shotgunCalibers = ["12 Gauge", "20 Gauge", "10 Gauge", "28 Gauge", ".410 Bore"]

    // Callback function passed from FirearmListView
    var onFirearmAdded: (Firearm) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $firearmTitle)
                }

                Section {
                    Picker("Type", selection: $selectedFirearmType) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .onChange(of: selectedFirearmType) { _, newValue in
                        updateModels(for: newValue)
                    }

                    Picker("Caliber", selection: $selectedCaliber) {
                        ForEach(calibers, id: \.self) { caliber in
                            Text(caliber).tag(caliber)
                        }
                    }
                    .disabled(calibers.isEmpty)
                }
            }
            .navigationTitle("Add Firearm")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if !selectedCaliber.isEmpty && !firearmTitle.isEmpty {
                            let newFirearm = Firearm(title: firearmTitle, type: selectedFirearmType, caliber: selectedCaliber)
                            onFirearmAdded(newFirearm) // Call the callback when a new firearm is added
                            isPresented = false
                        }
                    }
                    .disabled(selectedCaliber.isEmpty || firearmTitle.isEmpty)
                }
            }
            .onAppear {
                updateModels(for: selectedFirearmType)
            }
        }
    }

    func updateModels(for category: String) {
        switch category {
        case "Handgun": calibers = handgunCalibers
        case "Rifle": calibers = rifleCalibers
        case "Shotgun": calibers = shotgunCalibers
        default: calibers = []
        }

        if !calibers.isEmpty {
            selectedCaliber = calibers.first!
        } else {
            selectedCaliber = ""
        }
    }
}
