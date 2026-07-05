//
//  SearchSheet.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI
import MapKit

struct SearchSheet: View {
    let center: CLLocationCoordinate2D
    @Binding var bookmarks: Set<String>
    let onSelect: (PlaceResult) -> Void
    
    @StateObject private var vm = SearchViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Indicator Tiruan (Khas Sheet iOS)
            Capsule()
                .fill(Color(UIColor.systemGray4))
                .frame(width: 40, height: 4)
                .padding(.top, 10)
            
            // Search Bar Asli di dalam Sheet
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundColor(Theme.textSecondary)
                
                TextField("Search a location", text: $vm.query)
                    .focused($isFieldFocused)
                    .font(Theme.Typography.section)
                    .submitLabel(.search)
                    .onSubmit {
                        vm.runSearch(around: center)
                    }
                
                if vm.isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "mic.fill").foregroundColor(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 10)

            // Handling Error
            if let errorMessage = vm.errorMessage {
                Text(errorMessage)
                    .font(Theme.Typography.subtitle)
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
            }

            // List Hasil Pencarian
            if vm.results.isEmpty {
                List(vm.completer.suggestions, id: \.self) { suggestion in
                    Button {
                        vm.runSearch(completion: suggestion, center: center)
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .font(.title2)
                                .foregroundColor(Theme.textSecondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.title)
                                    .font(Theme.Typography.section)
                                    .foregroundColor(Theme.textPrimary)
                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle)
                                        .font(Theme.Typography.subtitle)
                                        .foregroundColor(Theme.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            } else {
                List(vm.results) { place in
                    SearchResultRow(
                        place: place,
                        isBookmarked: bookmarks.contains(place.name),
                        onBookmark: { vm.toggleBookmark(for: place, in: &bookmarks) },
                        onTap: { onSelect(place) }
                    )
                    .listRowSeparator(.hidden) // Membuang garis separator bawaan Apple agar lebih clean
                }
                .listStyle(.plain)
            }
        }
        .background(Theme.cardBackground.ignoresSafeArea()) // Menggunakan abu-abu muda khas iOS
        .onAppear { isFieldFocused = true }
        .onChange(of: vm.query) { _, _ in
            vm.updateQuery(around: center)
        }
    }
}

// MARK: - Row Hasil Pencarian (Sesuai iPhone 2)
struct SearchResultRow: View {
    let place: PlaceResult
    let isBookmarked: Bool
    let onBookmark: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Komponen Kiri: Pin & Jarak
            VStack(spacing: 4) {
                CustomPinMarker()
                    .padding(.top, 4)
                
                if let distance = place.distanceLabel {
                    Text(distance)
                        .font(Theme.Typography.subtitle)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .frame(width: 45) // Lebar tetap agar sejajar

            // Komponen Tengah: Teks
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(Theme.Typography.section)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                
                Text(place.subtitle)
                    .font(Theme.Typography.category)
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(2) // Sesuai desain, subtitle bisa cukup panjang
            }
            .padding(.top, 2)
            
            Spacer()
            
            // Komponen Kanan: Bookmark
            Button(action: onBookmark) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.primary)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .padding(.vertical, 12)
        // Menambahkan separator manual yang lebih rapi di bawah row
        .overlay(
            Rectangle()
                .fill(Color(UIColor.separator).opacity(0.5))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

#Preview("Search Sheet") {
    SearchSheet(
        center: CLLocationCoordinate2D(latitude: -8.65, longitude: 115.16),
        bookmarks: .constant([]),
        onSelect: { _ in }
    )
}

#Preview("Search Row") {
    SearchResultRow(
        place: PlaceResult(
            name: "Kuta",
            subtitle: "Kabupaten Badung, Bali, Indonesia",
            latitude: -8.7263,
            longitude: 115.1776,
            distanceKm: 1.7
        ),
        isBookmarked: true,
        onBookmark: {},
        onTap: {}
    )
    .padding()
}
