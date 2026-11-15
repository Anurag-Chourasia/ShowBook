//
//  StoreLoadErrorRecoveryView.swift
//  ShowBook
//

import SwiftUI
import DesignTokensKit
import LocalizationKit

/// Present recoverable store-load failures without automatic data deletion.
struct StoreLoadErrorRecoveryView: View {
    let error: Error
    var localization: LocalizationProviding = LocalizationController(initialLocale: .current)
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: \.sixteen) {
            Image(\.exclamationmarkTriangleFill)
                .foregroundColor(\.yellow)
            Text(\.errorsStoreLoadFailed)
                .font(\.headline)
                .foregroundColor(\.primary)
            Text(\.errorsStoreLoadMessage)
                .font(\.subheadline)
                .foregroundColor(\.secondary)
                .multilineTextAlignment(.center)
            Button(\.retry) {
                retryAction()
            }
            .buttonStyle(.borderedProminent)
            .tint(\.primary)
        }
        .padding(.horizontal, \.p34)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(\.grouped)
        .environment(\.layoutDirection, localization.isRightToLeft ? .rightToLeft : .leftToRight)
    }
}
