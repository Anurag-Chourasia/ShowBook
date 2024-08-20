//
//  SupportingFile.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import Foundation
import SwiftUI
import Combine

func isValidEmail(_ email: String) -> Bool {

    let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
    
    if let regex = try? NSRegularExpression(pattern: emailRegex) {

        return regex.firstMatch(in: email, options: [], range: NSRange(location: 0, length: email.utf16.count)) != nil
    }
    return false
}

func isValidPassword(_ password: String) -> Bool {
    let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^A-Za-z\\d]).{8,}$"
    
    if let regex = try? NSRegularExpression(pattern: passwordRegex) {
        return regex.firstMatch(in: password, options: [], range: NSRange(location: 0, length: password.utf16.count)) != nil
    }
    
    return false
}


extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
            
            ZStack(alignment: alignment) {
                placeholder().opacity(shouldShow ? 1 : 0)
                self
            }
        }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        ModifiedContent(content: self, modifier: CornerRadiusStyle(radius: radius, corners: corners))
    }
}

struct CornerRadiusStyle: ViewModifier {
    var radius: CGFloat
    var corners: UIRectCorner
    
    struct CornerRadiusShape: Shape {
        
        var radius = CGFloat.infinity
        var corners = UIRectCorner.allCorners
        
        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            return Path(path.cgPath)
        }
    }
    
    func body(content: Content) -> some View {
        content
            .clipShape(CornerRadiusShape(radius: radius, corners: corners))
    }
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
extension String {
    
    var hasUppercaseCharacter: Bool {
        return rangeOfCharacter(from: .uppercaseLetters) != nil
    }
    
    var hasLowercaseCharacter: Bool {
           return rangeOfCharacter(from: .lowercaseLetters) != nil
       }
    
    var hasNumberCharacter: Bool {
            return rangeOfCharacter(from: .decimalDigits) != nil
        }
    
    var hasSpecialCharacter: Bool {
            let characterSet = CharacterSet(charactersIn: "!@#$%^&*()-_=+[{]}\\|;:'\",<.>/?")
            return rangeOfCharacter(from: characterSet) != nil
        }
}
extension Double {
    func formattedString(maxFractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = maxFractionDigits
        formatter.minimumFractionDigits = 0 
        
        let number = NSNumber(value: self)
        
        if let formattedString = formatter.string(from: number) {
            return formattedString
        } else {
            return "\(self)"
        }
    }
}

extension UIApplication {
    func endEditing() {
        guard let windowScene = connectedScenes.first as? UIWindowScene else { return }
        windowScene.windows
            .filter { $0.isKeyWindow }
            .first?
            .endEditing(true)
    }
}
