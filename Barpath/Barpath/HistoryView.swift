//
//  HistoryView.swift
//  Barpath
//
//  Session history with cards
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var historyManager: HistoryManager
    @State private var selectedSession: Session?

    var body: some View {
        NavigationStack {
            Group {
                if historyManager.sessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .navigationTitle("History")
            .navigationDestination(item: $selectedSession) { session in
                if session.analysisResults != nil {
                    ResultsView(session: session)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.inkSubtle)

            Text("No Sessions Yet")
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Colors.baseInk)

            Text("Your analyzed lifts will appear here")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.inkSubtle)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
    }

    private var sessionList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(historyManager.sessions) { session in
                    SessionCard(session: session)
                        .onTapGesture {
                            selectedSession = session
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                historyManager.deleteSession(session)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(Theme.Spacing.md)
        }
    }
}

struct SessionCard: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.liftType.rawValue)
                        .font(Theme.Typography.title)
                        .foregroundColor(Theme.Colors.baseInk)

                    Text(session.date, style: .date)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.inkSubtle)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.Colors.inkSubtle)
            }

            // Metrics (if analyzed)
            if let results = session.analysisResults {
                Divider()

                HStack(spacing: Theme.Spacing.lg) {
                    MetricBadge(
                        icon: "number",
                        label: "Reps",
                        value: "\(results.totalReps)"
                    )

                    MetricBadge(
                        icon: "arrow.up.and.down",
                        label: "Avg ROM",
                        value: String(format: "%.1f cm", results.avgRomCm)
                    )

                    MetricBadge(
                        icon: "speedometer",
                        label: "Avg Vel",
                        value: String(format: "%.2f m/s", results.avgMaxVelocity / 100)
                    )
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.baseCanvas)
        .cornerRadius(Theme.Radius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.stroke, lineWidth: 1)
        )
    }
}

struct MetricBadge: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.primary)

            Text(value)
                .font(Theme.Typography.label)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.baseInk)

            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.inkSubtle)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HistoryView()
        .environmentObject(HistoryManager())
}
