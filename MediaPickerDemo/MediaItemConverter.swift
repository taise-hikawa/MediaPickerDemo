//
//  PHPickerResultConverter 2.swift
//  MediaPickerDemo
//
//  Created by 樋川大聖 on 2025/02/03.
//

import UIKit
import UniformTypeIdentifiers

enum MediaConvertError: Error {
    case missingImage
    case missingVideo
    case imageFileTooLarge
    case videoFileTooLarge
    case unsupportedImageExtension
    case unknown
}

enum MediaContent {
    case image(UIImage)
    case video(URL)
}

class MediaItemConverter {
    private static let maxImageFileSize: UInt64 = 50 * 1024 * 1024
    private static let maxVideoFileSize: UInt64 = 100 * 1024 * 1024
    private static let allowedExtensions = ["jpg", "jpeg", "gif", "png", "heic"]

    static func convertToUIImage(from itemProvider: NSItemProvider) async throws -> UIImage {
        let imageType = UTType.image.identifier
        guard itemProvider.hasItemConformingToTypeIdentifier(imageType) else {
            throw MediaConvertError.missingImage
        }
        let fileURL: URL = try await withCheckedThrowingContinuation { continuation in
            itemProvider.loadFileRepresentation(forTypeIdentifier: imageType) { temporaryURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let temporaryURL {
                    let fileExtension = temporaryURL.pathExtension
                    let destination = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingPathComponent("\(UUID().uuidString).\(fileExtension)")
                    try! FileManager.default.copyItem(at: temporaryURL, to: destination)
                    continuation.resume(returning: destination)
                } else {
                    continuation.resume(throwing: MediaConvertError.missingImage)
                }
            }
        }
        let ext = fileURL.pathExtension.lowercased()
        if !allowedExtensions.contains(ext) {
            throw MediaConvertError.unsupportedImageExtension
        }
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        if let fileSize = attributes[.size] as? UInt64, fileSize > maxImageFileSize {
            throw MediaConvertError.imageFileTooLarge
        }

        // TODO: file size calculatorを使う
        let data = try Data(contentsOf: fileURL)
        guard let image = UIImage(data: data) else {
            throw MediaConvertError.missingImage
        }
        return image
    }

    static func convertToURL(from itemProvider: NSItemProvider) async throws -> URL {
        let movieType = UTType.movie.identifier
        guard itemProvider.hasItemConformingToTypeIdentifier(movieType) else {
            throw MediaConvertError.missingVideo
        }
        let fileURL: URL = try await withCheckedThrowingContinuation { continuation in
            itemProvider.loadFileRepresentation(forTypeIdentifier: movieType) { temporaryURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let temporaryURL {
                    let fileExtension = temporaryURL.pathExtension
                    let destination = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingPathComponent("\(UUID().uuidString).\(fileExtension)")
                    try! FileManager.default.copyItem(at: temporaryURL, to: destination)
                    continuation.resume(returning: destination)
                } else {
                    continuation.resume(throwing: MediaConvertError.missingVideo)
                }
            }
        }
        // TODO: use file size calculator
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        if let fileSize = attributes[.size] as? UInt64, fileSize > maxVideoFileSize {
            throw MediaConvertError.videoFileTooLarge
        }
        return fileURL
    }


    static func convert(from itemProvider: NSItemProvider) async throws -> MediaContent {
        if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            let videoURL = try await convertToURL(from: itemProvider)
            return .video(videoURL)
        } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            let image = try await convertToUIImage(from: itemProvider)
            return .image(image)
        }
        throw MediaConvertError.unknown
    }
}
