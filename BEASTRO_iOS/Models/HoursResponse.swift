//
//  HoursResponse.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/26/24.
//

import Foundation
struct HoursResponse: Codable {
    let locationName: String
    let hours: [Hour]

    enum CodingKeys: String, CodingKey {
        case locationName = "location_name"
        case hours
    }
}

struct Hour: Codable, Identifiable {
    let dayOfWeek, startLocalTime, endLocalTime: String
    let id: String = UUID().uuidString
    enum CodingKeys: String, CodingKey {
        case dayOfWeek = "day_of_week"
        case startLocalTime = "start_local_time"
        case endLocalTime = "end_local_time"
    }
}
