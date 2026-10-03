import AVKit
import SwiftUI
import CullDashCore

/// A clip with the system's playback controls, and, once the pencil is
/// pressed, a row of pieces under it to cut it down with.
///
/// Editing works the way it does in a video editor: scrub to a moment, split
/// there, pick a piece and drop it. What is left closes up, and the player
/// shows the result rather than the original file, so the playhead and the row
/// never come to mean different things.
///
/// It starts paused, so stepping through a card full of clips stays quiet.
struct ClipEditor: View {
    @Environment(LibraryStore.self) private var store
    let url: URL

    @State private var player = AVPlayer()
    @State private var edit = ClipEdit(duration: 0)
    /// Which piece is picked, if any.
    @State private var selected: Int?
    /// The playhead, in output seconds.
    @State private var current = 0.0
    @State private var observer: Any?
    @State private var export: Double?
    @State private var failure: String?
    /// The row stays out of the way until editing is asked for: most clips are
    /// only watched, and a shoot is flicked through one key at a time.
    @State private var editing = false

    var body: some View {
        VStack(spacing: 10) {
            VideoPlayer(player: player)
                .clipShape(RoundedRectangle(cornerRadius: Theme.floatRadius))
            if edit.duration > 0 {
                if editing { editingStrip } else { entry }
            }
        }
        .task(id: url) { await load() }
        // Space reaches the player through the store, since the player is
        // this view's own and the keys are read from the window.
        .onChange(of: store.clipPlaybackToggles) { togglePlayback() }
        .alert(
            "Couldn't save the clip", isPresented: Binding(
                get: { failure != nil }, set: { if !$0 { failure = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(failure ?? "")
        }
    }

    /// Before editing starts: the clip's length, and the way in.
    private var entry: some View {
        HStack(spacing: 8) {
            Text(clipTime(edit.duration))
                .font(.system(size: 12)).foregroundStyle(Theme.subtle).monospacedDigit()
            Spacer()
            IconButton(symbol: "pencil", help: "Edit this clip: split it and drop what you don't want") {
                player.pause()
                editing = true
            }
        }
    }

    private var editingStrip: some View {
        VStack(spacing: 8) {
            ClipTrimBar(edit: edit, current: current, selected: $selected) { seconds in
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

    @ViewBuilder private var actions: some View {
        IconButton(symbol: "scissors", help: "Split the clip at the playhead") {
            if edit.split(atOutput: current) { selected = nil }
        }

        IconButton(
            symbol: "trash",
            help: selected == nil
                ? "Click a piece on the row, then drop it here"
                : "Drop this piece; what is left closes up",
            enabled: selected != nil
        ) {
            guard let piece = selected else { return }
            // Land where the dropped piece was, which is where the join now is.
            let landing = edit.outputStart(of: piece)
            edit.remove(at: piece)
            selected = nil
            Task { await showEdit(seekingTo: landing) }
        }

        IconButton(
            symbol: "arrow.uturn.backward", help: "Put the whole clip back",
            enabled: !edit.isUnchanged || edit.pieces.count > 1
        ) {
            edit.restoreEverything()
            selected = nil
            Task { await showEdit(seekingTo: current) }
        }

        IconButton(symbol: "xmark", help: "Stop editing and put the whole clip back") {
            edit.restoreEverything()
            selected = nil
            editing = false
            Task { await showEdit(seekingTo: current) }
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
                ? "Drop a piece first, then save what is left"
                : "Save the edited clip, as a new file or in the original's place")
    }

    /// "0:42.0 of 1:03.5 · 3 pieces", so the cost of the cuts is visible.
    private var lengths: String {
        var text = "\(clipTime(edit.keptDuration)) of \(clipTime(edit.duration))"
        if edit.pieces.count > 1 { text += " · \(edit.pieces.count) pieces" }
        return text
    }

    /// Space on a clip: play if it is paused, pause if it is running.
    private func togglePlayback() {
        if player.timeControlStatus == .paused { player.play() } else { player.pause() }
    }

    private func load() async {
        player.pause()
        selected = nil
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

    /// Plays the pieces rather than the file, so dropping one is seen at once
    /// and the playhead keeps meaning a moment of what is left.
    private func showEdit(seekingTo seconds: Double) async {
        guard !edit.isEverythingCut else {
            player.replaceCurrentItem(with: nil)
            return
        }
        let playing = player.timeControlStatus == .playing
        guard let preview = try? await ClipExporter.preview(of: url, edit: edit) else { return }
        player.replaceCurrentItem(with: AVPlayerItem(asset: preview))
        await player.seek(
            to: CMTime(seconds: min(seconds, edit.keptDuration), preferredTimescale: 600),
            toleranceBefore: .zero, toleranceAfter: .zero)
        if playing { player.play() }
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
