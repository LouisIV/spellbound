import SwiftUI

struct HomeView: View {
    @ObservedObject var model: PrototypeModel
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top) {
                Image(systemName: "character.cursor.ibeam").font(.system(size: 32)).foregroundStyle(.mint)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Catch the typo. Keep the word.").font(.title2.weight(.semibold))
                    Text("A tiny spelling exercise, right above the word you’re typing.")
                        .foregroundStyle(.secondary)
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 10) {
                Text("Try it here first").font(.headline)
                Text("Type a misspelling in the playground. Choose the correction, type it once with a cue, then twice from memory.")
                    .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Button("Open typing playground") { model.showPlayground() }
                    .buttonStyle(.borderedProminent).tint(.mint).controlSize(.large)
                    .keyboardShortcut("p", modifiers: .command)
            }
            Divider()
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Use it in other apps").font(.headline)
                    Spacer()
                    Toggle("Enable monitoring", isOn: Binding(get: { model.monitoring }, set: model.setMonitoring))
                        .toggleStyle(.switch).labelsHidden().help("Enable monitoring across supported inputs")
                }
                Text(model.status).foregroundStyle(.secondary)
                if !model.permissionGranted {
                    Button("Allow Accessibility access…") { model.openAccessibilitySettings() }
                    Text("One setup for all apps. Processing stays on your Mac; input text is never saved.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Follows focused text inputs automatically. Password fields and unsupported inputs are skipped.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            HStack {
                Text("\(model.practicedCount) words practiced").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Menu("Preferences") {
                    Button("Clear learned vocabulary (\(model.ignoredWords.count))") { model.clearVocabulary() }
                    Button("Clear app exclusions (\(model.excludedApps.count))") { model.clearExclusions() }
                }.fixedSize()
            }
        }
        .padding(30).frame(width: 600, height: 490)
    }
}
