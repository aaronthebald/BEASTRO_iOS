//
//  ContentView.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/25/24.
//

import SwiftUI

struct BeastroHomeView: View {
    
    @StateObject private var vm = BeastroHomeViewModel(networkingService: NetworkingService())
    @State private var showMenu: Bool = false
    @State private var showFullHours: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 50) {
                HStack {
                    homePageTitle
                    Spacer()
                }
                VStack(alignment: .leading) {
                    currentOpenStatus
                    if showFullHours {
                        Divider()
                            .foregroundStyle(Color.primary)
                        VStack(spacing: 10) {
                            ForEach(vm.formattedDaysTimes, id: \.self) { day in
                                HStack(alignment: .top) {
                                    Text(day.weekday)
                                    Spacer()
                                    if day.startTimes == [] || day.endTimes == [] {
                                        Text("Closed")
                                    } else if day.endTimes.contains("24:00:00") && day.startTimes.contains("00:00:00") {
                                        Text("Open 24 hours")
                                    } else {
                                        HStack(alignment: .top) {
                                            VStack {
                                                ForEach(day.startTimes, id: \.self) { time in
                                                        Text("\(makeTimeReadable(input: time)) -")
                                                }
                                            }
                                            
                                            VStack {
                                                ForEach(day.endTimes, id: \.self) { time in
                                                        Text(makeTimeReadable(input: time))
                                                }
                                            }
                                        }
                                       

                                    }
                                }
                            }
                        }
                    }
                }
                .padding(25)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Material.ultraThin)
                }
                .padding(.horizontal, 20)
                Spacer()
                Button {
                    showMenu = true
                } label: {
                    showMenuButton
                }
            }
            .background {
                Image("HomeScreenImage_Local")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea(.all)
            }
            .sheet(isPresented: $showMenu, onDismiss: {showMenu = false}, content: {
                Text("This is where the menu would go")
            })
            .task {
                await vm.fetchBusinessHours()
                vm.consolidateReturnedDays()
            }
            .alert("Uh Oh", isPresented: $vm.showAlert) {
                Button {
                    vm.showAlert = false
                } label: {
                    Text("Dismiss")
                }
            } message: {
                Text(vm.errorMessage)
            }
        }
    }
}

#Preview {
    BeastroHomeView()
}

extension BeastroHomeView {
    private var homePageTitle: some View {
        VStack(alignment: .leading) {
            Text("BEASTRO by")
            Text("Marshawn")
            Text("Lynch")
        }
        .padding(.leading)
        .font(.largeTitle)
        .fontWeight(.heavy)
        .foregroundStyle(Color.white)
    }
    
    private var showMenuButton: some View {
        VStack(spacing: 7) {
            Image(systemName: "chevron.up")
                .foregroundStyle(Color.white.opacity(0.5))
            Image(systemName: "chevron.up")
                .foregroundStyle(Color.white)
            Text("View Menu")
                .foregroundStyle(Color.white)
        }
        .fontWeight(.bold)
    }
    
    private var currentOpenStatus: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Open until 7PM")
                    Circle()
                        .frame(height: 7)
                        .foregroundStyle(Color.green)
                }
                Text("SEE FULL HOURS")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
            Button {
                withAnimation(.easeIn) {
                    showFullHours.toggle()
                }
            } label: {
                Image(systemName: showFullHours ? "chevron.up" : "chevron.right")
                    .foregroundStyle(Color.primary)
            }
        }
    }
    private func makeTimeReadable(input: String) -> String {
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
