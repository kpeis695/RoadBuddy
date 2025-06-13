// MapView.swift - Add this as a new file
import SwiftUI
import MapKit
import CoreLocation

// MARK: - Location Service
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestLocationPermission()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        currentLocation = location.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
}

// MARK: - Trip Map View
struct TripMapView: View {
    let trip: Trip
    @StateObject private var locationService = LocationService()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), // NYC default
        span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
    )
    @State private var fromCoordinate: CLLocationCoordinate2D?
    @State private var toCoordinate: CLLocationCoordinate2D?
    @State private var route: MKRoute?
    @State private var isLoadingRoute = false
    
    var body: some View {
        VStack {
            // Trip info header
            VStack(alignment: .leading, spacing: 8) {
                Text("\(trip.fromCity) → \(trip.toCity)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    Text("Driver: \(trip.driverName)")
                    Spacer()
                    Text("$\(Int(trip.pricePerPerson))")
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .font(.subheadline)
                
                if let route = route {
                    HStack {
                        Text("Distance: \(formatDistance(route.distance))")
                        Spacer()
                        Text("Time: \(formatTime(route.expectedTravelTime))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Map
            ZStack {
                Map(position: .constant(.region(region))) {
                    ForEach(mapAnnotations) { annotation in
                        Marker(annotation.name, coordinate: annotation.coordinate)
                            .tint(annotation.color)
                    }
                }
                
                if isLoadingRoute {
                    ProgressView("Loading route...")
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                }
            }
        }
        .navigationTitle("Trip Route")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadTripCoordinates()
        }
    }
    
    private var mapAnnotations: [MapAnnotation] {
        var annotations: [MapAnnotation] = []
        
        if let from = fromCoordinate {
            annotations.append(MapAnnotation(
                id: "from",
                name: trip.fromCity,
                coordinate: from,
                color: .green
            ))
        }
        
        if let to = toCoordinate {
            annotations.append(MapAnnotation(
                id: "to",
                name: trip.toCity,
                coordinate: to,
                color: .red
            ))
        }
        
        return annotations
    }
    
    private func loadTripCoordinates() async {
        isLoadingRoute = true
        
        // Geocode from city
        if let fromCoord = await geocodeCity(trip.fromCity) {
            fromCoordinate = fromCoord
        }
        
        // Geocode to city
        if let toCoord = await geocodeCity(trip.toCity) {
            toCoordinate = toCoord
        }
        
        // Update region to show both cities
        if let from = fromCoordinate, let to = toCoordinate {
            let center = CLLocationCoordinate2D(
                latitude: (from.latitude + to.latitude) / 2,
                longitude: (from.longitude + to.longitude) / 2
            )
            
            let latDelta = abs(from.latitude - to.latitude) * 1.5
            let lonDelta = abs(from.longitude - to.longitude) * 1.5
            
            region = MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(
                    latitudeDelta: max(latDelta, 0.5),
                    longitudeDelta: max(lonDelta, 0.5)
                )
            )
            
            // Calculate route
            await calculateRoute(from: from, to: to)
        }
        
        isLoadingRoute = false
    }
    
    private func geocodeCity(_ cityName: String) async -> CLLocationCoordinate2D? {
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.geocodeAddressString(cityName)
            return placemarks.first?.location?.coordinate
        } catch {
            print("Geocoding failed for \(cityName): \(error)")
            return nil
        }
    }
    
    private func calculateRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        
        do {
            let response = try await directions.calculate()
            route = response.routes.first
        } catch {
            print("Route calculation failed: \(error)")
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let miles = distance * 0.000621371
        return String(format: "%.0f mi", miles)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Map Annotation Model
struct MapAnnotation: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let color: Color
}

// MARK: - Route Overlay (Simple line for now)
struct RouteOverlay: View {
    let route: MKRoute?
    
    var body: some View {
        // For now, we'll show a simple implementation
        // In a full app, you'd use MKOverlayRenderer for the actual route path
        EmptyView()
    }
}

// MARK: - Enhanced Trip Card with Map Button
struct EnhancedTripCard: View {
    let trip: Trip
    @State private var showingMap = false
    @State private var showingBooking = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(trip.fromCity) → \(trip.toCity)")
                        .font(.headline)
                    Text("\(trip.departureDate) at \(trip.departureTime)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("$\(Int(trip.pricePerPerson))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("per person")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                Image(systemName: "person.circle")
                Text(trip.driverName)
                    .font(.subheadline)
                
                Spacer()
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(String(format: "%.1f", trip.driverRating))
                        .font(.caption)
                }
            }
            
            if !trip.description.isEmpty {
                Text(trip.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Text("\(trip.availableSeats) seats available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Map button
                Button(action: { showingMap = true }) {
                    HStack {
                        Image(systemName: "map")
                        Text("Route")
                    }
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(6)
                
                // Book button
                Button("Book") {
                    showingBooking = true
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding(.horizontal)
        .sheet(isPresented: $showingMap) {
            NavigationView {
                TripMapView(trip: trip)
                    .navigationBarItems(
                        trailing: Button("Done") {
                            showingMap = false
                        }
                    )
            }
        }
        .sheet(isPresented: $showingBooking) {
            PaymentBookingView(trip: trip)
        }
    }
}

// MARK: - Location Picker for Post Trip
struct LocationPickerView: View {
    @Binding var selectedLocation: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Environment(\.presentationMode) var presentationMode
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    TextField("Search for a city...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            searchForLocation()
                        }
                    
                    Button("Search") {
                        searchForLocation()
                    }
                }
                .padding()
                
                // Search results
                if !searchResults.isEmpty {
                    List(searchResults, id: \.self) { item in
                        VStack(alignment: .leading) {
                            Text(item.name ?? "Unknown")
                                .font(.headline)
                            if let address = item.placemark.title {
                                Text(address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onTapGesture {
                            selectLocation(item)
                        }
                    }
                    .frame(height: 200)
                }
                
                // Map
                Map(position: .constant(.region(region))) {
                    ForEach(selectedAnnotations) { annotation in
                        Marker(annotation.name, coordinate: annotation.coordinate)
                            .tint(annotation.color)
                    }
                }
                .onTapGesture(coordinateSpace: .local) { location in
                    // Handle map tap to select location
                }
            }
            .navigationTitle("Select Location")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(selectedCoordinate == nil)
            )
        }
    }
    
    private var selectedAnnotations: [MapAnnotation] {
        guard let coord = selectedCoordinate else { return [] }
        return [MapAnnotation(id: "selected", name: selectedLocation, coordinate: coord, color: .red)]
    }
    
    private func searchForLocation() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let response = response {
                searchResults = response.mapItems
            }
        }
    }
    
    private func selectLocation(_ item: MKMapItem) {
        selectedLocation = item.name ?? "Unknown Location"
        selectedCoordinate = item.placemark.coordinate
        
        region = MKCoordinateRegion(
            center: item.placemark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        searchResults = []
    }
}
