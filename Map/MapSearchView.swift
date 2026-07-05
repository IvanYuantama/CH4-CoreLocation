//
//  MapSearchView.swift
//  test
//
//  Created by Benedict Kenjiro Lehot on 02/07/26.
//

import SwiftUI
import MapKit

struct MapSearchView: View {
    @Binding var position: MapCameraPosition
    @Binding var tappedCoordinate: CLLocationCoordinate2D?
    @Binding var selectedMapItem: MKMapItem?

    @State private var searchText = ""
    @State private var completions: [MKLocalSearchCompletion] = []
    @State private var isSearching = false

    private let completer = MKLocalSearchCompleter()
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Cari lokasi...", text: $searchText)
                    .autocorrectionDisabled()
                    .onChange(of: searchText) { _, newValue in
                        searchTask?.cancel()
                        if newValue.isEmpty {
                            completions = []
                            isSearching = false
                        } else {
                            isSearching = true
                            searchTask = Task {
                                try? await Task.sleep(for: .milliseconds(300))
                                guard !Task.isCancelled else { return }
                                completer.queryFragment = newValue
                            }
                        }
                    }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        completions = []
                        isSearching = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 4)
            .padding(.horizontal)
            .padding(.top)

            // Hasil autocomplete
            if isSearching && !completions.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(completions, id: \.self) { completion in
                            Button {
                                selectCompletion(completion)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(completion.title)
                                        .foregroundStyle(.primary)
                                        .font(.body)
                                    if !completion.subtitle.isEmpty {
                                        Text(completion.subtitle)
                                            .foregroundStyle(.secondary)
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            Divider()
                                .padding(.leading)
                        }
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
                .frame(maxHeight: 300)
            }

            Spacer()
        }
        .onAppear {
            completer.delegate = SearchCompleterDelegate(completions: $completions)
            completer.resultTypes = [.pointOfInterest, .address]
        }
    }

    private func selectCompletion(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        Task {
            do {
                let response = try await search.start()
                if let mapItem = response.mapItems.first {
                    selectedMapItem = mapItem
                    tappedCoordinate = mapItem.placemark.coordinate

                    withAnimation {
                        let latitudeOffset = 0.005
                        position = .region(
                            MKCoordinateRegion(
                                center: CLLocationCoordinate2D(
                                    latitude: mapItem.placemark.coordinate.latitude - latitudeOffset,
                                    longitude: mapItem.placemark.coordinate.longitude
                                ),
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        )
                    }

                    searchText = ""
                    completions = []
                    isSearching = false
                }
            } catch {
                print("Gagal mencari lokasi: \(error.localizedDescription)")
            }
        }
    }
}

// Delegate untuk MKLocalSearchCompleter
class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    @Binding var completions: [MKLocalSearchCompletion]

    init(completions: Binding<[MKLocalSearchCompletion]>) {
        _completions = completions
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Completer error: \(error.localizedDescription)")
    }
}

#Preview {
    MapSearchView(
        position: .constant(.automatic),
        tappedCoordinate: .constant(nil),
        selectedMapItem: .constant(nil)
    )
}
