//
//  ContentView.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/25/24.
//

import SwiftUI

struct BeastroHomeView: View {
    
    @State private var showMenu: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    homePageTitle
                    Spacer()
                }
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
            Spacer()
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
}
