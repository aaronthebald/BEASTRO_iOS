//
//  ContentView.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/25/24.
//

import SwiftUI

struct BeastroHomeView: View {
    var body: some View {
        NavigationStack {
            HStack {
                homePageTitle
                Spacer()
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
}
