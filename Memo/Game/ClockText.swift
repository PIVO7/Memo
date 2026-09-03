import Foundation

/// De stopwatch in woorden: "0:07", "1:23". Altijd minuten en seconden,
/// zodat de klok op het spelscherm niet van breedte wisselt.
enum ClockText {
    static func string(seconds: Int) -> String {
        let clamped = max(seconds, 0)
        return String(format: "%d:%02d", clamped / 60, clamped % 60)
    }

    /// Voor VoiceOver en de statistieken: "1 minuut en 23 seconden".
    static func spoken(seconds: Int) -> String {
        let clamped = max(seconds, 0)
        let minutes = clamped / 60
        let rest = clamped % 60
        if minutes == 0 {
            return String(localized: "\(rest) seconden")
        }
        return String(localized: "\(minutes) minuten en \(rest) seconden")
    }
}
