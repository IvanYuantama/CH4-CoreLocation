//
//  SearchSheet.swift
//  CH4-ProPerty
//
//  Created by Andhika Satria on 05/07/26.
//

import SwiftUI
import MapKit

// CLLocationCoordinate2D belum conform Equatable secara default -- wajib ada ini
// supaya `.onChange(of: center)` di bawah bisa compile.
extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct SearchSheet: View {
    let center: CLLocationCoordinate2D
    @Binding var detent: PresentationDetent
    let onSelect: (PlaceResult) -> Void

    @StateObject private var vm = SearchViewModel()
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        // MARK: - Daftar Hasil Pencarian
        List {
            ForEach(vm.results) { place in
                SearchResultRow(
                    place: place,
                    isBookmarked: vm.isBookmarked(place),
                    onBookmark: { vm.toggleBookmark(for: place) },
                    onTap: { selectAndCollapse(place) }
                )
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .safeAreaInset(edge: .top) {
            // Memanggil Search Bar Custom di bagian atas
            searchField
        }
        .background(Color(.cardBackground).ignoresSafeArea())
        .onAppear { vm.setCenter(center) }
        .onChange(of: center) { _, newCenter in
            // Map di-geser -> update origin buat re-sort jarak/relevansi hasil pencarian.
            vm.setCenter(newCenter)
        }
        .onChange(of: isFieldFocused) { _, focused in
            if focused {
                withAnimation(.snappy) { detent = .large }
            }
        }
        .onChange(of: detent) { _, newDetent in
            // Kalau sheet di-collapse dari luar (mis. tap di map), pastikan keyboard
            // ikut turun -- tanpa ini isFieldFocused nyangkut true & keyboard nongol
            // padahal sheet-nya udah collapse.
            if newDetent != .large && newDetent != .medium {
                isFieldFocused = false
            }
        }
    }

    private func selectAndCollapse(_ place: PlaceResult) {
        isFieldFocused = false
        withAnimation(.snappy) {
            detent = .height(64)
        }
        onSelect(place)
    }

    // MARK: - Search Bar Custom
    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundColor(Color(.textSecondary))
            
            // Kolom input teks
            TextField(L.t(.searchLocation), text: $vm.query)
                .focused($isFieldFocused)
                .font(.body)
                .textCase(nil)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)
            
            // Indikator loading atau icon mic
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
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(.cardBackground))
        .offset(y: 5)
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
                CustomPinMarker() // Pastikan struct CustomPinMarker() sudah ada di file lain ya

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

// MARK: - Previews

#Preview("Search Sheet - Collapsed (Docked)") {
    SearchSheetDockedPreview(detent: .height(64))
}

#Preview("Search Sheet - Expanded (Docked)") {
    SearchSheetDockedPreview(detent: .large)
}

/// Wrapper preview yang bener-bener nge-present `SearchSheet` lewat `.sheet`
private struct SearchSheetDockedPreview: View {
    @State private var detent: PresentationDetent
    @State private var showSheet = true

    init(detent: PresentationDetent) {
        _detent = State(initialValue: detent)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemGray5), Color(.systemGray3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Text("MAP AREA (placeholder)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showSheet) {
            SearchSheet(
                center: CLLocationCoordinate2D(
                    latitude: -6.2088,
                    longitude: 106.8456
                ),
                detent: $detent
            ) { place in
                print("Selected:", place.name)
            }
            .presentationDetents([.height(64), .medium, .large], selection: $detent)
            .presentationBackgroundInteraction(.enabled(upThrough: .height(64)))
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled()
        }
    }
}
