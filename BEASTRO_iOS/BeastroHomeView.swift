//
//  ContentView.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/25/24.
//

import SwiftUI

struct BeastroHomeView: View {
    
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
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text("Open until 7PM")

                        }
                        Spacer()
                        Button {
                            showFullHours.toggle()
                        } label: {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.primary)
                        }
                        
                    }
                }
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 15)
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
}
