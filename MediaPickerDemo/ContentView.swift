//
//  ContentView.swift
//  MediaPickerDemo
//
//  Created by 樋川大聖 on 2025/02/03.
//

import SwiftUI

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
                PHPPickerWrapper(selectionLimit: 5, filter: .videos) { results in
                    print(results)
                }
            case .imagesAndVideos:
                PHPPickerWrapper(selectionLimit: 5) { results in
                    print(results)
                }
            case .image:
                PHPPickerWrapper(selectionLimit: 1, filter: .images) { results in
                    print(results)
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
