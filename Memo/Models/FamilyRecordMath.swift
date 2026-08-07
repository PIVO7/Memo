import Foundation

/// Rekent een gezinsrecord uit, los van de view zodat het te testen valt.
/// Alleen profielen die al gespeeld hebben doen mee, en een record van nul
/// is nog geen record.
enum FamilyRecordMath {
    /// De recordwaarde en iedereen die hem heeft — bij een gelijke stand
    /// delen ze het record, samen een record hebben is ook leuk.
    static func record(
        in profiles: [PlayerProfile],
        value: (PlayerProfile) -> Int,
        best: ([Int]) -> Int? = { $0.max() }
    ) -> (value: Int, holders: [PlayerProfile])? {
        let contenders = profiles.filter { $0.gamesPlayed > 0 }
        guard let record = best(contenders.map(value)), record > 0 else { return nil }
        return (record, contenders.filter { value($0) == record })
    }

    /// Voor de snelste overwinning wint juist het kléinste getal: hoe minder
    /// stenen, hoe knapper. Nul betekent "nog nooit gewonnen" en telt niet.
    static func lowestPositive(_ values: [Int]) -> Int? {
        values.filter { $0 > 0 }.min()
    }
}
