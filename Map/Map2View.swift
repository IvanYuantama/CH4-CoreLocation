//
//  Map2View.swift
//  test
//
//  Created by Benedict Kenjiro Lehto on 01/07/26.
//

import SwiftUI
import MapKit
import GeoToolbox

struct Map2View: View {
    @StateObject private var locationManager = LocationManager2()
    @State private var position: MapCameraPosition = .automatic
    @State private var hasCenteredOnUser = false
    @State private var selectedMapItem: MKMapItem?       // mengontrol mapItemDetailSheet
    @State private var lastFetchedMapItem: MKMapItem?    // menyimpan item terakhir
    @State private var tappedCoordinate: CLLocationCoordinate2D?
    @State private var showCoordinateSheet = false
    @State private var showLastPlaceSheet = false

    @State private var selectedStyle: MapStyleOption = .standard

    enum MapStyleOption: String, CaseIterable {
        case standard = "Standard"
        case hybrid = "Hybrid"
        case satellite = "Satellite"

        var mapStyle: MapStyle {
            switch self {
            case .standard: .standard(elevation: .realistic)
            case .hybrid: .hybrid(elevation: .realistic)
            case .satellite: .imagery(elevation: .realistic)
            }
        }
    }

    var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $position, selection: $selectedMapItem) {
                    UserAnnotation()

                    if let tappedCoordinate {
                        Marker("Lokasi Dipilih", coordinate: tappedCoordinate)
                    }
                }
                .mapControls {
                    MapCompass()
                    MapUserLocationButton()
                    MapScaleView()
                    MapPitchToggle()
                }
                .mapStyle(selectedStyle.mapStyle)
                .onAppear {
                    locationManager.requestPermission()
                }
                .onChange(of: locationManager.coordinate) { _, newCoordinate in
                    guard let coordinate = newCoordinate, !hasCenteredOnUser else { return }
                    position = .region(
                        MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                        )
                    )
                    hasCenteredOnUser = true
                }
                .onTapGesture { screenPoint in
                    if let coordinate = proxy.convert(screenPoint, from: .local) {
                        tappedCoordinate = coordinate
                        withAnimation {
                            position = .region(
                                MKCoordinateRegion(
                                    center: coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )
                            )
                        }
                        Task {
                            await fetchPlace(at: coordinate)
                        }
                    }
                }
                .mapItemDetailSheet(item: $selectedMapItem)
            }

            VStack {
                Spacer()
                
                HStack {
                    Spacer()

                    // Tombol buka ulang sheet tempat terakhir
                    if lastFetchedMapItem != nil {
                        Button {
                            selectedMapItem = lastFetchedMapItem
                        } label: {
                            Image(systemName: "mappin.circle.fill")
                                .padding()
                                .background(.white)
                                .cornerRadius(100)
                                .shadow(radius: 4)
                                .font(.system(size: 28))
                                .foregroundStyle(.blue)
                        }
                        .padding(.trailing)
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                HStack {
                    Spacer()
                    Menu {
                        Picker("Map Style", selection: $selectedStyle) {
                            ForEach(MapStyleOption.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                    } label: {
                        Image(systemName: "map")
                            .padding()
                            .background(.white)
                            .cornerRadius(100)
                            .shadow(radius: 4)
                            .font(.system(size: 28))
                            .foregroundStyle(.blue)
                    }
                    .padding()
                }

                HStack {
                    Spacer()
                    Button {
                        showCoordinateSheet = true
                    } label: {
                        Image(systemName: "dot.scope")
                            .padding()
                            .background(.white)
                            .cornerRadius(100)
                            .shadow(radius: 4)
                            .font(.system(size: 28))
                            .foregroundStyle(.blue)
                    }
                    .padding()
                }
            }
        }
        .animation(.easeInOut, value: lastFetchedMapItem != nil)
        .sheet(isPresented: $showCoordinateSheet) {
            CoordinateSheetView(coordinate: locationManager.coordinate)
                .presentationDetents([.height(160)])
                .presentationDragIndicator(.visible)
        }
    }

    func fetchPlace(at coordinate: CLLocationCoordinate2D) async {
        let descriptor = PlaceDescriptor(
            representations: [.coordinate(coordinate)],
            commonName: nil
        )
        let geoRequest = MKMapItemRequest(placeDescriptor: descriptor)

        do {
            let mapItem = try await geoRequest.mapItem
            if mapItem.name != nil {
                selectedMapItem = mapItem
                lastFetchedMapItem = mapItem   // simpan untuk tombol buka ulang
                return
            }
        } catch { }

        let poiRequest = MKLocalPointsOfInterestRequest(
            center: coordinate,
            radius: 50
        )
        let search = MKLocalSearch(request: poiRequest)

        do {
            let response = try await search.start()
            let nearest = response.mapItems.min { lhs, rhs in
                distance(from: coordinate, to: lhs.location.coordinate) <
                distance(from: coordinate, to: rhs.location.coordinate)
            }

            if let nearest {
                selectedMapItem = nearest
                lastFetchedMapItem = nearest   // simpan untuk tombol buka ulang
            } else {
                await fetchAddress(at: coordinate)
            }
        } catch {
            await fetchAddress(at: coordinate)
        }
    }

    private func fetchAddress(at coordinate: CLLocationCoordinate2D) async {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else {
            print("Koordinat tidak valid untuk reverse geocoding")
            return
        }
        do {
            let mapItems = try await request.mapItems
            if let first = mapItems.first {
                selectedMapItem = first
                lastFetchedMapItem = first     // simpan untuk tombol buka ulang
            }
        } catch {
            print("Gagal mengambil alamat: \(error.localizedDescription)")
        }
    }

    private func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: from.latitude, longitude: from.longitude)
            .distance(from: CLLocation(latitude: to.latitude, longitude: to.longitude))
    }
}

#Preview {
    Map2View()
}
