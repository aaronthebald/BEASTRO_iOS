//
//  BeastroHomeViewModel.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/26/24.
//

import Foundation

class BeastroHomeViewModel: ObservableObject {
    
    @Published var formattedDaysTimes: [DayWithAbbreviations] = []
    @Published var returnedHours: [Hour] = []
    @Published var showAlert: Bool = false
    @Published var errorMessage: String = ""
    @Published var currentDay: String = ""
    @Published var openStatusLight: IndicatorLights = .red
    @Published var openStatusText: String = ""
    @Published var restaurantIsOpen: Bool = false
    @Published var closingSoon: Bool = false
    
    
    init(networkingService: NetworkingServiceProtocol) {
        self.networkingService = networkingService
    }
    
    enum IndicatorLights {
        case red
        case yellow
        case green
    }
//    Initializing formatters and Services
    let dateAndTimeService = DateAndTimeService()
    let currentDayFormatter = DateFormatter()
    let timeFormatter = DateFormatter()
    let timeReadableInputFormatter = DateFormatter()
    let convertDateToStringFormatter = DateFormatter()
    
    var networkingService: NetworkingServiceProtocol
   
//    Creating an array of Days of the week to ittirate through and assign values to start and end times
    var daysOfTheWeek = [
        DayWithAbbreviations(weekday: "Monday", abv: "Mon", startTimes: [], endTimes: [], startTimeInDateFormat: [], endTimeInDateFormat: []),
        DayWithAbbreviations(weekday: "Tuesday", abv: "TUE", startTimes: [], endTimes: [], startTimeInDateFormat: [], endTimeInDateFormat: []),
        DayWithAbbreviations(weekday: "Wednesday", abv: "WED", startTimes: [], endTimes: [], startTimeInDateFormat: [], endTimeInDateFormat: []),
        DayWithAbbreviations(weekday: "Thursday", abv: "THU", startTimes: [], endTimes: [], startTimeInDateFormat: [], endTimeInDateFormat: []),
        DayWithAbbreviations(weekday: "Friday", abv: "FRI", startTimes: [], endTimes: [], startTimeInDateFormat: [], endTimeInDateFormat: []),
        DayWithAbbreviations(weekday: "Saturday", abv: "SAT", startTimes: [], endTimes: [], startTimeInDateFormat: [], endTimeInDateFormat: []),
        DayWithAbbreviations(weekday: "Sunday", abv: "SUN", startTimes: [], endTimes: [], startTimeInDateFormat: [], endTimeInDateFormat: [])
    ]
//    Make network call to receive JSON data using the NetworkingService class
    func fetchBusinessHours() async {
        do {
            let hours = try await networkingService.fetchBusinessHours()
            await MainActor.run {
                returnedHours = hours
            }
        } catch  {
            await MainActor.run {
                showAlert = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func createArrayOfDateFromArrayOfStartAndEndTimes(weekday: String, times: [String]  ) -> [Date] {
        var placeHolderArray: [Date] = []
        for time in times {
            guard let newDate = dateAndTimeService.dateFrom(weekday: weekday, time: time) else { return []}
            placeHolderArray.append(newDate)
        }
        return placeHolderArray
    }
    
    func formatTime(from dateString: String) -> String? {
        // Define the input date format including the timezone offset
        let inputDateFormat = "yyyy-MM-dd HH:mm:ss Z"
        // Create a DateFormatter for parsing the input date string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = inputDateFormat
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Parse the date string into a Date object
        if let date = dateFormatter.date(from: dateString) {
            // Define the output time format
            let outputTimeFormat = "HH:mm:ss"
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
//   This function creates a toupee containing the Dates of an opening and closing time.
    func getSpan() -> (Date, Date)? {
        let now = Date()
        var pairsOfDates: [(Date, Date)] = []
        var returnedSpan: (Date, Date)? = nil
        for day in formattedDaysTimes {
            let pairedDates: [(Date, Date)] = pairArrays(array1: day.startTimeInDateFormat, array2: day.endTimeInDateFormat)
            for dates in pairedDates {
                let span = dates.0...dates.1
                if span.contains(now) {
                    return dates
                }
                pairsOfDates.append(dates)
            }
        }
        for date in pairsOfDates {
            guard let nextOpenTime = pairsOfDates.first(where: {$0.0 > now}) else {
                print("The getSpan function is broken")
                return nil
            }
            return nextOpenTime
            
        }
        return returnedSpan
    }
    
    func mainTextController() {
        let now = Date()
        guard let spanDate = getSpan() else {
            print("There was a problem building the span")
            return
        }
            print("function ran")
                let span = spanDate.0...spanDate.1
                if span.contains(now) {
                    let within1Hour = Calendar.current.date(byAdding: .hour, value: 1, to: now)!
                    if spanDate.1 < within1Hour {
                        print("Closing within an hour!")
                        openStatusLight = .yellow
                        guard let closingTimeString = formatTime(from: spanDate.1.description) else {
                       print("This is broken Part A")
                        return }
                        openStatusText = "Open until \(makeTimeReadable(input: closingTimeString))"
                    } else {
                        print("The Restaurant is open!!!")
                        openStatusLight = .green
                        guard let closingTimeString = formatTime(from: spanDate.1.description) else {
                            print("This is broken part B")
                             return }
                        openStatusText = "Open until \(makeTimeReadable(input: closingTimeString))"
                    }
                }
//                If the current date and time is not within a span the restaurant is closed. That status will be handled here.
                else {
                    let within24Hours = Calendar.current.date(byAdding: .hour, value: 24, to: now)!
                    print(within24Hours)
//                    Checking to see if the restaurant will reopen within 24 hours
                    if within24Hours > spanDate.0 {
                        openStatusLight = .red
                        print("MORE THAN 24 HOURS")
                        guard let openingTimeString = formatTime(from: spanDate.0.description) else {
                            print("This is broken part D")
                             return }
                        openStatusText = "Opens DAY at \(makeTimeReadable(input: openingTimeString))"
                    } else {
                        openStatusLight = .red
                        print("LESS THAN 24 HOURS")

                        guard let openingTimeString = formatTime(from: spanDate.0.description) else {
                            print("This is broken E")
                             return }
                        openStatusText = "Opens again at \(makeTimeReadable(input: openingTimeString))"
                    }
                }
            
        
    }
    func pairArrays(array1: [Date], array2: [Date]) -> [(Date, Date)] {
        let count = min(array1.count, array2.count)
        var pairedArray: [(Date, Date)] = []
        
        for i in 0..<count {
            pairedArray.append((array1[i], array2[i]))
        }
        
        return pairedArray
    }
    
    func datesFromStrings(dayOfTheWeek: DateComponents, timeStrings: [String], closingTime: Bool) -> [Date] {
        var dates: [Date] = []
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss" // Adjust based on your input format
        timeFormatter.timeZone = TimeZone.current // Or set to the appropriate time zone
        
        let calendar = Calendar.current
//        Removed these as are not being used in function
//        let today = Date() // Get current date
////        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
        
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
//    Why am i calling this? Returns the components of the next occurrence of the current day?
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
    
    func consolidateReturnedDays() {
        var newArray: [DayWithAbbreviations] = []
        
        for day in daysOfTheWeek {
            let filteredHours = returnedHours.filter { $0.dayOfWeek == day.abv }
            let openingTimes = filteredHours.map { $0.startLocalTime }
            let closingTimes = filteredHours.map { $0.endLocalTime }
            let dayOfTheWeek = nextOccurrence(ofDayOfWeek: day.weekday)
            let startTimesInDateFormat = datesFromStrings(dayOfTheWeek: dayOfTheWeek!, timeStrings: openingTimes, closingTime: false)
            let endTimesInDateFormat = datesFromStrings(dayOfTheWeek: dayOfTheWeek!, timeStrings: closingTimes, closingTime: true)
            
            let formattedDay = DayWithAbbreviations(
                weekday: day.weekday,
                abv: day.abv,
                startTimes: openingTimes,
                endTimes: closingTimes,
                startTimeInDateFormat: startTimesInDateFormat,
                endTimeInDateFormat: endTimesInDateFormat
            )
            
            newArray.append(formattedDay)
        }
        
        formattedDaysTimes = newArray
        mainTextController()
        
    }
    
    func makeTimeReadable(input: String) -> String {
        var returnedString = ""
        timeReadableInputFormatter.dateFormat = "HH:mm:ss"
        
        // Convert the input string to a Date object
        if input == "24:00:00" {
            let newInput = "00:00:00"
            if let date = timeReadableInputFormatter.date(from: newInput) {
                // Create a DateFormatter for the output format
                let outputFormatter = DateFormatter()
                outputFormatter.dateFormat = "h a"
                outputFormatter.amSymbol = "AM"
                outputFormatter.pmSymbol = "PM"
                
                // Convert the Date object to the desired string format
                let outputTime = outputFormatter.string(from: date)
                returnedString = outputTime
            } else {
                print("Invalid input time format")
            }
        } else {
            if let date = timeReadableInputFormatter.date(from: input) {
                // Create a DateFormatter for the output format
                let outputFormatter = DateFormatter()
                outputFormatter.dateFormat = "h a"
                outputFormatter.amSymbol = "AM"
                outputFormatter.pmSymbol = "PM"
                
                // Convert the Date object to the desired string format
                let outputTime = outputFormatter.string(from: date)
                returnedString = outputTime
            } else {
                print("Invalid input time format")
            }
        }
        return returnedString
    }
}

struct DayWithAbbreviations: Hashable {
    let weekday: String
    let abv: String
    let startTimes: [String]
    let endTimes: [String]
    let startTimeInDateFormat: [Date]
    let endTimeInDateFormat: [Date]
}
