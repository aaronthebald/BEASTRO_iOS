//
//  BeastroHomeViewModel.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/26/24.
//

import Foundation
import SwiftUI

final class BeastroHomeViewModel: ObservableObject {
        
    @Published var businessName: String = ""
    @Published var showAlert: Bool = false
    @Published var errorMessage: String = ""
    @Published var openStatusLight: IndicatorLights = .red
    @Published var openStatusText: String = ""
    @Published var operatingHours: [OperatingHoursForWeekDay] = []
    @Published var dataIsLoading: Bool = true
    @Published var currentDay: String = ""
    
    init(networkingService: NetworkingServiceProtocol) {
        self.networkingService = networkingService
        getCurrentDayOfTheWeek()
    }

    let dateAndTimeService = DateAndTimeService()
    
    private var formattedDaysTimes: [DayWithParsableDates] = []
    private var returnedHours: [OpenPeriod] = []
    
    private var networkingService: NetworkingServiceProtocol
    
    //    Creating an array of Days of the week to iterate through and assign values to start and end times
   private var daysOfTheWeek = [
        DayWithParsableDates(weekday: "Monday", abv: "MON", startTimes: [], endTimes: [], startTimeInDateFormat: [], endTimeInDateFormat: []),
        DayWithParsableDates(weekday: "Tuesday", abv: "TUE", startTimes: [], endTimes: [], startTimeInDateFormat: [], endTimeInDateFormat: []),
        DayWithParsableDates(weekday: "Wednesday", abv: "WED", startTimes: [], endTimes: [], startTimeInDateFormat: [], endTimeInDateFormat: []),
        DayWithParsableDates(weekday: "Thursday", abv: "THU", startTimes: [], endTimes: [], startTimeInDateFormat: [], endTimeInDateFormat: []),
        DayWithParsableDates(weekday: "Friday", abv: "FRI", startTimes: [], endTimes: [], startTimeInDateFormat: [], endTimeInDateFormat: []),
        DayWithParsableDates(weekday: "Saturday", abv: "SAT", startTimes: [], endTimes: [], startTimeInDateFormat: [], endTimeInDateFormat: []),
        DayWithParsableDates(weekday: "Sunday", abv: "SUN", startTimes: [], endTimes: [], startTimeInDateFormat: [], endTimeInDateFormat: [])
    ]
//    Make network call to receive JSON data using the NetworkingService class
    func fetchBusinessHours() async {
        do {
            let hoursResponse = try await networkingService.fetchBusinessHours()
            await MainActor.run {
                returnedHours = hoursResponse.hours
                businessName = hoursResponse.locationName
                dataIsLoading = false
            }
        } catch  {
            await MainActor.run {
                dataIsLoading = false
                showAlert = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
//    Function to get current date of the week. This is to allow the view to make the current date font weight .bold
   private func getCurrentDayOfTheWeek() {
        currentDay = dateAndTimeService.getCurrentDayOfWeek()
    }
    
    func consolidateReturnedOpenPeriodsFromAPI() {
        var newArray: [DayWithParsableDates] = []
        
        for day in daysOfTheWeek {
            let filteredHours = returnedHours.filter { $0.dayOfWeek == day.abv }
            let openingTimes = filteredHours.map { $0.startLocalTime }
            let closingTimes = filteredHours.map { $0.endLocalTime }
            let dayOfTheWeek = dateAndTimeService.nextOccurrence(ofDayOfWeek: day.weekday)
            let startTimesInDateFormat = dateAndTimeService.datesFromStrings(dayOfTheWeek: dayOfTheWeek!, timeStrings: openingTimes, closingTime: false)
            let endTimesInDateFormat = dateAndTimeService.datesFromStrings(dayOfTheWeek: dayOfTheWeek!, timeStrings: closingTimes, closingTime: true)
            
            let operatingHour = OperatingHoursForWeekDay(dayOfWeek: day.weekday, openingTimes: openingTimes, closingTimes: closingTimes)
            operatingHours.append(operatingHour)
            
            let formattedDay = DayWithParsableDates(
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
        setAndFormatMainText()
        setAndSortOpeningAndClosingTimes()
    }
    
   private func setAndFormatMainText() {
        let now = Date()
        guard let spanDate = getSpan(getNextOpenTime: false) else {
            print("There was a problem building the span")
            return
        }
        let span = spanDate.0...spanDate.1
        if span.contains(now) {
            let dateWithin1HourObject = Calendar.current.date(byAdding: .hour, value: 1, to: now)!
            if spanDate.1 < dateWithin1HourObject {
//           OPEN BUT CLOSING WITHIN AN HOUR
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
//          CLOSED. NEXT OPEN TIME IS MORE THAN 24 HOURS IN THE FUTURE
            if within24Hours < spanDate.0 {
                openStatusLight = .red
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
//              Get text for next time restaurant will be open
                guard let openingTimeString = dateAndTimeService.formatTime(from: spanDate.0.description, getWeekDay: false) else {
                    print("This is broken E")
                    return }
                openStatusText = "Opens again at \(dateAndTimeService.makeTimeReadable(input: openingTimeString))"
            }
        }
    }
    
    //   This function creates a tuple containing the Dates of an opening and closing time.
    func getSpan(getNextOpenTime: Bool) -> (Date, Date)? {
        let now = Date()
        var pairsOfDates: [(Date, Date)] = []
        for day in formattedDaysTimes {
            let pairedDates: [(Date, Date)] = convertArraysIntoTuplesOfDates(array1: day.startTimeInDateFormat, array2: day.endTimeInDateFormat)
            for dates in pairedDates {
                pairsOfDates.append(dates)
            }
        }
        
        let sortedByFirstDate = pairsOfDates.sorted { $0.0 < $1.0 }
        for dates in sortedByFirstDate {
            let span = dates.0...dates.1
            guard let nextOpenTime = sortedByFirstDate.first(where: {$0.0 > now}) else {
                print("The getSpan function is broken")
                return nil
            }
            if getNextOpenTime {
                print("getNextOpenTime block ran")
                return nextOpenTime
            }
            if span.contains(now) {
                if isTheClosingTimePastMidnight(pair1: dates, pair2: nextOpenTime) {
                    return (dates.0, nextOpenTime.1)
                    
                } else {
                    return dates
                }
            }
        }
        guard let nextOpenTime = sortedByFirstDate.first(where: {$0.0 > now}) else {
            print("The getSpan function is broken")
            return nil
        }
        return nextOpenTime
    }
    
//    This function if used to determine if the restaurant is open past midnight
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
    
    
   private func convertArraysIntoTuplesOfDates(array1: [Date], array2: [Date]) -> [(Date, Date)] {
        let count = min(array1.count, array2.count)
        var pairedArray: [(Date, Date)] = []
        
        for i in 0..<count {
            pairedArray.append((array1[i], array2[i]))
        }
        return pairedArray
    }
    
   private func setAndSortOpeningAndClosingTimes() {
        var sortedArray: [OperatingHoursForWeekDay] = []
        for day in operatingHours {
            let  sortedOpenTimes = day.openingTimes.sorted { $0 < $1}
            let sortedClosingTimes = day.closingTimes.sorted { $0 < $1 }
            let newOperatingHour = OperatingHoursForWeekDay(dayOfWeek: day.dayOfWeek, openingTimes: sortedOpenTimes, closingTimes: sortedClosingTimes)
            sortedArray.append(newOperatingHour)
            
        }
        operatingHours = sortedArray
        
        for i in stride(from: 0, to: operatingHours.count - 1, by: 1) {
            let day1 = operatingHours[i]
            let day2 = operatingHours[i + 1]
            if day1.closingTimes.contains("24:00:00") && day2.openingTimes.contains("00:00:00") && !day2.closingTimes.first!.contains("24:00:00") {
                var newClosingTimesDay1 = day1.closingTimes
                if let lastClosingTimeIndex = newClosingTimesDay1.lastIndex(of: "24:00:00") {
                    newClosingTimesDay1[lastClosingTimeIndex] = day2.closingTimes.first!
                }
                
                let newDay1 = OperatingHoursForWeekDay(dayOfWeek: day1.dayOfWeek, openingTimes: day1.openingTimes, closingTimes: newClosingTimesDay1)
                
                var newOpeningTimesDay2 = day2.openingTimes
                newOpeningTimesDay2.removeFirst()
                
                var newClosingTimesDay2 = day2.closingTimes
                newClosingTimesDay2.removeFirst()
                
                let newDay2 = OperatingHoursForWeekDay(dayOfWeek: day2.dayOfWeek, openingTimes: newOpeningTimesDay2, closingTimes: newClosingTimesDay2)
                
                operatingHours[i] = newDay1
                operatingHours[i + 1] = newDay2
            }
        }
        
        // Compare the last object to the first object: "Sunday to Monday
        if let firstDay = operatingHours.first, let lastDay = operatingHours.last {
            if lastDay.closingTimes.contains("24:00:00") && firstDay.openingTimes.contains("00:00:00") {
                var newClosingTimesLastDay = lastDay.closingTimes
                // Assuming closingTimes is an array of strings
                if let lastClosingTimeIndex = newClosingTimesLastDay.lastIndex(of: "24:00:00") {
                    newClosingTimesLastDay[lastClosingTimeIndex] = firstDay.closingTimes.first!
                }
                
                let newLastDay = OperatingHoursForWeekDay(dayOfWeek: lastDay.dayOfWeek, openingTimes: lastDay.openingTimes, closingTimes: newClosingTimesLastDay)
                
                var newOpeningTimesFirstDay = firstDay.openingTimes
                newOpeningTimesFirstDay.removeFirst()
                
                var newClosingTimesFirstDay = firstDay.closingTimes
                newClosingTimesFirstDay.removeFirst()
                
                let newFirstDay = OperatingHoursForWeekDay(dayOfWeek: firstDay.dayOfWeek, openingTimes: newOpeningTimesFirstDay, closingTimes: newClosingTimesFirstDay)
                
                if let firstDayIndex = operatingHours.firstIndex(where: { $0.dayOfWeek == newFirstDay.dayOfWeek }),
                   let lastDayIndex = operatingHours.firstIndex(where: { $0.dayOfWeek == newLastDay.dayOfWeek }) {
                    operatingHours[firstDayIndex] = newFirstDay
                    operatingHours[lastDayIndex] = newLastDay
                }
            }
        }
    }
    
    enum IndicatorLights {
        case red
        case yellow
        case green
        
        var color: Color {
            switch self {
            case .red:
                return Color.red
            case .yellow:
                return Color.yellow
            case .green:
                return Color.green
            }
        }
    }
}




