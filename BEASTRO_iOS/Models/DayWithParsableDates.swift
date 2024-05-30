//
//  DayWithParsableDates.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/30/24.
//

import Foundation

struct DayWithParsableDates: Hashable {
    let weekday: String
    let abv: String
    let startTimes: [String]
    let endTimes: [String]
    let startTimeInDateFormat: [Date]
    let endTimeInDateFormat: [Date]
}
