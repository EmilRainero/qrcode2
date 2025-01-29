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
    
    init() {
        self.time = Date()
        self.allShots = []
        self.position = Models.Vector(angle: 0, distance: 0)
        self.score = 0
    }
}

// Model for Session
class SessionUI: Identifiable {
    let id = UUID()
    var starttime: Date
    var finishtime: Date? = nil
    var shots: [ShotUI]
    var score: Int32
    
    init() {
        self.starttime = Date()
        self.finishtime = nil
        self.shots = []
        self.score = 0
    }
    
    class func toSessionUI(session: Models.Session) -> SessionUI {
        let result = SessionUI()
        result.starttime = session.starttime
        result.finishtime = session.finishtime
        result.score = session.score
        result.shots = []
        for shot in session.shots {
            let shotUI = ShotUI()
            shotUI.time = shot.time
            shotUI.position = shot.position
            shotUI.score = shot.score
            shotUI.allShots = shot.allShots
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
            let sessionItem = SessionUI.toSessionUI(session: Models.Session.fromJson(json: session.data)!)
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
                    
                    Spacer()
                }
            }
            
            // Display the list of shots
            Section(header: Text("Shots")) {
                if session.shots.isEmpty {
                    Text("No shots recorded for this session.")
                        .font(.body)
                } else {
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

struct ShotRowView: View {
    let shot: ShotUI
    let sessionStart: Double

    var body: some View {
        VStack {
            let timeDiff = shot.time.timeIntervalSince1970 - sessionStart
            let message = calculateMessage(shot: shot) // Call a function for clarity

            Text(String(format: "Time: +%.1fs  Score: %d  Angle: %d  Dist: %.1f",
                        timeDiff, shot.score, (Int(shot.position.angle) + 360) % 360, shot.position.distance))
            Text(message)
        }
    }

    // Separate function to calculate the message
    private func calculateMessage(shot: ShotUI) -> String {
        guard shot.allShots.count > 1 else { return "" } // Guard against < 2 shots

        // Safely access the first and last elements
        guard let firstShot = shot.allShots.first, let lastShot = shot.allShots.last else {
            return "Cant" // Handle potential nil values
        }

        let result = firstShot.position.vectorDifference(lastShot.position) // Use first and last
        return String(format: "A: %d  D: %.1f", Int(result.angle), result.distance)
    }
}
