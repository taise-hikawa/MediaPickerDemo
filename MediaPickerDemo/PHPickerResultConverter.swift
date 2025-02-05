//
//  PHPickerResultConverter 2.swift
//  MediaPickerDemo
//
//  Created by 樋川大聖 on 2025/02/03.
//

import UIKit
import PhotosUI

enum PickerError: Error {
    case missingImage
    case missingVideo
    case imageFileTooLarge
    case videoFileTooLarge
    case unsupportedImageExtension
    case unknown
}

enum PickerContent {
    case image(UIImage)
    case video(URL)
}

class PHPickerResultConverter {
    private static let maxImageFileSize: UInt64 = 50 * 1024 * 1024
    private static let maxVideoFileSize: UInt64 = 100 * 1024 * 1024
    private static let allowedExtensions = ["jpg", "jpeg", "gif", "png", "heic"]

    static func convertToUIImage(from result: PHPickerResult) async throws -> UIImage {
        let imageType = UTType.image.identifier
        guard result.itemProvider.hasItemConformingToTypeIdentifier(imageType) else {
            throw PickerError.missingImage
        }
        let fileURL: URL = try await withCheckedThrowingContinuation { continuation in
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: imageType) { temporaryURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let temporaryURL {
                    let fileExtension = temporaryURL.pathExtension
                    let destination = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingPathComponent("\(UUID().uuidString).\(fileExtension)")
                    try! FileManager.default.copyItem(at: temporaryURL, to: destination)
                    continuation.resume(returning: destination)
                } else {
                    continuation.resume(throwing: PickerError.missingImage)
                }
            }
        }
        let ext = fileURL.pathExtension.lowercased()
        if !allowedExtensions.contains(ext) {
            throw PickerError.unsupportedImageExtension
        }
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        if let fileSize = attributes[.size] as? UInt64, fileSize > maxImageFileSize {
            throw PickerError.imageFileTooLarge
        }

        // TODO: file size calculatorを使う
        let data = try Data(contentsOf: fileURL)
        guard let image = UIImage(data: data) else {
            throw PickerError.missingImage
        }
        return image
    }

    static func convertToURL(from result: PHPickerResult) async throws -> URL {
        let movieType = UTType.movie.identifier
        guard result.itemProvider.hasItemConformingToTypeIdentifier(movieType) else {
            throw PickerError.missingVideo
        }
        let fileURL: URL = try await withCheckedThrowingContinuation { continuation in
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: movieType) { temporaryURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let temporaryURL {
                    let fileExtension = temporaryURL.pathExtension
                    let destination = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingPathComponent("\(UUID().uuidString).\(fileExtension)")
                    try! FileManager.default.copyItem(at: temporaryURL, to: destination)
                    continuation.resume(returning: destination)
                } else {
                    continuation.resume(throwing: PickerError.missingVideo)
                }
            }
        }
        // TODO: use file size calculator
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        if let fileSize = attributes[.size] as? UInt64, fileSize > maxVideoFileSize {
            throw PickerError.videoFileTooLarge
        }
        return fileURL
    }


    static func convert(from result: PHPickerResult) async throws -> PickerContent {
        if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            let videoURL = try await convertToURL(from: result)
            return .video(videoURL)
        } else if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            let image = try await convertToUIImage(from: result)
            return .image(image)
        }
        throw PickerError.unknown
    }
}
