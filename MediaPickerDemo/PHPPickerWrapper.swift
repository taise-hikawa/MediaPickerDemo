//
//  PHPPickerWrapper 2.swift
//  MediaPickerDemo
//
//  Created by 樋川大聖 on 2025/02/03.
//

import SwiftUI
import PhotosUI

struct PHPPickerWrapper: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let selectionLimit: Int
    let filter: PHPickerFilter?
    let didPick: ([PHPickerResult]) -> Void

    init(selectionLimit: Int, filter: PHPickerFilter? = nil, didPick: @escaping ([PHPickerResult]) -> Void) {
        self.selectionLimit = selectionLimit
        self.filter = filter
        self.didPick = didPick
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        if let filter {
            configuration.filter = filter
        }
        configuration.preferredAssetRepresentationMode = .current
        configuration.selectionLimit = selectionLimit
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: PHPPickerWrapper
        init(parent: PHPPickerWrapper) {
            self.parent = parent
        }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            parent.didPick(results)
        }
    }
}
