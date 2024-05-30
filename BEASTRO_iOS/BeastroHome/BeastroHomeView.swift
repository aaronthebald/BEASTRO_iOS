//
//  ContentView.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/25/24.
//

import SwiftUI

struct BeastroHomeView: View {
    
    @StateObject private var viewModel = BeastroHomeViewModel(networkingService: NetworkingService())
    @State private var showMenu: Bool = false
    @State private var showFullHours: Bool = false
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 50) {
                HStack {
                    homePageTitle
                    Spacer()
                }
                
                hoursInformationAccordion
                
                Spacer()
                
                Button {
                    showMenu = true
                } label: {
                    showMenuButton
                }
            }
            .background {
                Image(.homeScreenImageLocal)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea(.all)
            }
            .sheet(isPresented: $showMenu, onDismiss: {showMenu = false}, content: {
                Text("This is where the menu would go")
            })
            .task {
                await viewModel.fetchBusinessHours()
                viewModel.consolidateReturnedDays()
            }
            .alert("Uh Oh", isPresented: $viewModel.showAlert) {
                Button {
                    viewModel.showAlert = false
                } label: {
                    Text("Dismiss")
                }
            } message: {
                Text(viewModel.errorMessage)
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
    
    private var hoursInformationAccordion: some View {
        VStack(alignment: .leading) {
            currentOpenStatus
                .onTapGesture {
                    withAnimation(.easeIn) {
                        showFullHours.toggle()
                    }
                }
            if showFullHours {
                Divider()
                    .foregroundStyle(Color.primary)
                openCloseTimes
            }
        }
        .padding(25)
        .frame(maxWidth: .infinity)
        
        .background {
            RoundedRectangle(cornerRadius: 7)
                .fill(Material.ultraThin)
        }
        .padding(.horizontal, 20)
        .overlay {
            if viewModel.dataIsLoading {
                loadingCover
            }
        }
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
                    Text(viewModel.openStatusText)
                    
                    Circle()
                        .frame(height: 7)
                        .foregroundStyle(viewModel.openStatusLight.color)
                }
                
                Text("SEE FULL HOURS")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.primary)
                .rotationEffect(.degrees(showFullHours ? -90 : 0)) // Rotate 90 degrees if showFullHours is true
        }
        .contentShape(Rectangle().inset(by: -25)) // Increase the tappable area by 25 points on all sides
        
    }
    
    private var openCloseTimes: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.operatingHours, id: \.self) { day in
                HStack(alignment: .top) {
                    Text(day.dayOfWeek)
                    
                    Spacer()
                    
                    if day.openingTimes == [] || day.closingTimes == [] {
                        Text("Closed")
                    } else if day.closingTimes.contains("24:00:00") && day.openingTimes.contains("00:00:00") {
                        Text("Open 24 hours")
                    } else {
                        HStack(alignment: .top) {
                            VStack {
                                ForEach(day.openingTimes, id: \.self) { time in
                                    Text("\(viewModel.dateAndTimeService.makeTimeReadable(input: time)) -")
                                }
                            }
                            
                            VStack {
                                ForEach(day.closingTimes, id: \.self) { time in
                                    Text(viewModel.dateAndTimeService.makeTimeReadable(input: time))
                                }
                            }
                        }
                    }
                }
                .fontWeight(viewModel.currentDay == day.dayOfWeek ? .bold : .regular)
            }
        }
    }
    
    
    private var loadingCover: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .frame(height: 95)
            .background {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Material.ultraThin).opacity(0.85)
                    .padding(.horizontal, 20)
                
            }
    }
}
