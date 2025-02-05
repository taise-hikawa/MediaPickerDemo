//
//  ContentView.swift
//  MediaPickerDemo
//
//  Created by 樋川大聖 on 2025/02/03.
//
import Foundation
import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct ContentView: View {
    private enum Sheet: Identifiable {
        case videos
        case imagesAndVideos
        case image
        var id: String {
            switch self {
            case .videos:
                return "videos"
            case .imagesAndVideos:
                return "imagesAndVideos"
            case .image:
                return "image"
            }
        }
    }

    @State private var selectedSheet: Sheet?
    var body: some View {
        VStack(spacing: 24) {
            Button {
                selectedSheet = .videos
            } label: {
                Text("動画複数選択")
            }

            Button {
                selectedSheet = .imagesAndVideos
            } label: {
                Text("画像&動画複数選択")
            }

            Button {
                selectedSheet = .image
            } label: {
                Text("画像単数選択")
            }
        }
        .buttonStyle(.bordered)
        .sheet(item: $selectedSheet) { sheet in
            switch sheet {
            case .videos:
                PHPPickerWrapper(selectionLimit: 100, filter: .videos) { results in
                    Task {
                        let start = Date()
                        await handle(results: results)
                        print("Time: \(Date().timeIntervalSince(start))")
                    }
                }
            case .imagesAndVideos:
                PHPPickerWrapper(selectionLimit: 5) { results in
                    print(results)
                }
            case .image:
                PHPPickerWrapper(selectionLimit: 1, filter: .images) { results in
                    guard let result = results.first else { return }
                    print(result)
                }
            }
        }
    }
}

extension ContentView {
    private func handle(results: [PHPickerResult]) async {
        var urls = [URL]()
        var errors = [Error]()

        await withTaskGroup(of: (Int, Result<URL, Error>).self) { group in
            for (index, result) in results.enumerated() {
                group.addTask {
                    do {
                        let url = try await MediaItemConverter.convertToURL(from: result.itemProvider)
                        return (index, .success(url))
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }
            for await (index, conversionResult) in group {
                switch conversionResult {
                case .success(let url):
                    print(url)
                    urls.append(url)
                case .failure(let error):
                    errors.append(error)
                }
                print("\(index)/ \(results.count)")
            }
        }

        print("URLs: \(urls)")
        print("Errors: \(errors)")
    }

    private func handleSerial(results: [PHPickerResult]) async {
        for result in results {
            do {
                let url = try await MediaItemConverter.convertToURL(from: result.itemProvider)
                print(url)
            } catch {
                print("🍎", error)
            }
        }
    }
}

#Preview {
    ContentView()
}

extension PHPickerResult: @unchecked @retroactive Sendable {}
