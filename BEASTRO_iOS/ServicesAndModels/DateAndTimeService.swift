//
//  DateAndTimeService.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/26/24.
//

import Foundation

class DateAndTimeService {
    
    func dateFrom(weekday: String, time: String) -> Date? {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"  // Updated to match the time format "07:00:00"
            guard let timeDate = formatter.date(from: time) else {
                print("Invalid time format")
                return nil
            }
            
            let calendar = Calendar.current
            let weekdaySymbols = calendar.weekdaySymbols.map { $0.lowercased() }
            
            guard let weekdayIndex = weekdaySymbols.firstIndex(of: weekday.lowercased()) else {
                print("Invalid weekday")
                return nil
            }
            
            let today = Date()
            let todayWeekday = calendar.component(.weekday, from: today)
            
            var daysToAdd = (weekdayIndex + 1) - todayWeekday
            if daysToAdd < 0 {
                daysToAdd += 7
            }
            
            guard let nextWeekdayDate = calendar.date(byAdding: .day, value: daysToAdd, to: today) else {
                return nil
            }
            
            let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: timeDate)
            var finalDateComponents = calendar.dateComponents([.year, .month, .day], from: nextWeekdayDate)
            finalDateComponents.hour = timeComponents.hour
            finalDateComponents.minute = timeComponents.minute
            finalDateComponents.second = timeComponents.second
            
            return calendar.date(from: finalDateComponents)
        }
}
