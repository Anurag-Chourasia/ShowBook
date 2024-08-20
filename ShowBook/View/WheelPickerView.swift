//
//  WheelPickerView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI

struct WheelPickerView: View {
    @Binding var selectedCountryIndex: Int
    var country: [String]
    
    @Environment(\.managedObjectContext) private var viewContext
    let persistenceController = PersistenceController.shared
    
    var body: some View {
        VStack {
            Picker(selection: $selectedCountryIndex, label: Text("Select an Item")) {
                ForEach(0..<country.count, id: \.self) { index in
                    Text(self.country[index])
                        .tag(index)
                }
            }
            .frame(height: 140)
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
