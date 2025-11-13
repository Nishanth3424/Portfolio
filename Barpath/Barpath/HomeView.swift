//
//  HomeView.swift
//  Barpath
//
//  Welcome / Safety screen with action buttons
//

import SwiftUI
import PhotosUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var historyManager: HistoryManager
    @State private var showVideoPicker = false
    @State private var showCamera = false
    @State private var selectedVideoURL: URL?
    @State private var navigateToCalibration = false

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                // Logo / Title
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 64))
                        .foregroundColor(Theme.Colors.primary)

                    Text("Barpath")
                        .font(Theme.Typography.display)
                        .foregroundColor(Theme.Colors.baseInk)

                    Text("Track your barbell movement")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.inkSubtle)
                }

                Spacer()

                // Safety Notice
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Theme.Colors.warning)
                        Text("Safety First")
                            .font(Theme.Typography.label)
                            .fontWeight(.semibold)
                    }

                    Text("Film from the side (sagittal view) with stable phone position. Ensure barbell plates and body are clearly visible.")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.inkSubtle)
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.fill)
                .cornerRadius(Theme.Radius.medium)
                .padding(.horizontal, Theme.Spacing.md)

                // Action Buttons
                VStack(spacing: Theme.Spacing.md) {
                    Button(action: {
                        showVideoPicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Analyze Video")
                        }
                        .font(Theme.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Theme.Colors.primary)
                        .cornerRadius(Theme.Radius.medium)
                    }

                    Button(action: {
                        showCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Record & Analyze")
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
                }
                .padding(.horizontal, Theme.Spacing.md)

                Spacer()
            }
            .navigationDestination(isPresented: $navigateToCalibration) {
                if let videoURL = selectedVideoURL {
                    CalibrationView(videoURL: videoURL, isRecorded: false)
                }
            }
            .sheet(isPresented: $showVideoPicker) {
                VideoPickerView(selectedURL: $selectedVideoURL, isPresented: $showVideoPicker)
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureView(isPresented: $showCamera, onVideoRecorded: { url in
                    selectedVideoURL = url
                    navigateToCalibration = true
                })
            }
            .onChange(of: selectedVideoURL) { oldValue, newValue in
                if newValue != nil {
                    navigateToCalibration = true
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
        .environmentObject(HistoryManager())
}
