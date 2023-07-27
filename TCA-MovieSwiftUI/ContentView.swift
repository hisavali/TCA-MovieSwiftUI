//
//  ContentView.swift
//  TCA-MovieSwiftUI
//
//  Created by Hitesh Savaliya on 14/06/2023.
//

import SwiftUI
import MovieKit

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
