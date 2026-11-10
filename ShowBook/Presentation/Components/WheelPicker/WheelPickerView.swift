import DesignTokensKit
//
//  WheelPickerView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import LocalizationKit
import CoreData

struct WheelPickerView: View {
    @Binding var selectedCountryIndex: Int
    var country: [String]
    var persistenceController: PersistenceController

    init(selectedCountryIndex: Binding<Int>, country: [String], persistenceController: PersistenceController) {
        self._selectedCountryIndex = selectedCountryIndex
        self.country = country
        self.persistenceController = persistenceController
    }

    #if DEBUG
    init(selectedCountryIndex: Binding<Int>, country: [String]) {
        self._selectedCountryIndex = selectedCountryIndex
        self.country = country
        self.persistenceController = PersistenceController.inMemory()
    }
    #endif
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack {
            Picker(selection: $selectedCountryIndex) {
                ForEach(0..<country.count, id: \.self) { index in
                    Text(self.country[index])
                        .tag(index)
                }
            } label: {
                Text(\.countrySelect)
            }
            .frame(height: \.p140)
            .pickerStyle(.wheel)
            .onChange(of: selectedCountryIndex){
                let name = country[selectedCountryIndex]
                persistenceController.saveDefaultCountryName(selectedCountryName: name)
            }
        }
    }
}

#Preview {
    WheelPickerView(selectedCountryIndex: .constant(0), country: ["India","USA","Nepal"])
}
