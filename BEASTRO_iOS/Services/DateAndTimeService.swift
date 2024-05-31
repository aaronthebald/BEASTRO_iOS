//
//  DateAndTimeService.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/26/24.
//

import Foundation

final class DateAndTimeService {
    
    let timeFormatter = DateFormatter()
    let timeReadableInputFormatter = DateFormatter()
    let dateFormatter = DateFormatter()
    let timeReadableOutputFormatter = DateFormatter()
    let formatter = DateFormatter()
    
    enum dateError: Error {
        case failedToFormatDate
    }

    func getCurrentDayOfWeek() -> String {
        let date = Date()
        dateFormatter.dateFormat = "EEEE"
        let dayOfWeekString = dateFormatter.string(from: date)
        return dayOfWeekString
    }
    
    func formatTime(from dateString: String, getWeekDay: Bool) throws -> String {
        let inputDateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.dateFormat = inputDateFormat
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = dateFormatter.date(from: dateString) {
            let outputTimeFormat = getWeekDay ? "EEEE" : "HH:mm:ss"
            dateFormatter.dateFormat = outputTimeFormat
            var timeString = dateFormatter.string(from: date)
            if timeString == "24:00:00" ||  timeString == "23:59:59" {
                timeString = "00:00:00"
            }
            return timeString
        } else {
            print("Failed to turn \(dateString) into a string")
            throw dateError.failedToFormatDate
        }
    }
    
    func datesFromStrings(dayOfTheWeek: DateComponents, timeStrings: [String], closingTime: Bool) throws -> [Date] {
        var dates: [Date] = []
        timeFormatter.dateFormat = "HH:mm:ss"
        timeFormatter.timeZone = TimeZone.current
        
        let calendar = Calendar.current
        
        for timeString in timeStrings {
            if timeString == "24:00:00" {
                let correctedTimeString = closingTime ? "23:59:59" : "00:00:00"
                if let timeDate = timeFormatter.date(from: correctedTimeString) {
                    var dateComponents = calendar.dateComponents([.hour, .minute, .second], from: timeDate)
                    dateComponents.year = dayOfTheWeek.year
                    dateComponents.month = dayOfTheWeek.month
                    dateComponents.day = dayOfTheWeek.day
                    
                    if let combinedDate = calendar.date(from: dateComponents) {
                        dates.append(combinedDate)
                    }
                } else {
                    throw dateError.failedToFormatDate
                }
            } else {
                if let timeDate = timeFormatter.date(from: timeString) {
                    var dateComponents = calendar.dateComponents([.hour, .minute, .second], from: timeDate)
                    dateComponents.year = dayOfTheWeek.year
                    dateComponents.month = dayOfTheWeek.month
                    dateComponents.day = dayOfTheWeek.day
                    
                    if let combinedDate = calendar.date(from: dateComponents) {
                        dates.append(combinedDate)
                    }
                } else {
                    throw dateError.failedToFormatDate
                }
            }
        }
        return dates
    }
    
///      Returns the components of the next occurrence of the input day
        func nextOccurrence(ofDayOfWeek day: String) throws -> DateComponents {
            let calendar = Calendar.current
            var dateComponents = DateComponents()
            
            let currentDate = Date()
            
            let currentWeekday = calendar.component(.weekday, from: currentDate)
            
            guard let index = calendar.weekdaySymbols.firstIndex(where: { $0.caseInsensitiveCompare(day) == .orderedSame }) else {
                print("Invalid day of the week: \(day)")
                throw dateError.failedToFormatDate
            }
            
            let daysUntilNextDay = (index + 7 - currentWeekday + 1) % 7
            
            if let nextDate = calendar.date(byAdding: .day, value: daysUntilNextDay, to: currentDate) {
                dateComponents = calendar.dateComponents([.year, .month, .day], from: nextDate)
            } else {
                throw dateError.failedToFormatDate
            }
            return dateComponents
        }
    
    func makeTimeReadable(input: String) throws -> String {
        let timeReadableInputFormatter = DateFormatter()
        timeReadableInputFormatter.dateFormat = "HH:mm:ss"
        
        // Handle special case for "24:00:00"
        var adjustedInput = input
        if input == "24:00:00" {
            adjustedInput = "00:00:00"
        }
        
        if let date = timeReadableInputFormatter.date(from: adjustedInput) {
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: date)
            
            if components.minute == 0 {
                timeReadableOutputFormatter.dateFormat = "h a"
            } else {
                timeReadableOutputFormatter.dateFormat = "h:mm a"
            }
            
            timeReadableOutputFormatter.amSymbol = "AM"
            timeReadableOutputFormatter.pmSymbol = "PM"
            
            return timeReadableOutputFormatter.string(from: date)
        } else {
            throw dateError.failedToFormatDate
        }
    }
}
