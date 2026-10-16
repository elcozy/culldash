import AVFoundation
import Foundation

/// Where an edited clip should land.
public enum ClipDestination: Sendable {
    /// `IMG_0305-trimmed.MOV` beside the original, which is left alone.
    case newFile
    /// Takes the original's place. The original goes to that drive's Trash
    /// rather than being deleted, so a wrong cut is still recoverable.
    case replacingOriginal
}

public enum ClipExportError: Error, LocalizedError {
    case nothingToExport
    case everythingCut
    case noTracks
    case exportFailed(String)

    public var errorDescription: String? {
        switch self {
        case .nothingToExport: "Nothing was cut, so there is nothing to write."
        case .everythingCut: "The whole clip is cut. Keep at least one section."
        case .noTracks: "This clip has no video or audio track that can be copied."
        case .exportFailed(let why): why
        }
    }
}

/// What came of an export, so the app can tell the user and undo it.
public struct ClipExportResult: Sendable {
    public let url: URL
    /// The original, when it was moved aside to make room for the edit.
    public let trashedOriginal: TrashedFile?
}

/// Writes a trimmed clip out by copying the parts kept, never re-encoding.
///
/// The streams are copied as they are, so a 4K clip is written in about the
/// time it takes to read it and comes out identical to the source. The cost of
/// not re-encoding is that cuts land on the nearest keyframe before the mark,
/// which on long-GOP footage can be a second or so earlier than the handle was
/// dropped. That is the usual trade, and the one QuickTime makes too.
public enum ClipExporter {
    public static func export(
        _ url: URL, edit: ClipEdit, to destination: ClipDestination,
        progress: (@Sendable (Double) -> Void)? = nil
    ) async throws -> ClipExportResult {
        guard !edit.isUnchanged else { throw ClipExportError.nothingToExport }
        guard !edit.isEverythingCut else { throw ClipExportError.everythingCut }

        let composition = try await composition(of: url, keeping: edit.kept)
        let target = workingFile(for: url)
        try? FileManager.default.removeItem(at: target)

        guard
            let session = AVAssetExportSession(
                asset: composition, presetName: AVAssetExportPresetPassthrough)
        else { throw ClipExportError.exportFailed("This clip cannot be copied without re-encoding.") }

        do {
            try await run(session, to: target, as: fileType(for: url), progress: progress)
        } catch {
            try? FileManager.default.removeItem(at: target)
            throw ClipExportError.exportFailed(error.localizedDescription)
        }

        return try place(target, from: url, to: destination)
    }

    /// Runs the export, reporting progress as it goes. macOS 15 added a
    /// throwing export and a stream of states; macOS 14, which the app still
    /// supports, only has the older call, whose progress has to be polled.
    private static func run(
        _ session: AVAssetExportSession, to target: URL, as type: AVFileType,
        progress: (@Sendable (Double) -> Void)?
    ) async throws {
        if #available(macOS 15, *) {
            let watcher = progress.map { report in
                Task.detached {
                    for await state in session.states(updateInterval: 0.2) {
                        if case .exporting(let fraction) = state { report(fraction.fractionCompleted) }
                    }
                }
            }
            defer { watcher?.cancel() }
            try await session.export(to: target, as: type)
        } else {
            session.outputURL = target
            session.outputFileType = type
            let watcher = progress.map { report in
                Task.detached {
                    while !Task.isCancelled {
                        report(Double(session.progress))
                        try? await Task.sleep(for: .milliseconds(200))
                    }
                }
            }
            defer { watcher?.cancel() }
            await session.export()
            if let error = session.error { throw error }
            guard session.status == .completed else { throw CancellationError() }
        }
    }

    /// The pieces laid end to end, for playing the edit back before it is
    /// written. The player's own clock then runs in output time, which is what
    /// the strip draws, so the playhead and the row cannot drift apart.
    public static func preview(of url: URL, edit: ClipEdit) async throws -> AVComposition {
        guard !edit.isEverythingCut else { throw ClipExportError.everythingCut }
        return try await composition(of: url, keeping: edit.kept)
    }

    /// The kept parts laid end to end, each track copied across.
    private static func composition(of url: URL, keeping kept: [ClipRange]) async throws -> AVComposition {
        let asset = AVURLAsset(url: url)
        let composition = AVMutableComposition()
        let sources = try await asset.loadTracks(withMediaType: .video)
            + asset.loadTracks(withMediaType: .audio)
        guard !sources.isEmpty else { throw ClipExportError.noTracks }

        // One track in the composition per track in the clip, so video and
        // audio stay in step across every cut.
        for source in sources {
            guard
                let track = composition.addMutableTrack(
                    withMediaType: source.mediaType, preferredTrackID: kCMPersistentTrackID_Invalid)
            else { continue }
            track.preferredTransform = try await source.load(.preferredTransform)
            var at = CMTime.zero
            for range in kept {
                let span = CMTimeRange(
                    start: CMTime(seconds: range.start, preferredTimescale: 600),
                    duration: CMTime(seconds: range.duration, preferredTimescale: 600))
                try track.insertTimeRange(span, of: source, at: at)
                at = CMTimeAdd(at, span.duration)
            }
        }
        return composition
    }

    /// Written beside the original first, whatever the destination, so a
    /// failure half way through cannot leave the only copy damaged.
    private static func workingFile(for url: URL) -> URL {
        let name = url.deletingPathExtension().lastPathComponent
        return url.deletingLastPathComponent()
            .appendingPathComponent("\(name)-trimmed")
            .appendingPathExtension(url.pathExtension)
    }

    private static func place(
        _ written: URL, from original: URL, to destination: ClipDestination
    ) throws -> ClipExportResult {
        switch destination {
        case .newFile:
            return ClipExportResult(url: written, trashedOriginal: nil)
        case .replacingOriginal:
            // Trash first, then move into the gap: the edit only becomes the
            // original once the original is safely aside.
            let trashed = try PhotoTrash.trash(original)
            try FileManager.default.moveItem(at: written, to: original)
            return ClipExportResult(url: original, trashedOriginal: trashed)
        }
    }

    private static func fileType(for url: URL) -> AVFileType {
        switch url.pathExtension.lowercased() {
        case "mov": .mov
        case "m4v": .m4v
        default: .mp4
        }
    }
}
