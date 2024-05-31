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
        dateFormatter.dateFormat = "EEEE" // "EEEE" gives the full name of the day
        let dayOfWeekString = dateFormatter.string(from: date)
        return dayOfWeekString
    }
    
    func formatTime(from dateString: String, getWeekDay: Bool) throws -> String {
        // Define the input date format including the timezone offset
        let inputDateFormat = "yyyy-MM-dd HH:mm:ss Z"
        // Create a DateFormatter for parsing the input date string
        dateFormatter.dateFormat = inputDateFormat
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Parse the date string into a Date object
        if let date = dateFormatter.date(from: dateString) {
            // Define the output time format
            let outputTimeFormat = getWeekDay ? "EEEE" : "HH:mm:ss"
            dateFormatter.dateFormat = outputTimeFormat
            // Format the Date object into the desired time string
            var timeString = dateFormatter.string(from: date)
            if timeString == "24:00:00" ||  timeString == "23:59:59" {
                timeString = "00:00:00"
            }
            return timeString
        } else {
            // Return nil if the input string could not be parsed into a Date
            print("Failed to turn \(dateString) into a string")
            throw dateError.failedToFormatDate
        }
    }
    
    func datesFromStrings(dayOfTheWeek: DateComponents, timeStrings: [String], closingTime: Bool) throws -> [Date] {
        var dates: [Date] = []
        timeFormatter.dateFormat = "HH:mm:ss" // Adjust based on your input format
        timeFormatter.timeZone = TimeZone.current // Or set to the appropriate time zone
        
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
    
    //   Returns the components of the next occurrence of the current day
        func nextOccurrence(ofDayOfWeek day: String) throws -> DateComponents {
            let calendar = Calendar.current
            var dateComponents = DateComponents()
            
            // Get the current date
            let currentDate = Date()
            
            // Get the weekday of the current date (Sunday: 1, Monday: 2, ..., Saturday: 7)
            let currentWeekday = calendar.component(.weekday, from: currentDate)
            
            // Get the index of the input day (case-insensitive)
            guard let index = calendar.weekdaySymbols.firstIndex(where: { $0.caseInsensitiveCompare(day) == .orderedSame }) else {
                print("Invalid day of the week: \(day)")
                throw dateError.failedToFormatDate
            }
            
            // Calculate the number of days until the next occurrence of the input day
            let daysUntilNextDay = (index + 7 - currentWeekday + 1) % 7
            
            // Add the number of days to the current date
            if let nextDate = calendar.date(byAdding: .day, value: daysUntilNextDay, to: currentDate) {
                // Get the components for the next occurrence of the input day
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
        
        // Convert the input string to a Date object
        if let date = timeReadableInputFormatter.date(from: adjustedInput) {
            // Create a DateFormatter for the output format
            
            // Check if minutes are not "00"
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: date)
            
            if components.minute == 0 {
                timeReadableOutputFormatter.dateFormat = "h a"
            } else {
                timeReadableOutputFormatter.dateFormat = "h:mm a"
            }
            
            timeReadableOutputFormatter.amSymbol = "AM"
            timeReadableOutputFormatter.pmSymbol = "PM"
            
            // Convert the Date object to the desired string format
            return timeReadableOutputFormatter.string(from: date)
        } else {
            throw dateError.failedToFormatDate
        }
    }
}
