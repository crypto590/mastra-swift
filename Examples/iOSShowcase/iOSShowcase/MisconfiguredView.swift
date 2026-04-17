import SwiftUI

struct MisconfiguredView: View {
    let message: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label("Setup needed", systemImage: "gearshape.2")
                    .font(.title2.bold())

                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick start").font(.headline)
                    StepRow(n: 1, text: "cp Secrets.xcconfig.example Secrets.xcconfig")
                    StepRow(n: 2, text: "Set MASTRA_BASE_URL, MASTRA_AGENT_ID, and (optionally) MASTRA_API_KEY")
                    StepRow(n: 3, text: "Product → Clean Build Folder, then run again")
                }
                .padding()
                .background(.quaternary, in: .rect(cornerRadius: 16))

                Text("Need a Mastra server? Run `npx create-mastra@latest` and point the base URL at it.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .padding()
        }
    }
}

private struct StepRow: View {
    let n: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(n).")
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
            Text(text)
                .font(.callout.monospaced())
                .textSelection(.enabled)
        }
    }
}

#Preview {
    MisconfiguredView(message: "MASTRA_BASE_URL is not set. Copy Secrets.xcconfig.example to Secrets.xcconfig and fill it in.")
}
