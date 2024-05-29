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
    
    
    var networkingService: NetworkingServiceProtocol
    
    //    Creating an array of Days of the week to iterate through and assign values to start and end times
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
    
    //   This function creates a tuple containing the Dates of an opening and closing time.
    func getSpan(getNextOpenTime: Bool) -> (Date, Date)? {
        let now = Date()
        var pairsOfDates: [(Date, Date)] = []
        let returnedSpan: (Date, Date)? = nil
        for day in formattedDaysTimes {
            let pairedDates: [(Date, Date)] = pairArrays(array1: day.startTimeInDateFormat, array2: day.endTimeInDateFormat)
            for dates in pairedDates {
                pairsOfDates.append(dates)
            }
        }
        
        let sortedByFirstDate = pairsOfDates.sorted { $0.0 < $1.0 }
        
        for dates in pairsOfDates {
            let span = dates.0...dates.1
            guard let nextOpenTime = sortedByFirstDate.first(where: {$0.0 > now}) else {
                print("The getSpan function is broken")
                return nil
            }
            
            if getNextOpenTime {
                guard let nextOpenTime = sortedByFirstDate.first(where: {$0.0 > now}) else {
                    print("The getSpan function is broken")
                    return nil
                }
                return nextOpenTime
            }
            
            if span.contains(now) {
                if isTheClosingTimePastMidnight(pair1: dates, pair2: nextOpenTime) {
                    print(dates.0, nextOpenTime.1)
                    return (dates.0, nextOpenTime.1)
                    
                } else {
                    print("We are here")
                    return dates
                }
            } else {
                guard let nextOpenTime = sortedByFirstDate.first(where: {$0.0 > now}) else {
                    print("The getSpan function is broken")
                    return nil
                }
                return nextOpenTime
            }
        }
        print("If you are reading this the getSpan function returned nil")
        return returnedSpan
    }
    
    func isTheClosingTimePastMidnight(pair1: (Date, Date), pair2: (Date, Date)) -> Bool {
        let newFormatter = DateFormatter()
        newFormatter.dateFormat = "HH:mm:ss"
        
        let closingTimeString = newFormatter.string(from: pair1.1)
        let openingTimeString = newFormatter.string(from: pair2.0)
        if closingTimeString.contains("24:00:00") || closingTimeString.contains("23:59:59") && openingTimeString.contains("00:00:00") {
            return true
        } else {
            return false
        }
    }
    
    func formatMainText() {
        let now = Date()
        guard let spanDate = getSpan(getNextOpenTime: false) else {
            print("There was a problem building the span")
            return
        }
        let span = spanDate.0...spanDate.1
        if span.contains(now) {
            let within1Hour = Calendar.current.date(byAdding: .hour, value: 1, to: now)!
            //                   OPEN BUT CLOSING WITHIN AN HOUR
            if spanDate.1 < within1Hour {
                print("Closing within an hour!")
                openStatusLight = .yellow
//              Get String for the time restaurant will be closing
                guard let closingTimeString = dateAndTimeService.formatTime(from: spanDate.1.description, getWeekDay: false) else {
                    print("This is broken Part A")
                    return
                }
//              Get span for next time restaurant will be open
                guard let nextOpenTime = getSpan(getNextOpenTime: true) else {
                    print("failed to get nextOpenTime")
                    return
                }
//              Get text for next time restaurant will be open
                guard let nextOpenTimeText = dateAndTimeService.formatTime(from: nextOpenTime.0.description, getWeekDay: false) else {
                    print("failed to get nextOpenTimeText")
                    return
                }
                openStatusText = "Open until \(dateAndTimeService.makeTimeReadable(input: closingTimeString)), reopens at \(dateAndTimeService.makeTimeReadable(input: nextOpenTimeText))"
            } else {
//              OPEN FOR MORE THAN AN HOUR LONGER
                print("The Restaurant is open!!!")
                openStatusLight = .green
//              Get String for the time restaurant will be closing
                guard let closingTimeString = dateAndTimeService.formatTime(from: spanDate.1.description, getWeekDay: false) else {
                    print("This is broken part B")
                    return }
                openStatusText = "Open until \(dateAndTimeService.makeTimeReadable(input: closingTimeString))"
            }
        }
//      If the current date and time is not within a span, the restaurant is closed. That status will be handled here.
        else {
            let within24Hours = Calendar.current.date(byAdding: .hour, value: 24, to: now)!
            print(within24Hours)
//          CLOSED. NEXT OPEN TIME IS MORE THAN 24 HOURS IN THE FUTURE
            if within24Hours < spanDate.0 {
                openStatusLight = .red
                print("MORE THAN 24 HOURS")
//              Get text for next time restaurant will be open
                guard let openingTimeString = dateAndTimeService.formatTime(from: spanDate.0.description, getWeekDay: false) else {
                    print("This is broken part D")
                    return
                }
//              Get text for next day restaurant will be open
                guard let openingDay = dateAndTimeService.formatTime(from: spanDate.0.description, getWeekDay: true) else {
                    print("failed to get openingDay String")
                    return
                }
                openStatusText = "Opens \(openingDay) at \(dateAndTimeService.makeTimeReadable(input: openingTimeString))"
            } else {
//              CLOSED REOPENS WITHIN 24 HOURS
                openStatusLight = .red
                print("LESS THAN 24 HOURS")
//              Get text for next time restaurant will be open
                guard let openingTimeString = dateAndTimeService.formatTime(from: spanDate.0.description, getWeekDay: false) else {
                    print("This is broken E")
                    return }
                openStatusText = "Opens again at \(dateAndTimeService.makeTimeReadable(input: openingTimeString))"
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
    
    
    
    
    func consolidateReturnedDays() {
        var newArray: [DayWithAbbreviations] = []
        
        for day in daysOfTheWeek {
            let filteredHours = returnedHours.filter { $0.dayOfWeek == day.abv }
            let openingTimes = filteredHours.map { $0.startLocalTime }
            let closingTimes = filteredHours.map { $0.endLocalTime }
            let dayOfTheWeek = dateAndTimeService.nextOccurrence(ofDayOfWeek: day.weekday)
            let startTimesInDateFormat = dateAndTimeService.datesFromStrings(dayOfTheWeek: dayOfTheWeek!, timeStrings: openingTimes, closingTime: false)
            let endTimesInDateFormat = dateAndTimeService.datesFromStrings(dayOfTheWeek: dayOfTheWeek!, timeStrings: closingTimes, closingTime: true)
            
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
        formatMainText()
        
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
