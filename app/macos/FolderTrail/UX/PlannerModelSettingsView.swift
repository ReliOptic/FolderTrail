import SwiftUI

struct PlannerModelSettingsView: View {
    @ObservedObject var settings: PlannerModelSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Planner Model")
                .font(.headline)

            Picker("Curated model", selection: $settings.selectedModel) {
                ForEach(PlannerModelSettings.curatedModels, id: \.self) { model in
                    Text(model).tag(model)
                }
            }

            TextField("Custom OpenRouter model", text: $settings.customModel)
                .textFieldStyle(.roundedBorder)

            Text("Using: \(settings.effectiveModel)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
