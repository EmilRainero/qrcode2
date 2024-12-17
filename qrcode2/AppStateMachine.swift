//
//  AppStateMachine.swift
//  qrcode2
//
//  Created by Emil V Rainero on 11/20/24.
//

import Foundation

// Step 1: Define the states
enum AppState {
    case initial
    case calibrating
    case calibrated
    case calibrationFailed
    case startRunningSession
    case runningSession
    case sessionEnded
}

// Step 2: Define the events/triggers
enum AppEvent {
    case startCalibration
    case endCalibration
    case calibrationFailed
    case startRunSession
    case running
    case endRunSession

}

// Step 3: Create the state machine
class AppStateMachine {
    // Current state of the machine
    private(set) var currentState: AppState
    
    // Initialization
    init(initialState: AppState) {
        self.currentState = initialState
    }
    
    // Transition logic
    func handle(event: AppEvent) {
        print("Handle event \(event)")

        switch (currentState, event) {
        case (.initial, .startCalibration):
            currentState = .calibrating
        case (.initial, .calibrationFailed):
            currentState = .calibrationFailed
        case (.calibrating, .endCalibration):
            currentState = .initial
        case (.calibrating, .calibrationFailed):
            currentState = .calibrationFailed
        case (.calibrating, .startRunSession):
            currentState = .startRunningSession
        case (.startRunningSession, .running):
            currentState = .runningSession
        case (.calibrating, .running):
            currentState = .runningSession
        case (.runningSession, .endRunSession):
            currentState = .sessionEnded
        case (.runningSession, .startCalibration):
            currentState = .calibrating
        case (.sessionEnded, .startCalibration):
            currentState = .calibrating
        case (.calibrationFailed, .startCalibration):
            currentState = .calibrating
        default:
            print("Invalid transition from \(currentState) with event \(event)")
        }
    }
}

func test() {
    // Step 4: Use the state machine
    let appStateMachine = AppStateMachine(initialState: .initial)
    print(appStateMachine.currentState)

    appStateMachine.handle(event: .startCalibration)
    print(appStateMachine.currentState)
        
    appStateMachine.handle(event: .endCalibration)
    print(appStateMachine.currentState)
    
    appStateMachine.handle(event: .startRunSession)
    print(appStateMachine.currentState)
    
    appStateMachine.handle(event: .endRunSession)
    print(appStateMachine.currentState)
}
