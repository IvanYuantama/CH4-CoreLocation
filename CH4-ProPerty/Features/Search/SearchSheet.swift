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
    let onSelect: (PlaceResult) -> Void
    
    @StateObject private var vm = SearchViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Search Bar Custom
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundColor(Color(.textSecondary))
                
                TextField("Search a location", text: $vm.query)
                    .focused($isFieldFocused)
                    .font(.body)
                    .textCase(nil)
                    .textInputAutocapitalization(.never) // Mengikuti status asli tombol caps lock keyboard user
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                
                if vm.isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "mic.fill").foregroundColor(Color(.textSecondary))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color(UIColor.systemBackground))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 10)

            if let errorMessage = vm.errorMessage {
                Text(errorMessage)
                    .font(Theme.Typography.subtitle)
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }

            // MARK: - List Tampilan Lokasi (Clean Style)
            List {
                if vm.query.isEmpty {
                    // Menampilkan daftar bookmark secara bersih jika kolom pencarian kosong
                    ForEach(vm.savedPlaces) { place in
                        SearchResultRow(
                            place: place,
                            isBookmarked: true,
                            onBookmark: { vm.toggleBookmark(for: place) },
                            onTap: { onSelect(place) }
                        )
                        .listRowSeparator(.hidden)
                    }
                } else {
                    // Menampilkan hasil pencarian fuzzy sedunia yang diurutkan kombinasi relevansi & jarak
                    ForEach(vm.results) { place in
                        SearchResultRow(
                            place: place,
                            isBookmarked: vm.isBookmarked(place),
                            onBookmark: { vm.toggleBookmark(for: place) },
                            onTap: { onSelect(place) }
                        )
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
        }
        .padding(.top, 10)
        .background(Color(.cardBackground).ignoresSafeArea())
        .onAppear {
            isFieldFocused = true
            vm.setCenter(center)
        }
    }
}

// MARK: - Row Hasil Pencarian Custom Pin Marker & Jarak
struct SearchResultRow: View {
    let place: PlaceResult
    let isBookmarked: Bool
    let onBookmark: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                CustomPinMarker()
                
                if let distance = place.distanceLabel {
                    Text(distance)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(.textSecondary))
                        .padding(.top, 4)
                        .fixedSize()
                }
            }
            .frame(width: 45)

            // MARK: Komponen Tengah: Teks Informasi Alamat
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(Theme.Typography.section)
                    .foregroundColor(Color(.textPrimary))
                    .lineLimit(1)
                
                Text(place.subtitle)
                    .font(Theme.Typography.subtitle)
                    .foregroundColor(Color(.textSecondary))
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
            .padding(.top, 2)
            
            Spacer()
            
            // MARK: Komponen Kanan: Tombol Simpan/Bookmark
            Button(action: onBookmark) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 19))
                    .foregroundColor(isBookmarked ? Color(red: 0.2, green: 0.2, blue: 0.9) : Color(.brand))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            .padding(.trailing, 4)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .padding(.vertical, 10)
        .overlay(
            Rectangle()
                .fill(Color(UIColor.separator).opacity(0.4))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

