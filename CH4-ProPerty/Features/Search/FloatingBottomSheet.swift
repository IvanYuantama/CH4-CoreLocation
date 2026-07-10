//
//  FloatingBottomSheet.swift
//  CH4-ProPerty
//
//  Created by Ryan Tjendana on 08/07/26.
//

import SwiftUI
import MapKit

enum FloatingSheetState {
    case collapsed
    case expanded
}

// MARK: - Generic Floating Sheet Container

struct FloatingBottomSheet<Content: View>: View {

    @Binding var state: FloatingSheetState
    @GestureState private var dragOffset: CGFloat = 0

    let content: Content

    init(
        state: Binding<FloatingSheetState>,
        @ViewBuilder content: () -> Content
    ) {
        _state = state
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in

            VStack(alignment: .center) {
                Spacer()
                content
            }
            .frame(
                width: sheetWidth(in: geo),
                height: sheetHeight(in: geo)
            )
            .background(Color(.cardBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 25)
            .frame(maxWidth: .infinity,
                   maxHeight: .infinity,
                   alignment: .bottom)
            .padding(.bottom, bottomPadding(in: geo))
            .offset(y: dragOffset)
            .animation(.snappy, value: state)
            .gesture(dragGesture)
        }
        
    }

    private func sheetWidth(in geo: GeometryProxy) -> CGFloat {
        switch state {
        case .collapsed:
            return 250
        case .expanded:
            return geo.size.width
        }
    }

    private func sheetHeight(in geo: GeometryProxy) -> CGFloat {
        let h = geo.size.height
           print("height =", h)
        
        switch state {
        case .collapsed:
            return 45
        case .expanded:
            return 778
            
        }
    }

    private func bottomPadding(in geo: GeometryProxy) -> CGFloat {
        switch state {
        case .collapsed:
            return 45
        case .expanded:
            return -20
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in

                if value.translation.height < -20 {
                    state = .expanded
                } else if value.translation.height > 80 {
                    state = .collapsed
                }
            }
    }}

// MARK: - Search Sheet Implementation (port dari SearchSheet.swift)
struct FloatingSearchSheet: View {
    let center: CLLocationCoordinate2D
    @Binding var state: FloatingSheetState
    let onSelect: (PlaceResult) -> Void

    @StateObject private var vm = SearchViewModel()
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        FloatingBottomSheet(state: $state) {
            VStack(spacing: 0) {
                searchField

                List {
                    if vm.query.isEmpty {
                        ForEach(vm.savedPlaces) { place in
                            SearchResultRow(
                                place: place,
                                isBookmarked: true,
                                onBookmark: { vm.toggleBookmark(for: place) },
                                onTap: { selectAndCollapse(place) }
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    } else {
                        ForEach(vm.results) { place in
                            SearchResultRow(
                                place: place,
                                isBookmarked: vm.isBookmarked(place),
                                onBookmark: { vm.toggleBookmark(for: place) },
                                onTap: { selectAndCollapse(place) }
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onAppear { vm.setCenter(center) }
        .onChange(of: center) { _, newCenter in
            vm.setCenter(newCenter)
        }
        .onChange(of: isFieldFocused) { _, focused in
            if focused {
                withAnimation(.snappy) {
                    state = .expanded
                }
            }
        }
        .onChange(of: state) { _, newState in
            if newState == .collapsed {
                isFieldFocused = false
            }
        }
    }

    private func selectAndCollapse(_ place: PlaceResult) {
        isFieldFocused = false
        withAnimation(.snappy) {
            state = .collapsed
        }
        onSelect(place)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundColor(Color(.textPrimary))
            TextField(L.t(.searchLocation), text: $vm.query)
                .focused($isFieldFocused)
                .font(Theme.Typography.category)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)
            if vm.isLoading {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: "mic.fill").foregroundColor(Color(.textPrimary))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .padding(.horizontal, 16)
        .background(Color(.cardBackground))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
        .padding(.horizontal, state == .expanded ? 16 : 0)
        .padding(.bottom, 10)
    }
}

// MARK: - Preview

#Preview {
    Demo()
}

private struct Demo: View {

    @State private var state: FloatingSheetState = .collapsed

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.green.opacity(0.3), .blue.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Text("MAP")

            FloatingSearchSheet(
                center: CLLocationCoordinate2D(latitude: -6.2088, longitude: 106.8456),
                state: $state
            ) { place in
                print("Selected:", place.name)
            }
            .offset(y: 35)
        }
    }
}
