import SwiftUI

struct AIWorkspaceView: View {
    @Environment(AppState.self) private var app
    @State private var prompt: String = "laravel"
    @State private var isThinking: Bool = false
    @State private var plan: AIPlanResponse?
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("AI Workspace")
                    .font(.largeTitle.weight(.semibold))
                Text("Describe your stack. We'll draft a workspace you can review before saving.")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            HStack {
                Image(systemName: "sparkles").foregroundStyle(.secondary)
                TextField("e.g. laravel, nextjs, data-science", text: $prompt)
                    .textFieldStyle(.plain)
                    .font(.title3)
                Button {
                    Task { await runPlan() }
                } label: {
                    if isThinking { ProgressView().controlSize(.small) }
                    else { Label("Draft plan", systemImage: "wand.and.stars") }
                }
                .buttonStyle(.borderedProminent)
                .disabled(prompt.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(12)
            .background(.thinMaterial, in: .rect(cornerRadius: 12))
            .padding(.horizontal, 24)

            if let error {
                Text(error).foregroundStyle(.red).padding(.horizontal, 24)
            }

            if let plan {
                planPreview(plan)
            } else if !app.ai.isConfigured {
                unconfiguredCallout
            } else {
                Spacer()
            }
        }
    }

    // MARK: -

    private var unconfiguredCallout: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Workspace is off").font(.headline)
            Text("Enable it in Settings → AI to point at the ProfilePilot companion API or your own LLM endpoint.")
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(.thinMaterial, in: .rect(cornerRadius: 12))
        .padding(.horizontal, 24)
    }

    private func planPreview(_ plan: AIPlanResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: plan.symbol).font(.title2)
                Text(plan.name).font(.title2.weight(.semibold))
                Spacer()
                Button("Save workspace") {
                    let ws = app.ai.materialise(plan)
                    app.addWorkspace(ws)
                    self.plan = nil
                }
                .buttonStyle(.borderedProminent)
            }
            ForEach(plan.items.indices, id: \.self) { i in
                let it = plan.items[i]
                HStack {
                    Image(systemName: symbol(for: it.kind)).frame(width: 20)
                    VStack(alignment: .leading) {
                        Text(it.value).lineLimit(1)
                        if let note = it.note {
                            Text(note).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text("\(it.delayMs ?? 0) ms")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(.thinMaterial, in: .rect(cornerRadius: 8))
            }
        }
        .padding(24)
    }

    private func symbol(for kind: String) -> String {
        switch kind {
        case "browserProfile": return "person.crop.circle"
        case "app": return "app.fill"
        case "url": return "link"
        case "shell": return "terminal.fill"
        default: return "questionmark"
        }
    }

    private func runPlan() async {
        error = nil
        isThinking = true
        defer { isThinking = false }
        do {
            plan = try await app.ai.plan(prompt: prompt)
        } catch let e {
            error = e.localizedDescription
        }
    }
}
