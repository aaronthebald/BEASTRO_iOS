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
    let currentDayFormatter = DateFormatter()
    let timeFormatter = DateFormatter()

    var networkingService: NetworkingServiceProtocol
    var daysOfTheWeek = [
        DayWithAbbreviations(weekday: "Monday", abv: "Mon", startTimes: [], endTimes: []),
        DayWithAbbreviations(weekday: "Tuesday", abv: "TUE", startTimes: [], endTimes: []),
        DayWithAbbreviations(weekday: "Wednesday", abv: "WED", startTimes: [], endTimes: []),
        DayWithAbbreviations(weekday: "Thursday", abv: "THU", startTimes: [], endTimes: []),
        DayWithAbbreviations(weekday: "Friday", abv: "FRI", startTimes: [], endTimes: []),
        DayWithAbbreviations(weekday: "Saturday", abv: "SAT", startTimes: [], endTimes: []),
        DayWithAbbreviations(weekday: "Sunday", abv: "SUN", startTimes: [], endTimes: [])
    ]
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
    func datesFromStrings(timeStrings: [String]) -> [Date] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
//        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        var dates: [Date] = []
        
        for timeString in timeStrings {
            if timeString == "24:00:00" {
                var fixedTimeString = "00:00:00"
                if let date = dateFormatter.date(from: fixedTimeString) {
                    dates.append(date)
                } else {
                    print("Invalid time string format: \(fixedTimeString)")
                }
            } else {
                if let date = dateFormatter.date(from: timeString) {
                    dates.append(date)
                } else {
                    print("Invalid time string format: \(timeString)")
                }
            }
        }
        
        return dates
    }
    
    func consolidateReturnedDays() {
        var newArray: [DayWithAbbreviations] = []
        for day in daysOfTheWeek {
            let findTheDaysArray = returnedHours.filter({$0.dayOfWeek == day.abv})
            let openingTimes = findTheDaysArray.map { $0.startLocalTime }
            let closingTimes = findTheDaysArray.map { $0.endLocalTime }
            let startTimesInDateFormat = datesFromStrings(timeStrings: openingTimes)
            let endTimesInDateFormat = datesFromStrings(timeStrings: closingTimes)
            print(startTimesInDateFormat, endTimesInDateFormat)
            let formattedDay = DayWithAbbreviations(weekday: day.weekday, abv: day.abv, startTimes: openingTimes, endTimes: closingTimes)
            newArray.append(formattedDay)
            formattedDaysTimes = newArray
        }
        getOpenStatus()
    }
    
    func getOpenStatus() {
        // Get the current date
        let currentDate = Date()
        let calendar = Calendar.current
        // "EEEE" gives the full name of the day of the week
        currentDayFormatter.dateFormat = "EEEE"
        timeFormatter.dateFormat = "HH:mm:ss"
        // Get the day of the week string
        let dayOfWeek = currentDayFormatter.string(from: currentDate)
        currentDay = dayOfWeek
        guard let todaysHoursObject = formattedDaysTimes.first(where: {$0.weekday == currentDay}) else {
            print("The Full function isn't running")
            return
        }
//        Restaurant is closed
        if todaysHoursObject.startTimes == [] && todaysHoursObject .startTimes == [] {
            let currentTimeString = timeFormatter.string(from: currentDate)
            if let currentTime = timeFormatter.date(from: currentTimeString) {
                restaurantIsOpen = false
                openStatusLight = .red
                guard let nextDayOpen = getNextOpenDay(businessHours: formattedDaysTimes) else {
                    print("Part A Is broken")
                    return
                }
                guard let nextOpenDateString = nextDayOpen.startTimes.first else {
                    print("Part B is broken")
                    return
                }
                if let nextDayOpenDate = currentDayFormatter.date(from: nextDayOpen.weekday),
                   let nextDayOpenTime = timeFormatter.date(from: nextOpenDateString) {
                    let within24Hours = calendar.date(byAdding: .hour, value: -24, to: nextDayOpenTime)!
                    let isOpeningWithin24Hours = currentTime >= nextDayOpenTime && currentTime >= within24Hours
                    if isOpeningWithin24Hours {
                        openStatusText = "Opens again at \(makeTimeReadable(input: nextOpenDateString))"
                    } else {
                        openStatusText = "Opens \(nextDayOpen.weekday) at \(makeTimeReadable(input: nextOpenDateString))"
                    }
                }
            }
        }
        
        let currentTimeString = timeFormatter.string(from: currentDate)
        for openTime in todaysHoursObject.startTimes {
            for closedTime in todaysHoursObject.endTimes {
                if let openDate = timeFormatter.date(from: openTime),
                   let closeDate = timeFormatter.date(from: closedTime),
                   let currentTime = timeFormatter.date(from: currentTimeString) {
                    // Check if the Restaurant is open
                    if currentTime >= openDate && currentTime <= closeDate {
                        restaurantIsOpen = true
                        openStatusLight = .green
//                        Checks if Restaurant is closing within the hour
                       let closeDateString = closeDate.description
                        openStatusText = "Open until \(makeTimeReadable(input: closeDateString))"
                        let oneHourBeforeClose = calendar.date(byAdding: .hour, value: -1, to: closeDate)!
                        let isClosingSoon = currentTime >= oneHourBeforeClose && currentTime <= closeDate
                        closingSoon = isClosingSoon
                        if closingSoon {
                            guard let nextDayOpen = getNextOpenDay(businessHours: formattedDaysTimes) else { return }
                            
                            openStatusText = "Open until \(makeTimeReadable(input: closeDateString)), reopens at THIS NEEDS TO BE FIXED"
                            openStatusLight = .yellow
                        }
                    }
                }
            }
        }
    }
    func getCurrentDayString() -> String {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: now)
    }
    
    func getNextOpenDay(businessHours: [DayWithAbbreviations]) -> DayWithAbbreviations? {
        let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let currentDay = getCurrentDayString()
        guard let currentIndex = daysOfWeek.firstIndex(of: currentDay) else {
            print("This part is broken")
            return nil }
        
        // Iterate through the days starting from the current day
        for offset in 0..<daysOfWeek.count {
            let dayIndex = (currentIndex + offset) % daysOfWeek.count
            let dayName = daysOfWeek[dayIndex]
            for day in businessHours {
                if day.weekday == dayName && isStartTimeInThePast(day: day) && day.startTimes != [] {
                    return day
                }
            }
            
        }
        return nil
    }
    
    func isStartTimeInThePast(day: DayWithAbbreviations) -> Bool {
        let now = Date()
        var returnedBool: Bool = false
        if day.startTimes == [] {
            returnedBool = true
        } else {
            for startTime in day.startTimes {
                guard let timeOfDay = timeFormatter.date(from: startTime) else {
                    print("There was a problem in the isStartTimeInThePast function")
                    return false }
                if timeOfDay <= now {
                    returnedBool = true
                } else {
                    returnedBool = false
                }
            }
        }
        return returnedBool
    }
    
    func makeTimeReadable(input: String) -> String {
       var returnedString = ""
       let inputFormatter = DateFormatter()
       inputFormatter.dateFormat = "HH:mm:ss"

       // Convert the input string to a Date object
       if input == "24:00:00" {
          let newInput = "00:00:00"
           if let date = inputFormatter.date(from: newInput) {
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
           if let date = inputFormatter.date(from: input) {
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
}
