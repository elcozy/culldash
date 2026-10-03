import AVKit
import SwiftUI
import CullDashCore

/// A clip with the system's playback controls, a strip of time under it, and
/// enough to cut it down: mark a stretch, cut it out or keep only it, then
/// write the result beside the original or in its place.
///
/// It starts paused, so stepping through a card full of clips stays quiet.
struct ClipEditor: View {
    @Environment(LibraryStore.self) private var store
    let url: URL

    @State private var player = AVPlayer()
    @State private var edit = ClipEdit(duration: 0)
    @State private var selection: ClipRange?
    @State private var current = 0.0
    @State private var observer: Any?
    @State private var export: Double?
    @State private var failure: String?
    /// The strip stays out of the way until trimming is asked for: most clips
    /// are only watched, and a shoot is flicked through one key at a time.
    @State private var editing = false

    var body: some View {
        VStack(spacing: 10) {
            VideoPlayer(player: player)
                .clipShape(RoundedRectangle(cornerRadius: Theme.floatRadius))
            if edit.duration > 0 {
                if editing { editingStrip } else { trimEntry }
            }
        }
        .task(id: url) { await load() }
        // Space reaches the player through the store, since the player is
        // this view's own and the keys are read from the window.
        .onChange(of: store.clipPlaybackToggles) { togglePlayback() }
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

    /// What is on screen until trimming starts: the clip's length, and the one
    /// button that brings the strip out.
    private var trimEntry: some View {
        HStack(spacing: 8) {
            Text(clipTime(edit.duration))
                .font(.system(size: 12)).foregroundStyle(Theme.subtle).monospacedDigit()
            Spacer()
            IconButton(symbol: "pencil", help: "Edit this clip: trim it, or cut sections out") {
                player.pause()
                editing = true
            }
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
        let marked = !(selection?.isEmpty ?? true)

        IconButton(
            symbol: "scissors",
            help: marked
                ? "Cut out the marked stretch and close the gap"
                : "Drag across the strip to mark a stretch, then cut it out",
            enabled: marked
        ) {
            guard let selection else { return }
            edit.cut(selection)
            self.selection = nil
        }

        IconButton(
            symbol: "crop",
            help: marked
                ? "Keep only the marked stretch, trimming both ends"
                : "Drag across the strip to mark a stretch, then keep only it",
            enabled: marked
        ) {
            guard let selection else { return }
            edit.keepOnly(from: selection.start, to: selection.end)
            self.selection = nil
        }

        IconButton(
            symbol: "arrow.uturn.backward", help: "Put every cut back",
            enabled: !edit.isUnchanged
        ) {
            edit.restoreEverything()
            selection = nil
        }

        IconButton(symbol: "xmark", help: "Stop editing and put every cut back") {
            edit.restoreEverything()
            selection = nil
            editing = false
        }

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
        .opacity(edit.isUnchanged || edit.isEverythingCut ? 0.35 : 1)
        .help(
            edit.isUnchanged
                ? "Cut something out first, then save it"
                : "Save the edited clip, as a new file or in the original's place")
    }

    /// "0:42.0 of 1:03.5 · 2 cuts", so the cost of the cuts is visible.
    private var lengths: String {
        var text = "\(clipTime(edit.keptDuration)) of \(clipTime(edit.duration))"
        if !edit.cuts.isEmpty { text += " · \(edit.cuts.count) cut\(edit.cuts.count == 1 ? "" : "s")" }
        return text
    }

    /// Space on a clip: play if it is paused, pause if it is running.
    private func togglePlayback() {
        if player.timeControlStatus == .paused { player.play() } else { player.pause() }
    }

    private func load() async {
        player.pause()
        selection = nil
        editing = false
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
        do {
            let result = try await ClipExporter.export(url, edit: edit, to: destination) { fraction in
                Task { @MainActor in export = fraction }
            }
            if let trashed = result.trashedOriginal {
                store.noteReplacedClip(trashed)
            } else {
                // Saved beside the original: the shoot has to be told, or the
                // new clip exists only on the card until the folder is
                // re-opened.
                store.noteNewClip(at: result.url, from: url)
            }
            await load()
        } catch {
            failure = error.localizedDescription
        }
    }
}
