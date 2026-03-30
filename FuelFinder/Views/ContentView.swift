


import SwiftUI
import MapKit

 struct ContentView: View {
    @State private var eta: String = ""
    @State private var distance: String = ""
        @State private var usingCurrentLocation = false
    @StateObject private var locationManager = LocationManager()
    @StateObject var fromVM = LocationSearchViewModel()
    @StateObject var toVM = LocationSearchViewModel()
    @StateObject private var vm = MainViewModel()
    @FocusState private var focus: Field?
    enum Field { case from, to }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            if vm.isLoading {
                HStack(spacing: 10) {
                    ProgressView().tint(Color(hex: "E65100")).scaleEffect(0.8)
                    Text(vm.loadingMessage)
                        .font(.system(size: 13)).italic()
                        .foregroundColor(Color(hex: "E65100"))
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Color.white)
            }
            if let err = vm.errorMessage {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color(hex: "C62828"))
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "C62828"))
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Color(hex: "FFEBEE"))
            }
            
            ZStack(alignment: .bottomTrailing) {
                FuelMapView(vm: vm)
                    .ignoresSafeArea(edges: .bottom)
                if case .idle = vm.appState { emptyCard }
                if vm.isSuccess, let r = vm.route {
                    routeChip(r)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 12)
                }
                if vm.isSuccess { fab.padding(20) }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $vm.showStationList) {
            StationListSheet(vm: vm)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        
        // ── When location arrives, set flag only ──
        .onReceive(locationManager.$userLocation) { location in
            guard location != nil else { return }
            usingCurrentLocation = true
        }
            .onReceive(NotificationCenter.default.publisher(for: .navigationUpdated)) { notification in
            guard let route = notification.object as? MKRoute else { return }
            let minutes = Int(route.expectedTravelTime / 60)
            let km = route.distance / 1000
          eta = "\(minutes) min"
            distance = String(format: "%.1f km", km)
        }
        // ── When address resolved, fill from field and auto-search ──
        .onReceive(locationManager.$resolvedAddress) { address in
            guard !address.isEmpty else { return }
            fromVM.searchText = address
            fromVM.suggestions = []
            focus = nil
            if !toVM.searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                doSearch()
            }
        }
        // ── Only reset flag if user manually types in from field ──
        .onChange(of: fromVM.searchText) { newValue in
            if newValue != locationManager.resolvedAddress {
                usingCurrentLocation = false  // manual typing
            }
        }
    }
    
     // MARK: - Header
    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Image("ic_pump")
                        .resizable()
                        .frame(width: 50, height: 50)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("FuelFinder")
                        .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                    Text("Real petrol pumps on your route")
                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                if vm.isSuccess {
                    Button("Reset") {
                        fromVM.searchText = ""
                        toVM.searchText = ""
                        usingCurrentLocation = false
                        vm.reset()
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .overlay(Capsule().stroke(.white, lineWidth: 1))
                }
            }
            
            VStack(alignment: .leading) {
                Text("Enter your location to get Started")
                    .foregroundStyle(Color.white)
                    .font(.system(size: 18, weight: .bold))
                
                HStack {
                    // From field — NO onChange reset here
                    locationRow(
                        image: "ic_start",
                        text: $fromVM.searchText,
                        placeholder: "Starting Point",
                        isFocused: focus == .from
                    )
                    .focused($focus, equals: .from)
                    .submitLabel(.next)
                    .onSubmit { focus = .to }
                    
                    // To field
                    locationRow(
                        image: "ic_destination",
                        text: $toVM.searchText,
                        placeholder: "Destination",
                        isFocused: focus == .to
                    )
                    .focused($focus, equals: .to)
                    .submitLabel(.search)
                    .onSubmit { doSearch() }
                }
                
                // From suggestions
                if focus == .from && !fromVM.suggestions.isEmpty {
                    SuggestionList(
                        vm: fromVM,
                        locationManager: locationManager,
                        isFromField: true
                    )
                }
   
                if focus == .to && !toVM.suggestions.isEmpty {
                    SuggestionList(
                        vm: toVM,
                        locationManager: locationManager,
                        isFromField: false,
                        onDestinationSelected: { doSearch() }  
                    )
                }
            }
            Button(action: doSearch) {
                Label(vm.isLoading ? "Searching..." : "Find Fuel Stations",
                      systemImage: "magnifyingglass")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(Color(hex: "E65100"))
                .cornerRadius(12)
            }
            .disabled(vm.isLoading)
            .opacity(vm.isLoading ? 0.7 : 1)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(hex: "1A237E"), Color(hex: "283593")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
    }
    
    private func locationRow(
        image: String,
        text: Binding<String>,
        placeholder: String,
        isFocused: Bool
    ) -> some View {
        HStack(spacing: 10) {
            Image(image)
                .resizable()
                .frame(width: 30, height: 30)
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                TextField("", text: text)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
        .background(.white.opacity(0.15))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(.white.opacity(isFocused ? 0.7 : 0.3), lineWidth: 1))
    }
    
    // MARK: - Empty card
    private var emptyCard: some View {
        VStack(spacing: 8) {
            Text("⛽").font(.system(size: 38))
            Text("Enter route above")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "1A1A2E"))
            Text("to see real petrol pumps")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "6B7280"))
        }
        .padding(22)
        .background(.ultraThinMaterial).cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    //  Route chip///
    private func routeChip(_ r: RouteInfo) -> some View {
        HStack(spacing: 6) {
            Circle().fill(Color(hex: "4CAF50")).frame(width: 8, height: 8)
            Text(r.fromName ?? "")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "1A1A2E")).lineLimit(1)
            Text("➜")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "E65100"))
            Circle().fill(Color(hex: "F44336")).frame(width: 8, height: 8)
            Text(r.toName ?? "")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "1A1A2E")).lineLimit(1)
            Text("• \(String(format: "%.0f", r.totalDistanceKm ?? 0.0)) km")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "6B7280"))
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(.ultraThinMaterial).cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
    
