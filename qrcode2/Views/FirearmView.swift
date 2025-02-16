//
//  Firearm.swift
//  qrcode2
//
//  Created by Emil V Rainero on 2/15/25.
//
// Firearm.swift
import SwiftUI

struct FirearmListView: View {
    @Binding var navigationPath: NavigationPath

    @State private var firearms: [Models.Firearm] = []
    @State private var isAddingFirearm: Bool = false
    @State private var selectedFirearm: Models.Firearm?
    @State private var defaultFirearmID: UUID? // Store default firearm ID

    init(navigationPath: Binding<NavigationPath>) {
        self._navigationPath = navigationPath
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(firearms) { firearm in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(firearm.title)")
                                .font(defaultFirearmID == firearm.id ? .title : .title) // Highlight default
                                .foregroundColor(defaultFirearmID == firearm.id ? .blue : .primary)
                            Text("    \(firearm.caliber) \(firearm.type)")
                                .font(defaultFirearmID == firearm.id ? .headline : .body) // Highlight default
                                .foregroundColor(defaultFirearmID == firearm.id ? .blue : .primary)
                        }
                        Spacer()
                        Button(action: { setDefaultFirearm(firearm) }) {
                            Image(systemName: defaultFirearmID == firearm.id ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                        }
                        .buttonStyle(BorderlessButtonStyle())

                        Button(action: { selectedFirearm = firearm }) {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                .onDelete(perform: deleteFirearm)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddingFirearm = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                initializeFirearms()
                loadDefaultFirearm()
            }
            .sheet(isPresented: $isAddingFirearm) {
                AddEditFirearmView(isPresented: $isAddingFirearm, onSave: addFirearm)
            }
            .sheet(item: $selectedFirearm) { firearm in
                AddEditFirearmView(existingFirearm: firearm, isPresented: Binding(
                    get: { selectedFirearm != nil },
                    set: { if !$0 { selectedFirearm = nil } }
                ), onSave: editFirearm)
            }
        }
        .navigationTitle("Firearms")
    }

    func initializeFirearms() {
        let dataAccess = DB.DataAccess("db.sqlite3")
        let firearms = dataAccess.getAllFirearms()
        self.firearms = []
        for firearm in firearms {
//            print(firearm)
            self.firearms.append(Models.Firearm(
                id: firearm.id,
                title: firearm.title,
                type: firearm.type,
                caliber: firearm.caliber
            ))
        }

        sortFirearms()
    }

    func deleteFirearm(at offsets: IndexSet) {
        let firearm = firearms[offsets.first!]
        let dataAccess = DB.DataAccess("db.sqlite3")
        dataAccess.deleteFirearm(id: firearm.id.uuidString)
        
        firearms.remove(atOffsets: offsets)
        saveDefaultFirearm() // Update default if removed
    }

    func addFirearm(_ newFirearm: Models.Firearm) {
        let dataAccess = DB.DataAccess("db.sqlite3")
        dataAccess.insertFirearm(firearm: DB.Firearm(
            id: newFirearm.id,
            title: newFirearm.title,
            type: newFirearm.type,
            caliber: newFirearm.caliber
        ))
        firearms.append(newFirearm)
        sortFirearms()
    }

    func editFirearm(_ updatedFirearm: Models.Firearm) {
        if let index = firearms.firstIndex(where: { $0.id == updatedFirearm.id }) {
            let dataAccess = DB.DataAccess("db.sqlite3")
            dataAccess.updateFirearm(firearm: DB.Firearm(
                id: updatedFirearm.id,
                title: updatedFirearm.title,
                type: updatedFirearm.type,
                caliber: updatedFirearm.caliber
            ))
            
            firearms[index] = updatedFirearm
            sortFirearms()
        }
    }

    func sortFirearms() {
        firearms.sort { $0.title < $1.title }
    }

    // MARK: - Default Firearm Functions
    func setDefaultFirearm(_ firearm: Models.Firearm) {
        defaultFirearmID = firearm.id
        saveDefaultFirearm()
    }

    func saveDefaultFirearm() {
        UserDefaults.standard.set(defaultFirearmID?.uuidString, forKey: "defaultFirearmID")
    }

    func loadDefaultFirearm() {
        if let idString = UserDefaults.standard.string(forKey: "defaultFirearmID"),
           let id = UUID(uuidString: idString) {
            defaultFirearmID = id
        }
    }
}

struct AddEditFirearmView: View {
    var existingFirearm: Models.Firearm? = nil
    @Binding var isPresented: Bool
    var onSave: (Models.Firearm) -> Void

    @State private var firearmTitle: String = ""
    @State private var selectedFirearmType: String = "Handgun"
    @State private var selectedCaliber: String = ""
    @State private var calibers: [String] = []

    let categories = ["Handgun", "Rifle", "Shotgun"]
    let handgunCalibers = ["9mm", ".380 ACP", ".40 S&W", ".45 ACP Auto", "10mm Auto", "357 Magnum", "357 SIG", "38 Special", "44 Remington Magnum", "45 Colt"]
    let rifleCalibers = ["223 Remington", "5.56 NATO", "5.7X28mm Rifle", "6.8x51mm", "7.62x51mm NATO",  "308 Winchester", ".30-06", ".50 BMG"]
    let shotgunCalibers = ["410 Gauge", "12 Gauge", "16 Gauge", "20 Gauge", "24 Gauge", "10 Gauge", "28 Gauge"]

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
                        updateCalibers(for: newValue)
                    }

                    Picker("Caliber", selection: $selectedCaliber) {
                        ForEach(calibers, id: \.self) { caliber in
                            Text(caliber).tag(caliber)
                        }
                    }
                    .disabled(calibers.isEmpty)
                }
            }
            .navigationTitle(existingFirearm == nil ? "Add Firearm" : "Edit Firearm")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(existingFirearm == nil ? "Add" : "Save") {
                        let newFirearm = Models.Firearm(
                            id: existingFirearm?.id ?? UUID(),
                            title: firearmTitle,
                            type: selectedFirearmType,
                            caliber: selectedCaliber
                        )
                        onSave(newFirearm)
                        isPresented = false
                    }
                    .disabled(firearmTitle.isEmpty || selectedCaliber.isEmpty)
                }
            }
            .onAppear {
                if let firearm = existingFirearm {
                    firearmTitle = firearm.title
                    selectedFirearmType = firearm.type
                    updateCalibers(for: firearm.type)
                    selectedCaliber = firearm.caliber
                } else {
                    updateCalibers(for: selectedFirearmType)
                }
            }
        }
    }

    func updateCalibers(for category: String) {
        switch category {
        case "Handgun": calibers = handgunCalibers
        case "Rifle": calibers = rifleCalibers
        case "Shotgun": calibers = shotgunCalibers
        default: calibers = []
        }
        if calibers.isEmpty {
            selectedCaliber = ""
        } else if !calibers.contains(selectedCaliber) {
            selectedCaliber = calibers.first!
        }
    }
}
