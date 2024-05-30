//
//  DateAndTimeService.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/26/24.
//

import Foundation

class DateAndTimeService {
    
    let timeFormatter = DateFormatter()
    let timeReadableInputFormatter = DateFormatter()
    let dateFormatter = DateFormatter()
    let timeReadableOutputFormatter = DateFormatter()
    let formatter = DateFormatter()

    func getCurrentDayOfWeek() -> String {
        let date = Date()
        dateFormatter.dateFormat = "EEEE" // "EEEE" gives the full name of the day
        let dayOfWeekString = dateFormatter.string(from: date)
        return dayOfWeekString
    }
    
    func dateFrom(weekday: String, time: String) -> Date? {
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"  // Updated to match the time format "07:00:00"
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
    
    func formatTime(from dateString: String, getWeekDay: Bool) -> String? {
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
            let timeString = dateFormatter.string(from: date)
            print(timeString)
            return timeString
        } else {
            // Return nil if the input string could not be parsed into a Date
            print("Failed to turn \(dateString) into a string")
            return nil
        }
    }
    
    func datesFromStrings(dayOfTheWeek: DateComponents, timeStrings: [String], closingTime: Bool) -> [Date] {
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
                    } else {
                        print("Could not combine date components for string: \(correctedTimeString)")
                    }
                } else {
                    print("Invalid date format for string: \(correctedTimeString)")
                }
            } else {
                if let timeDate = timeFormatter.date(from: timeString) {
                    var dateComponents = calendar.dateComponents([.hour, .minute, .second], from: timeDate)
                    dateComponents.year = dayOfTheWeek.year
                    dateComponents.month = dayOfTheWeek.month
                    dateComponents.day = dayOfTheWeek.day
                    
                    if let combinedDate = calendar.date(from: dateComponents) {
                        dates.append(combinedDate)
                    } else {
                        print("Could not combine date components for string: \(timeString)")
                    }
                } else {
                    print("Invalid date format for string: \(timeString)")
                }
            }
        }
        return dates
    }
    
    //   Returns the components of the next occurrence of the current day
        func nextOccurrence(ofDayOfWeek day: String) -> DateComponents? {
            let calendar = Calendar.current
            var dateComponents = DateComponents()
            
            // Get the current date
            let currentDate = Date()
            
            // Get the weekday of the current date (Sunday: 1, Monday: 2, ..., Saturday: 7)
            let currentWeekday = calendar.component(.weekday, from: currentDate)
            
            // Get the index of the input day (case-insensitive)
            guard let index = calendar.weekdaySymbols.firstIndex(where: { $0.caseInsensitiveCompare(day) == .orderedSame }) else {
                print("Invalid day of the week: \(day)")
                return nil
            }
            
            // Calculate the number of days until the next occurrence of the input day
            let daysUntilNextDay = (index + 7 - currentWeekday + 1) % 7
            
            // Add the number of days to the current date
            if let nextDate = calendar.date(byAdding: .day, value: daysUntilNextDay, to: currentDate) {
                // Get the components for the next occurrence of the input day
                dateComponents = calendar.dateComponents([.year, .month, .day], from: nextDate)
            } else {
                print("Unable to get the next occurrence of weekday ")
            }
            return dateComponents
        }
    
    func makeTimeReadable(input: String) -> String {
        var returnedString = ""
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
            returnedString = timeReadableOutputFormatter.string(from: date)
        } else {
            print("Invalid input time format")
        }
        
        return returnedString
    }

}
