//
//  MapView.swift
//  test
//
//  Created by Benedict Kenjiro Lehot on 30/06/26.
//

import SwiftUI
import MapKit

extension MKMapItem: @retroactive Identifiable {
    public var id: String { self.name ?? UUID().uuidString }
}

struct MapView: View {
    @StateObject private var locationManager = LocationManager2()
    @State private var position: MapCameraPosition = .automatic
    @State private var hasCenteredOnUser = false
    @State private var selectedMapItem: MKMapItem?
    @State private var tappedCoordinate: CLLocationCoordinate2D?

    @State private var showCoordinateSheet = false

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
        ZStack(alignment: .top) {
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
                            let latitudeOffset = 0.005
                            let adjustedCenter = CLLocationCoordinate2D(
                                latitude: coordinate.latitude - latitudeOffset,
                                longitude: coordinate.longitude
                            )
                            position = .region(
                                MKCoordinateRegion(
                                    center: adjustedCenter,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )
                            )
                        }
                        Task {
                            await fetchPlace(at: coordinate)
                        }
                    }
                }
                .sheet(item: $selectedMapItem) { mapItem in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if let name = mapItem.name {
                                Text(name)
                                    .font(.title2.bold())
                            }
                            if let address = mapItem.placemark.title {
                                Label(address, systemImage: "mappin")
                                    .foregroundStyle(.secondary)
                            }
                            if let phone = mapItem.phoneNumber {
                                Label(phone, systemImage: "phone")
                            }
                            if let url = mapItem.url {
                                Link(destination: url) {
                                    Label("Buka Website", systemImage: "safari")
                                }
                            }
                            Button("Buka di Apple Maps") {
                                mapItem.openInMaps()
                            }
                            .buttonStyle(.borderedProminent)

                            ParameterItemView(icon: "water.waves", text: "Low Flood Risk", color: "34C759")
                            ParameterItemView(icon: "thermometer.medium", text: "Very Hot", color: "FF3B30")
                            ParameterItemView(icon: "aqi.medium", text: "Moderate", color: "FF9500")
                            ParameterItemView(icon: "leaf", text: "Dense", color: "34C759")
                            ParameterItemView(icon: "person.3", text: "8,450/km²", color: "5AC8FA")
                            ParameterItemView(icon: "mountain.2", text: "Highland", color: "5AC8FA")
                            ParameterItemView(icon: "road.lanes", text: "Footpath", color: "8E8E93")
                            ParameterItemView(icon: "building.2", text: "Adequate")
                            ParameterItemView(icon: "cloud.fog", text: "100%")

                            Spacer()
                        }
                    }
                    .padding()
                    .presentationDetents([.fraction(0.75)])
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled)
                }
            }

            // Search bar di atas map
            MapSearchView(
                position: $position,
                tappedCoordinate: $tappedCoordinate,
                selectedMapItem: $selectedMapItem
            )

            // Tombol-tombol di kanan bawah
            VStack {
                Spacer()
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
        .sheet(isPresented: $showCoordinateSheet) {
            CoordinateSheetView(coordinate: locationManager.coordinate)
                .presentationDetents([.height(160)])
                .presentationDragIndicator(.visible)
        }
    }

    func fetchPlace(at coordinate: CLLocationCoordinate2D) async {
        let request = MKLocalPointsOfInterestRequest(
            center: coordinate,
            radius: 50
        )
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            let nearest = response.mapItems.min { lhs, rhs in
                distance(from: coordinate, to: lhs.location.coordinate) <
                distance(from: coordinate, to: rhs.location.coordinate)
            }

            if let nearest {
                selectedMapItem = nearest
            } else {
                await fetchAddress(at: coordinate)
            }
        } catch {
            print("Gagal mengambil place: \(error.localizedDescription)")
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
            selectedMapItem = mapItems.first
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
    MapView()
}
