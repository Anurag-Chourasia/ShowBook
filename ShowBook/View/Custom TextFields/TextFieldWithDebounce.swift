//
//  TextFieldWithDebounce.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import Combine
import SwiftUI
import UIComponentsKit

class TextFieldObserver: ObservableObject {
    @Published var searchText = ""
    @Published var debouncedText = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $searchText
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.debouncedText = text
            }
            .store(in: &cancellables)
    }
}

struct TextFieldWithDebounce: View {
    @Binding var debouncedText: String
    @StateObject private var textObserver = TextFieldObserver()
    @State private var books: [Book] = []

    var body: some View {
        VStack {
            TextField("", text: $textObserver.searchText)
                .padding(.trailing, 21)
                .fieldPlaceholder(when: textObserver.searchText.isEmpty) {
                    HStack {
                        Text("Search for Books")
                            .foregroundColor(ShowBookTheme.colors.foreground)
                            .font(.title3)
                    }
                }
                .onChange(of: textObserver.debouncedText) {
                    debouncedText = textObserver.debouncedText
                }
        }
    }
}

// Preview for testing
struct TextFieldWithDebounce_Previews: PreviewProvider {
    @State static private var debouncedText = ""

    static var previews: some View {
        TextFieldWithDebounce(debouncedText: $debouncedText)
    }
}
