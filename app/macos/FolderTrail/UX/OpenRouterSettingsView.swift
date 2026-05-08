import SwiftUI

struct OpenRouterSettingsView: View {
    @ObservedObject var settings: OpenRouterProviderSettings
    @State private var manualKey = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OpenRouter")
                .font(.headline)

            SecureField("OpenRouter API key", text: $manualKey)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Save API Key") {
                    settings.saveManualAPIKey(manualKey)
                    manualKey = ""
                }
                .disabled(manualKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Text(settings.maskedAPIKey)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
