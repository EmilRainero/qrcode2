//
//  SessionHistory.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/25/25.
//

import SwiftUI

class ShotUI: Identifiable {
    let id = UUID()
    var time: Date
    var allShots: [Models.TimeVector] = []
    var position: Models.Vector
    var score: Int32
    var number: Int32
    
    init() {
        self.time = Date()
        self.allShots = []
        self.position = Models.Vector(angle: 0, distance: 0)
        self.score = 0
        self.number = 0
    }
}

// Model for Session
class SessionUI: Identifiable {
    let id = UUID()
    var starttime: Date
    var finishtime: Date? = nil
    var shots: [ShotUI]
    var score: Int32
    var session_id: String
    var session: Models.Session?
    
    init() {
        self.starttime = Date()
        self.finishtime = nil
        self.shots = []
        self.score = 0
        self.session_id = ""
        self.session = nil
    }
    
    class func toSessionUI(session: Models.Session) -> SessionUI {
        let result = SessionUI()
        result.session_id = session.id
        result.session = session
        result.starttime = session.starttime
        result.finishtime = session.finishtime
        result.score = session.score
        result.shots = []
        for (index, shot) in session.shots.enumerated() {
            let shotUI = ShotUI()
            shotUI.time = shot.time
            shotUI.position = shot.position
            shotUI.score = shot.score
            shotUI.allShots = shot.allShots
            shotUI.number = Int32(index) + 1
            result.shots.append(shotUI)
        }
        return result
    }
    
    func shotAverage() -> Double {
        guard !shots.isEmpty else { return 0.0 }
        
        let average = Double(self.score) / Double(self.shots.count)
        return average
    }
}

struct SessionHistoryView: View {
    @Binding var navigationPath: NavigationPath
    @State var sessions: [SessionUI] = []
    @Environment(\.editMode) var editMode

    init(navigationPath: Binding<NavigationPath>) {
        self._navigationPath = navigationPath
        loadSessions()
    }

    func loadSessions() {
        let dataAccess = DB.DataAccess("db.sqlite3") // Make sure DB.DataAccess is available
        let dbSessions = dataAccess.getAllSessions()
        sessions = dbSessions.compactMap { dbSession in
            guard let sessionModel = Models.Session.fromJson(json: dbSession.data) else { return nil }
            let sessionUI = SessionUI.toSessionUI(session: sessionModel)
            return sessionUI
        }
    }

