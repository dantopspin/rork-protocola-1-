import SwiftUI
import LocalAuthentication

struct AppLockView: View {
    let errorMessage: String?
    let isAuthenticating: Bool
    let unlock: () -> Void

    var body: some View {
        VStack(spacing: Theme.spaceXL) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.teal)
                .accessibilityHidden(true)

            VStack(spacing: Theme.spaceS) {
                Text("Protocola is locked")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.ink)

                Text(
                    "Unlock to view your local protocol records."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                unlock()
            } label: {
                if isAuthenticating {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label(
                        "Unlock Protocola",
                        systemImage: "faceid"
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.teal)
            .controlSize(.large)
            .disabled(isAuthenticating)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Theme.spaceXL)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(Theme.paper)
        .accessibilityElement(children: .contain)
    }
}
