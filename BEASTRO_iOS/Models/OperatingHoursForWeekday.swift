//
//  OperatingHoursForWeekday.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/30/24.
//

import Foundation

struct OperatingHoursForWeekDay: Hashable {
    let dayOfWeek: String
    let openingTimes: [String]
    let closingTimes: [String]
}
