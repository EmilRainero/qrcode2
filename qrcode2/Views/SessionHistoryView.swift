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
    var image: UIImage?
    
    init() {
        self.starttime = Date()
        self.finishtime = nil
        self.shots = []
        self.score = 0
        self.image = nil
    }
    
    class func toSessionUI(session: Models.Session) -> SessionUI {
        let result = SessionUI()
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
    var sessions: [SessionUI]

    init(navigationPath: Binding<NavigationPath>) {
        self._navigationPath = navigationPath

        let dataAccess = DB.DataAccess("db.sqlite3")
        self.sessions = []
        let sessions = dataAccess.getAllSessions()
        for session in sessions {
            let sessionModel = Models.Session.fromJson(json: session.data)!
            let image = sessionModel.createTargetImageWithShots(size: CGSize(width: 600, height: 600))
            let sessionItem = SessionUI.toSessionUI(session: sessionModel)
            sessionItem.image = image
            self.sessions.append(sessionItem)
        }
    }

    var body: some View {
        NavigationView { // Keep the NavigationView here
            VStack(alignment: .leading) { // Use a VStack
                if sessions.isEmpty {
                    Text("No sessions.")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top) // Add some top padding
                    Spacer() // Push content to top
                } else {
                    List(sessions) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatDateToLocalTime(date: session.starttime, format: "yyyy-MM-dd HH:mm a"))
                                    .font(.headline)

                                Text("Shots: \(session.shots.count)  Score: \(session.score)  Average: \(String(format: "%.1f", session.shotAverage()))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            } // End of VStack
            
        } // End of NavigationView
        .navigationTitle("History") // Set the title here!
        .navigationBarTitleDisplayMode(.inline)
    }
    
}

struct SessionDetailView: View {
    let session: SessionUI

    var body: some View {
        List {
            // Display session details at the top
            Section(header: Text("Session Details")) {
                VStack(alignment: .leading, spacing: 16) {
                    
                    Text(formatDateToLocalTime(date: session.starttime, format: "yyyy-MM-dd HH:mm a"))
                        .font(.largeTitle)
                        .bold()
                    Text("Shots: \(session.shots.count)  Score: \(session.score)  Average: \(String(format: "%.1f", session.shotAverage()))")
                        .font(.body)
                    
                    Text("Finish time: \(formatDateToLocalTime(date: session.finishtime!, format: "yyyy-MM-dd HH:mm a"))")
                        .font(.body)
                    
                    Text("Duration: \(computeDuration(start: session.starttime, finish: session.finishtime!))")
                        .font(.body)
                    
                    if let image = session.image {
//                        Image(uiImage: image)
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
                        ZoomableImageView(image: image) // Use a separate zoomable view


                    }
                    Spacer()
                }
            }
            
            // Display the list of shots
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
        .listStyle(InsetGroupedListStyle()) // Use a grouped list style for better readability
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ZoomableImageView: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            let imageSize = geometry.size
            let maxOffset = computeMaxOffset(imageSize: imageSize, scale: scale)
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(x: offset.width, y: offset.height)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let newScale = max(0.25, min(lastScale * value, 5.0)) // Limit zoom-in to 5x
                            scale = newScale
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1.0 { // Allow panning only if zoomed in
                                let newOffset = CGSize(
                                    width: offset.width + value.translation.width,
                                    height: offset.height + value.translation.height
                                )
                                offset = clampOffset(newOffset, maxOffset: maxOffset)
                            }
                        }
                        .onEnded { _ in }
                )
                .gesture(
                    TapGesture(count: 2)
                        .onEnded {
                            withAnimation {
                                scale = 1.0
                                offset = .zero
                            }
                        }
                )
                .frame(width: imageSize.width, height: imageSize.height)
                .clipped()
                .animation(.easeInOut(duration: 0.2), value: scale)
                .animation(.easeInOut(duration: 0.2), value: offset)
        }
        .frame(height: 300) // Adjust based on needs
    }

    /// Calculate maximum offset to keep the image within bounds
    private func computeMaxOffset(imageSize: CGSize, scale: CGFloat) -> CGSize {
        let maxX = ((imageSize.width * scale) - imageSize.width) / 2
        let maxY = ((imageSize.height * scale) - imageSize.height) / 2
        return CGSize(width: maxX, height: maxY)
    }

    /// Clamp offset to prevent excessive panning
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
