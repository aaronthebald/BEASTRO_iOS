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
    
    func consolidateReturnedDays() {
        var newArray: [DayWithAbbreviations] = []
        for day in daysOfTheWeek {
            let findTheDaysArray = returnedHours.filter({$0.dayOfWeek == day.abv})
            let openingTimes = findTheDaysArray.map { $0.startLocalTime }
            let closingTimes = findTheDaysArray.map { $0.endLocalTime }
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
                    let within24Hours = calendar.date(byAdding: .hour, value: -24, to: nextDayOpenDate)
                    let isOpeningWithin24Hours = currentTime >= nextDayOpenTime
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
                            openStatusText = "Open until \(makeTimeReadable(input: closeDateString)), reopens at THIS NEEDS TO BE FIXED"
                            openStatusLight = .yellow
                        }
                    } else {
                        print("This is running")
                        restaurantIsOpen = false
                        openStatusLight = .red
                        guard let nextDayOpen = getNextOpenDay(businessHours: formattedDaysTimes) else { return }
                        guard let nextOpenDateString = nextDayOpen.startTimes.first else { return }
                        if let nextDayOpenDate = currentDayFormatter.date(from: nextDayOpen.weekday),
                           let nextDayOpenTime = timeFormatter.date(from: nextOpenDateString) {
                            let within24Hours = calendar.date(byAdding: .hour, value: -24, to: nextDayOpenDate)
                            let  isOpeningWithin24Hours = currentTime >= nextDayOpenTime
                            if isOpeningWithin24Hours {
                                print("HEYYYYOO")
                            }
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
            
            if let dayHours = businessHours.first(where: { $0.weekday == dayName && !$0.startTimes.isEmpty }) {
                return dayHours
            }
        }
        return nil
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
