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
    @Published var openStatusLight: IndicatorLights = .green
    
    init(networkingService: NetworkingServiceProtocol) {
        self.networkingService = networkingService
        
    }
    
    enum IndicatorLights {
        case red
        case yellow
        case green
    }
    
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
        getDayOfTheWeek()
    }
    
    func getDayOfTheWeek() {
        // Get the current date
        let currentDate = Date()

        // Create a DateFormatter to get the day of the week as a string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"// "EEEE" gives the full name of the day of the week

        // Get the day of the week string
        let dayOfWeek = dateFormatter.string(from: currentDate)
        currentDay = dayOfWeek
        let todaysHoursObject = formattedDaysTimes.first(where: {$0.weekday == currentDay})
        
        if todaysHoursObject?.startTimes == [] && todaysHoursObject?.endTimes == [] {
            openStatusLight = .red
        }
        
        print(todaysHoursObject)
    }
}

struct DayWithAbbreviations: Hashable {
    let weekday: String
    let abv: String
    let startTimes: [String]
    let endTimes: [String]
}