// pump count///
    private var fab: some View {
        Button { vm.showStationList = true } label: {
            VStack(spacing: 3) {
                Text("⛽").font(.system(size: 26))
                Text("\(vm.stations.count) pumps")
                    .font(.system(size: 10, weight: .bold)).foregroundColor(.white)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(LinearGradient(
                colors: [Color(hex: "1A237E"), Color(hex: "E65100")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .cornerRadius(20)
            .shadow(color: Color(hex: "1A237E").opacity(0.35), radius: 8, x: 0, y: 4)
        }
    }
    
  
    private func doSearch() {
        focus = nil
        let to = toVM.searchText.trimmingCharacters(in: .whitespaces)
        guard !to.isEmpty else { return }
        
        let from: String
        
        if usingCurrentLocation {
            if let coord = locationManager.userLocation?.coordinate {
                from = String(format: "%.6f,%.6f", coord.latitude, coord.longitude)
                print("✅ From coords:", from)
            } else {
                locationManager.requestLocation()
                return
            }
        } else {
            let typed = fromVM.searchText.trimmingCharacters(in: .whitespaces)
            guard !typed.isEmpty else { return }
            from = typed
            print("✅ From typed:", from)
        }
        vm.search(from: from, to: to, fromDisplayName: locationManager.resolvedAddress.isEmpty ? nil : locationManager.resolvedAddress)
    }
}

struct SuggestionList: View {
    @ObservedObject var vm: LocationSearchViewModel
    @ObservedObject var locationManager: LocationManager
    let isFromField: Bool
    var onDestinationSelected: (() -> Void)? = nil
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if isFromField {
                    HStack(spacing: 10) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        Text("Use Current Location")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        locationManager.requestLocation()
                        vm.suggestions = []
                    }
                    Divider()
                }
                    ForEach(vm.suggestions, id: \.self) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 14))
                        Text(item.subtitle)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        vm.searchText  = item.title
                        vm.suggestions = []
            
                        if !isFromField {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDestinationSelected?()
                            }
                        }
                    }
                    Divider()
                }
            }
        }
        .frame(maxHeight: 250)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}
#Preview {
    ContentView()
}
