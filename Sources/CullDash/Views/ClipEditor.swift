import AVKit
import SwiftUI
import CullDashCore

/// A clip with the system's playback controls, a strip of time under it, and
/// enough to cut it down: mark a stretch, cut it out or keep only it, then
/// write the result beside the original or in its place.
///
/// It starts paused, so stepping through a card full of clips stays quiet.
struct ClipEditor: View {
    let url: URL
    /// Called with the clip that should now be shown, after a replace has put
    /// a shorter file in the old one's place.
    let onReplaced: (TrashedFile) -> Void

    @State private var player = AVPlayer()
    @State private var edit = ClipEdit(duration: 0)
    @State private var selection: ClipRange?
    @State private var current = 0.0
    @State private var observer: Any?
    @State private var export: Double?
    @State private var failure: String?

    var body: some View {
        VStack(spacing: 10) {
            VideoPlayer(player: player)
                .clipShape(RoundedRectangle(cornerRadius: Theme.floatRadius))
            if edit.duration > 0 { editingStrip }
        }
        .task(id: url) { await load() }
        .onDisappear {
            player.pause()
            if let observer { player.removeTimeObserver(observer) }
            observer = nil
        }
        .alert(
            "Couldn't save the clip", isPresented: Binding(
                get: { failure != nil }, set: { if !$0 { failure = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(failure ?? "")
        }
    }

    private var editingStrip: some View {
        VStack(spacing: 8) {
            ClipTrimBar(edit: edit, current: current, selection: $selection) { seconds in
                player.seek(
                    to: CMTime(seconds: seconds, preferredTimescale: 600),
                    toleranceBefore: .zero, toleranceAfter: .zero)
            }
            HStack(spacing: 8) {
                Text(lengths).font(.system(size: 12)).foregroundStyle(Theme.subtle).monospacedDigit()
                Spacer()
                if let export {
                    ProgressView(value: export).progressViewStyle(.linear).frame(width: 120)
                    Text("Saving…").font(.system(size: 12)).foregroundStyle(Theme.subtle)
                } else {
                    actions
                }
            }
        }
    }

    /// Icons rather than words: the strip is already busy, and each one says
    /// what it does on hover.
    @ViewBuilder private var actions: some View {
        IconButton(symbol: "scissors", help: "Cut out the marked stretch and close the gap") {
            guard let marked = selection else { return }
            edit.cut(marked)
            selection = nil
        }
        .disabled(selection?.isEmpty ?? true)

        IconButton(symbol: "crop", help: "Keep only the marked stretch, trimming both ends") {
            guard let marked = selection else { return }
            edit.keepOnly(from: marked.start, to: marked.end)
            selection = nil
        }
        .disabled(selection?.isEmpty ?? true)

        IconButton(symbol: "arrow.uturn.backward", help: "Put every cut back") {
            edit.restoreEverything()
            selection = nil
        }
        .disabled(edit.isUnchanged)

        Menu {
            Button("Save as a new clip") { Task { await write(to: .newFile) } }
            Button("Replace the original…") { Task { await write(to: .replacingOriginal) } }
        } label: {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 13, weight: .medium))
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .disabled(edit.isUnchanged || edit.isEverythingCut)
        .help("Save the trimmed clip, as a new file or in the original's place")
    }

    /// "0:42.0 of 1:03.5 · 2 cuts", so the cost of the cuts is visible.
    private var lengths: String {
        var text = "\(clipTime(edit.keptDuration)) of \(clipTime(edit.duration))"
        if !edit.cuts.isEmpty { text += " · \(edit.cuts.count) cut\(edit.cuts.count == 1 ? "" : "s")" }
        return text
    }

    private func load() async {
        player.pause()
        selection = nil
        current = 0
        if let observer { player.removeTimeObserver(observer) }
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        let seconds = (try? await item.asset.load(.duration).seconds) ?? 0
        edit = ClipEdit(duration: seconds.isFinite ? seconds : 0)
        observer = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.05, preferredTimescale: 600), queue: .main
        ) { time in
            current = time.seconds
        }
    }

    private func write(to destination: ClipDestination) async {
        player.pause()
        export = 0
        defer { export = nil }
        let edit = self.edit
        let url = self.url
        do {
            let result = try await ClipExporter.export(url, edit: edit, to: destination) { fraction in
                Task { @MainActor in export = fraction }
            }
            if let trashed = result.trashedOriginal { onReplaced(trashed) }
            self.edit = ClipEdit(duration: self.edit.keptDuration)
            await load()
        } catch {
            failure = error.localizedDescription
        }
    }
}
