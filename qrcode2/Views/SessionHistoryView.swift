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
        NavigationView {
            List(sessions) { session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatDateToLocalTime(date: session.starttime, format: "yyyy-MM-dd HH:mm a"))
                            .font(.headline)

                        Text("Score: \(session.score)  Average: \(String(format: "%.1f", session.shotAverage()))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                    }
                    .padding(.vertical, 5)
                }
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
            // Display session details at the top
            Section(header: Text("Session Details")) {
                VStack(alignment: .leading, spacing: 16) {
                    
                    Text(formatDateToLocalTime(date: session.starttime, format: "yyyy-MM-dd HH:mm a"))
                        .font(.largeTitle)
                        .bold()
                    Text("Score: \(session.score)  Average: \(String(format: "%.1f", session.shotAverage()))")
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
        HStack {
            Text("Shot \(shot.time.timeIntervalSince1970 - sessionStart) \(shot.score) \(shot.position.angle) \(shot.position.distance)")
        }
    }
}
