//
//  ContentView.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/25/24.
//

import SwiftUI

struct BeastroHomeView: View {
    
    @StateObject private var viewModel = BeastroHomeViewModel(networkingService: NetworkingService())
    @State private var showFullHours: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                HStack {
                    homePageTitle
                    Spacer()
                }
                
                hoursInformationAccordion
                
                Spacer()
                
                showMenuButton
            }
            .background {
                Image(.homeScreenImageLocal)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea(.all)
            }
            .task {
                await viewModel.fetchBusinessHours()
                viewModel.consolidateReturnedOpenPeriodsFromAPI()
            }
            .alert("There was an error", isPresented: $viewModel.showAlert) {
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
        Text(viewModel.businessName)
        .padding(.leading)
        .lineLimit(3)
        .font(.custom(FontHelper.instance.firaSans, size: 54, relativeTo: .largeTitle))
        .fixedSize(horizontal: false, vertical: true)
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
                .font(.custom(FontHelper.instance.hindSiliguriREG, size: 24, relativeTo: .body))
                .foregroundStyle(Color.white)
        }
        .fontWeight(.bold)
    }
    
    private var currentOpenStatus: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                
                HStack {
                    Text(viewModel.openStatusText)
                        .font(.custom(FontHelper.instance.hindSiliguriREG, size: 18, relativeTo: .body))

                    Circle()
                        .frame(height: 7)
                        .foregroundStyle(viewModel.openStatusLight.color)
                }
                
                Text("SEE FULL HOURS")
                    .font(.custom(FontHelper.instance.chivo, size: 12, relativeTo: .body))
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
        VStack {
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
                                   try? Text("\(viewModel.dateAndTimeService.makeTimeReadable(input: time))  -")
                                }
                            }
                            
                            VStack {
                                ForEach(day.closingTimes, id: \.self) { time in
                                    try? Text(viewModel.dateAndTimeService.makeTimeReadable(input: time))
                                }
                            }
                        }
                    }
                }
                .font(.custom(day.dayOfWeek == viewModel.currentDay ? FontHelper.instance.hindSiliguriBOLD : FontHelper.instance.hindSiliguriREG, size: 18, relativeTo: .body))
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