    func deleteSessions(at offsets: IndexSet) {
        let dataAccess = DB.DataAccess("db.sqlite3") // Make sure DB.DataAccess is available

        for index in offsets {
            let sessionToDelete = sessions[index]
            let ok = dataAccess.deleteSession(id: sessionToDelete.session_id)
            if !ok {
                print("error deleting session")
            }
        }
        sessions.remove(atOffsets: offsets)
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                if sessions.isEmpty {
                    Text("No sessions.")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top)
                    Spacer()
                } else {
                    List {
                        ForEach(sessions) { session in
                            NavigationLink(destination: SessionDetailView(session: session)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(formatDateToLocalTime(date: session.starttime, format: "yyyy-MM-dd HH:mm a"))
                                        .font(.headline)

                                    Text("Shots: \(session.shots.count)  Score: \(session.score)  Average: \(String(format: "%.1f", session.shotAverage()))")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 5)
                            }
                        }
                        .onDelete(perform: deleteSessions)
                    }
                }
            }
            .toolbar {
                EditButton()
            }
            .task {
                loadSessions()
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SessionDetailView: View {
    let session: SessionUI

    var body: some View {
        List {
            Section(header: Text("")) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(formatDateToLocalTime(date: session.starttime, format: "yyyy-MM-dd HH:mm a"))
                        .font(.largeTitle)
                        .bold()
                    Text("Shots: \(session.shots.count)  Score: \(session.score)  Average: \(String(format: "%.1f", session.shotAverage()))")
                        .font(.body)

                    if let finishTime = session.finishtime { // Handle optional finishtime
                        Text("Finish time: \(formatDateToLocalTime(date: finishTime, format: "yyyy-MM-dd HH:mm a"))")
                            .font(.body)

                        Text("Duration: \(computeDuration(start: session.starttime, finish: finishTime))")
                            .font(.body)
                    }

                    let newImage = session.session!.createTargetImageWithShots(size: CGSize(width: 600, height: 600))
                    if newImage != nil {
                        ZoomableImageView(image: newImage!)
                            .frame(maxWidth: .infinity, maxHeight: 300) // Set max height
                            .clipped()
                    } else {
                        Text("No Image Available") // Placeholder for when image is nil
                            .frame(maxWidth: .infinity, maxHeight: 300)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8) // Add a rounded border
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }
                }
                .padding(.vertical, 8) // Add some padding around the details
            }

            Section(header: Text("Shots")) {
                if session.shots.isEmpty {
                    Text("No shots recorded for this session.")
                        .font(.body)
                } else {
                    HStack {
                        Text("Shot").bold().frame(width: 40, alignment: .leading)
                        Text("Score").bold().frame(width: 80, alignment: .center)
                        Text("Time").bold().frame(width: 100, alignment: .leading)
                        Text("Drift").bold()
                    }
                    ForEach(session.shots) { shot in
                        ShotRowView(shot: shot, sessionStart: session.starttime.timeIntervalSince1970)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ZoomableImageView: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            let imageSize = geometry.size
            let maxOffset = computeMaxOffset(imageSize: imageSize, scale: scale)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let newScale = max(1.0, min(lastScale * value, 5.0))
                            scale = newScale
                        }
                        .onEnded { _ in
                            withAnimation {
                                lastScale = scale
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1.0 {
                                let translation = value.translation
                                let newOffset = CGSize(
                                    width: lastOffset.width + translation.width,
                                    height: lastOffset.height + translation.height
                                )
                                offset = clampOffset(newOffset, maxOffset: maxOffset)
                            }
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .gesture(
                    TapGesture(count: 2)
                        .onEnded {
                            withAnimation {
                                if scale == 1.0 {
                                    scale = 2.0
                                } else {
                                    scale = 1.0
                                }
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                )
                .frame(width: imageSize.width, height: imageSize.height)
                .clipped()
                .overlay(
//                    RoundedRectangle(cornerRadius: 10) // Adjust corner radius as needed
                    Rectangle()
                        .stroke(Color.gray, lineWidth: 2) // Border color and width
                )
                .highPriorityGesture(DragGesture())  // Prevents List from scrolling
        }
        .frame(height: 300)
    }

    private func computeMaxOffset(imageSize: CGSize, scale: CGFloat) -> CGSize {
        let maxX = ((imageSize.width * scale) - imageSize.width) / 2
        let maxY = ((imageSize.height * scale) - imageSize.height) / 2
        return CGSize(width: maxX, height: maxY)
    }

    private func clampOffset(_ offset: CGSize, maxOffset: CGSize) -> CGSize {
        return CGSize(
            width: min(max(offset.width, -maxOffset.width), maxOffset.width),
            height: min(max(offset.height, -maxOffset.height), maxOffset.height)
        )
    }
}



struct ShotRowView: View {
    let shot: ShotUI
    let sessionStart: Double

    var body: some View {
        VStack {
            let timeDiff = shot.time.timeIntervalSince1970 - sessionStart
            let message = calculateMessage(shot: shot) // Call a function for clarity

            HStack {
                Text("\(shot.number)")
                    .frame(width: 40, alignment: .leading)
                Text("\(shot.score)")
                    .frame(width: 80, alignment: .center)
                Text(String(format: "+%.1fs", timeDiff))
                    .frame(width: 100, alignment: .leading)
                Text(message)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .listRowInsets(EdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 2))
        }
    }

    // Separate function to calculate the message
    private func calculateMessage(shot: ShotUI) -> String {
        guard shot.allShots.count > 1 else { return "-" } // Guard against < 2 shots

        // Safely access the first and last elements
        guard let firstShot = shot.allShots.first, let lastShot = shot.allShots.last else {
            return "Cant" // Handle potential nil values
        }

        let result = firstShot.position.vectorDifference(lastShot.position) // Use first and last
        if result.distance < 0.2 {
            return "NO DRIFT"
        }
        let angle = result.angle - 90.0
        if isAngleNear(angle: angle, near: 180.0, maxDifference: 22.5) {
            return "W DRIFT"
        }
        if isAngleNear(angle: angle, near: 0.0, maxDifference: 22.5) {
            return "E DRIFT"
        }
        if isAngleNear(angle: angle, near: 90.0, maxDifference: 22.5) {
            return "N DRIFT"
        }
        if isAngleNear(angle: angle, near: 270.0, maxDifference: 22.5) {
            return "S DRIFT"
        }
        if isAngleNear(angle: angle, near: 45.0, maxDifference: 22.5) {
            return "NE DRIFT"
        }
        if isAngleNear(angle: angle, near: 135.0, maxDifference: 22.5) {
            return "NW DRIFT"
        }
        if isAngleNear(angle: angle, near: 225.0, maxDifference: 22.5) {
            return "SW DRIFT"
        }
        if isAngleNear(angle: angle, near: 315.0, maxDifference: 22.5) {
            return "SE DRIFT"
        }
        
        return String(format: "A: %d  D: %.1f", Int(result.angle), result.distance)
    }
}

func isAngleNear(angle: Double, near: Double, maxDifference: Double) -> Bool {
    // Normalize angles to be within 0 - 360 degrees
    var angleNormalized = angle.truncatingRemainder(dividingBy: 360.0)
    if angleNormalized < 0 {
        angleNormalized += 360.0
    }

    var nearNormalized = near.truncatingRemainder(dividingBy: 360.0)
    if nearNormalized < 0 {
        nearNormalized += 360.0
    }

    // Calculate the absolute difference between the angles
    var difference = abs(angleNormalized - nearNormalized)
    
    // Adjust the difference to account for the wrap-around of angles (i.e., near 360° and 0°)
    if difference > 180.0 {
        difference = 360.0 - difference
    }

    // Check if the difference is within the max allowed difference
    return difference <= maxDifference
}
