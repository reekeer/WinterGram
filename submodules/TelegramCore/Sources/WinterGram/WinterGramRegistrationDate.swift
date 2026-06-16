import Foundation

// Estimates the approximate registration date of a Telegram account from its user ID.
// Telegram user IDs are allocated roughly monotonically over time, so a piecewise-linear
// interpolation between known (id, date) anchor points yields a usable estimate. This is an
// approximation only — it is never exact and is meant for display with an "≈" prefix.
public func winterGramEstimatedRegistrationDate(userId: Int64) -> Date? {
    guard userId > 0 else {
        return nil
    }

    // Anchor points: (user id, unix timestamp). Sourced from widely-used community datasets
    // mapping account id ranges to registration months.
    let anchors: [(id: Double, timestamp: Double)] = [
        (1_000_000, 1_383_264_000),     // ~Nov 2013
        (10_000_000, 1_388_448_000),    // ~Jan 2014
        (50_000_000, 1_404_086_400),    // ~Jul 2014
        (100_000_000, 1_414_972_800),   // ~Nov 2014
        (150_000_000, 1_426_723_200),   // ~Mar 2015
        (200_000_000, 1_437_523_200),   // ~Jul 2015
        (300_000_000, 1_460_073_600),   // ~Apr 2016
        (400_000_000, 1_483_228_800),   // ~Jan 2017
        (500_000_000, 1_508_716_800),   // ~Oct 2017
        (700_000_000, 1_534_809_600),   // ~Aug 2018
        (1_000_000_000, 1_561_939_200), // ~Jul 2019
        (1_300_000_000, 1_585_699_200), // ~Apr 2020
        (1_700_000_000, 1_609_459_200), // ~Jan 2021
        (2_000_000_000, 1_630_454_400), // ~Sep 2021
        (3_000_000_000, 1_657_756_800), // ~Jul 2022
        (4_000_000_000, 1_682_899_200), // ~May 2023
        (5_000_000_000, 1_704_067_200), // ~Jan 2024
        (6_000_000_000, 1_722_470_400), // ~Aug 2024
        (7_500_000_000, 1_743_465_600)  // ~Apr 2025
    ]

    let value = Double(userId)
    if value <= anchors[0].id {
        return Date(timeIntervalSince1970: anchors[0].timestamp)
    }
    if value >= anchors[anchors.count - 1].id {
        return Date(timeIntervalSince1970: anchors[anchors.count - 1].timestamp)
    }
    for i in 0 ..< (anchors.count - 1) {
        let lower = anchors[i]
        let upper = anchors[i + 1]
        if value >= lower.id && value <= upper.id {
            let fraction = (value - lower.id) / (upper.id - lower.id)
            let timestamp = lower.timestamp + fraction * (upper.timestamp - lower.timestamp)
            return Date(timeIntervalSince1970: timestamp)
        }
    }
    return nil
}
