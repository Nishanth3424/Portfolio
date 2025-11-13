//
//  VideoPickerView.swift
//  Barpath
//
//  Photo/File picker for video import
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct VideoPickerView: View {
    @Binding var selectedURL: URL?
    @Binding var isPresented: Bool
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                Image(systemName: "video.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Theme.Colors.primary)

                Text("Select a Video")
                    .font(Theme.Typography.title)

                Text("Choose a lift video from your photo library")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.inkSubtle)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)

                Spacer()

                PhotosPicker(selection: $selectedItem,
                            matching: .videos,
                            photoLibrary: .shared()) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose from Photos")
                    }
                    .font(Theme.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Theme.Colors.primary)
                    .cornerRadius(Theme.Radius.medium)
                }
                .padding(.horizontal, Theme.Spacing.md)

                Button(action: {
                    // TODO: Implement file picker
                }) {
                    HStack {
                        Image(systemName: "folder")
                        Text("Choose from Files")
                    }
                    .font(Theme.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.medium)
                            .stroke(Theme.Colors.primary, lineWidth: 2)
                    )
                }
                .padding(.horizontal, Theme.Spacing.md)

                Spacer()
            }
            .navigationTitle("Import Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onChange(of: selectedItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        // Save to temporary location
                        let tempURL = FileManager.default.temporaryDirectory
                            .appendingPathComponent(UUID().uuidString)
                            .appendingPathExtension("mp4")

                        try? data.write(to: tempURL)
                        selectedURL = tempURL
                        isPresented = false
                    }
                }
            }
        }
    }
}
