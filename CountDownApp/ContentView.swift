//
//  ContentView.swift
//  CountDownApp
//
//  Created by nakamori.emiri on 2024/07/13.
//

import SwiftUI
import Combine

class TimerManager: ObservableObject {
    @Published var secondsRemaining: Int
    @Published var isRunning: Bool = false
    private var timer: AnyCancellable?
    private var endDate: Date?
    
    init(initialSeconds: Int) {
        self.secondsRemaining = initialSeconds
    }
    
    func start() {
        if !isRunning {
            if endDate == nil {
                endDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
            }
            isRunning = true
            timer = Timer.publish(every: 0.1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.updateTimer()
                }
        }
    }
    
    func stop() {
        timer?.cancel()
        timer = nil
        isRunning = false
    }
    
    func reset(to seconds: Int) {
        stop()
        secondsRemaining = seconds
        endDate = nil
    }
    
    private func updateTimer() {
        guard let endDate = endDate else { return }
        let remaining = max(0, Int(endDate.timeIntervalSinceNow))
        if remaining > 0 {
            secondsRemaining = remaining
        } else {
            secondsRemaining = 0
            stop()
        }
    }
    
    func updateTimeRemaining() {
        if let endDate = endDate {
            secondsRemaining = max(0, Int(endDate.timeIntervalSinceNow))
            if secondsRemaining == 0 {
                stop()
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var timerManager = TimerManager(initialSeconds: 60) // 1分に設定
    @State private var selectedDuration: Int = 60 // 1分をデフォルトに設定
    
    let durations = [60, 120, 180, 300, 600, 1800, 3600] // 1分, 2分, 3分, 5分, 10分, 30分, 1時間
    
    var body: some View {
        VStack {
            Text(timeString(from: timerManager.secondsRemaining))
                .font(.largeTitle)
                .padding()
            
            Button(action: {
                if timerManager.isRunning {
                    timerManager.stop()
                } else if timerManager.secondsRemaining > 0 {
                    timerManager.start()
                } else {
                    timerManager.reset(to: selectedDuration)
                }
            }) {
                Text(buttonTitle)
            }
            .padding()
            
            if !timerManager.isRunning {
                Picker("Duration", selection: $selectedDuration) {
                    ForEach(durations, id: \.self) { duration in
                        Text(timeString(from: duration)).tag(duration)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                
                Button("Set Timer") {
                    timerManager.reset(to: selectedDuration)
                }
                .padding()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // アプリがバックグラウンドに移行する時
            timerManager.stop()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // アプリがフォアグラウンドに戻る時
            timerManager.updateTimeRemaining()
            if timerManager.secondsRemaining > 0 {
                timerManager.start()
            }
        }
    }
    
    private var buttonTitle: String {
        if timerManager.isRunning {
            return "Stop"
        } else if timerManager.secondsRemaining > 0 {
            return "Start"
        } else {
            return "Reset"
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%02d:%02d", minutes, remainingSeconds)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
