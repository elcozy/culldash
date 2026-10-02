import CoreGraphics
import Foundation
import Vision

/// Measures how alike two photos look, with Apple's on-device Vision
/// feature prints. Nothing leaves the Mac.
public enum SimilarityPrints {
    /// A compact description of what a picture shows; small previews are enough.
    public static func featurePrint(of image: CGImage) -> VNFeaturePrintObservation? {
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: image)
        try? handler.perform([request])
        return request.results?.first
    }

    /// 0 for the same picture; larger the more two pictures differ.
    public static func distance(_ a: VNFeaturePrintObservation, _ b: VNFeaturePrintObservation) -> Float? {
        var value: Float = 0
        guard (try? a.computeDistance(&value, to: b)) != nil else { return nil }
        return value
    }

    /// Groups a shoot into bursts, reporting progress from 0 to 1. Uses the
    /// capture time from EXIF, or the file date when a photo has none.
    public static func bursts(
        in photos: [Photo], rules: BurstRules = .standard, progress: (Double) -> Void = { _ in }
    ) -> [[URL]] {
        let frames = photos.map { BurstGrouper.Frame(id: $0.id, time: ExposureInfo.read($0.primary).captured ?? $0.modified) }
            .sorted { $0.time < $1.time }
        var prints: [Int: VNFeaturePrintObservation] = [:]
        func print(_ index: Int) -> VNFeaturePrintObservation? {
            if let cached = prints[index] { return cached }
            let image = PreviewLoader.shared.preview(for: frames[index].id, maxPixels: 400)
            let made = image.flatMap(featurePrint)
            prints[index] = made
            return made
        }
        return BurstGrouper.group(frames, rules: rules) { index in
            progress(Double(index) / Double(max(frames.count - 1, 1)))
            prints[index - 2] = nil  // only neighbours are compared, so older prints can go
            guard let a = print(index - 1), let b = print(index) else { return nil }
            return distance(a, b)
        }
    }
}
