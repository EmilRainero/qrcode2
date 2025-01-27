//
//  SessionHistory.swift
//  qrcode2
//
//  Created by Emil V Rainero on 1/25/25.
//

import SwiftUI

// Model for Session
struct SessionItem: Identifiable {
    let id = UUID()
    let session: DB.Session
}

// Main ContentView
struct SessionHistoryView: View {
    @Binding var navigationPath: NavigationPath
    var sessions: [SessionItem]

    init(navigationPath: Binding<NavigationPath>) {
        self._navigationPath = navigationPath

        let dataAccess = DB.DataAccess("db.sqlite3")
        self.sessions = []
        let sessions = dataAccess.getAllSessions()
        for session in sessions {
            let sessionItem = SessionItem(
                session: session
//                title: formatDateToLocalTime(date: session.starttime,
//                                             format: "yyyy-MM-dd HH:mm"),
//                description: "Score: 32  Average: 8.2"
            )
            self.sessions.append(sessionItem)
        }
//        self.sessions = [
//            SessionItem(title: "SwiftUI Basics", description: "Learn the basics of SwiftUI."),
//            SessionItem(title: "Advanced SwiftUI", description: "Explore advanced concepts in SwiftUI."),
//            SessionItem(title: "Combine Framework", description: "Introduction to the Combine framework."),
//            SessionItem(title: "Core Data", description: "Managing data persistence with Core Data.")
//        ]
        
        // Additional initialization logic (if needed)
        print("SessionHistoryView initialized with \(sessions.count) sessions.")
    }

    var body: some View {
        NavigationView {
            List(sessions) { session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatDateToLocalTime(date: session.session.starttime, format: "yyyy-MM-dd HH:mm"))
                            .font(.headline)

                        Text("Score: 32  Average: 8.2") // Replace with actual session details if needed
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

// Session Detail View
struct SessionDetailView: View {
    let session: SessionItem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(formatDateToLocalTime(date: session.session.starttime, format: "yyyy-MM-dd HH:mm"))
                .font(.largeTitle)
                .bold()

//            Text(session.session.name)
//                .font(.body)
//                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
