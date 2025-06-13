// AdvancedFeatures.swift - Add this as a new file
import SwiftUI
import MapKit

// MARK: - Vehicle Models
struct Vehicle: Codable, Identifiable {
    let id: String
    let ownerID: String
    let make: String
    let model: String
    let year: Int
    let color: String
    let licensePlate: String
    let vehicleType: VehicleType
    let seatingCapacity: Int
    let amenities: [VehicleAmenity]
    let photos: [Data]
    let isVerified: Bool
    let insuranceVerified: Bool
    
    enum VehicleType: String, Codable, CaseIterable {
        case sedan = "sedan"
        case suv = "suv"
        case hatchback = "hatchback"
        case truck = "truck"
        case van = "van"
        case luxury = "luxury"
        
        var displayName: String {
            switch self {
            case .sedan: return "Sedan"
            case .suv: return "SUV"
            case .hatchback: return "Hatchback"
            case .truck: return "Truck"
            case .van: return "Van"
            case .luxury: return "Luxury"
            }
        }
        
        var icon: String {
            switch self {
            case .sedan: return "car.fill"
            case .suv: return "car.2.fill"
            case .hatchback: return "car.rear.fill"
            case .truck: return "truck.box.fill"
            case .van: return "bus.fill"
            case .luxury: return "car.top.radiowaves.front"
            }
        }
    }
    
    enum VehicleAmenity: String, Codable, CaseIterable {
        case airConditioning = "ac"
        case heating = "heating"
        case bluetooth = "bluetooth"
        case wifi = "wifi"
        case usbCharging = "usb"
        case musicSystem = "music"
        case extraLuggage = "luggage"
        case childSeat = "child_seat"
        
        var displayName: String {
            switch self {
            case .airConditioning: return "Air Conditioning"
            case .heating: return "Heating"
            case .bluetooth: return "Bluetooth"
            case .wifi: return "WiFi"
            case .usbCharging: return "USB Charging"
            case .musicSystem: return "Premium Sound"
            case .extraLuggage: return "Extra Luggage Space"
            case .childSeat: return "Child Seat Available"
            }
        }
        
        var icon: String {
            switch self {
            case .airConditioning: return "snowflake"
            case .heating: return "thermometer.sun"
            case .bluetooth: return "bluetooth"
            case .wifi: return "wifi"
            case .usbCharging: return "battery.100.bolt"
            case .musicSystem: return "speaker.3"
            case .extraLuggage: return "suitcase"
            case .childSeat: return "figure.2.and.child.holdinghands"
            }
        }
    }
    
    var displayName: String {
        return "\(year) \(make) \(model)"
    }
}

// MARK: - Recurring Trip Models
struct RecurringTrip: Codable, Identifiable {
    let id: String
    let driverID: String
    let fromCity: String
    let toCity: String
    let departureTime: String
    let recurringPattern: RecurringPattern
    let pricePerPerson: Double
    let availableSeats: Int
    let vehicleID: String?
    let isActive: Bool
    let startDate: Date
    let endDate: Date?
    
    enum RecurringPattern: String, Codable, CaseIterable {
        case daily = "daily"
        case weekdays = "weekdays"
        case weekends = "weekends"
        case weekly = "weekly"
        case biweekly = "biweekly"
        case monthly = "monthly"
        
        var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .weekdays: return "Weekdays Only"
            case .weekends: return "Weekends Only"
            case .weekly: return "Weekly"
            case .biweekly: return "Every 2 Weeks"
            case .monthly: return "Monthly"
            }
        }
        
        var description: String {
            switch self {
            case .daily: return "Every day"
            case .weekdays: return "Monday to Friday"
            case .weekends: return "Saturday and Sunday"
            case .weekly: return "Same day every week"
            case .biweekly: return "Every other week"
            case .monthly: return "Same date every month"
            }
        }
    }
}

// MARK: - Advanced Search Filters
struct SearchFilters: Codable {
    var priceRange: ClosedRange<Double>
    var vehicleTypes: Set<Vehicle.VehicleType>
    var requiredAmenities: Set<Vehicle.VehicleAmenity>
    var minRating: Double
    var maxDetourMinutes: Int
    var instantBooking: Bool
    var verifiedDriversOnly: Bool
    
    static let `default` = SearchFilters(
        priceRange: 0...200,
        vehicleTypes: Set(Vehicle.VehicleType.allCases),
        requiredAmenities: [],
        minRating: 0.0,
        maxDetourMinutes: 30,
        instantBooking: false,
        verifiedDriversOnly: false
    )
}

// MARK: - Driver Analytics
struct DriverAnalytics: Codable {
    let totalEarnings: Double
    let monthlyEarnings: Double
    let totalTrips: Int
    let monthlyTrips: Int
    let averageRating: Double
    let totalDistance: Double
    let fuelSavings: Double
    let co2Reduced: Double
    let topRoutes: [RouteStats]
    let earningsHistory: [EarningsRecord]
    
    struct RouteStats: Codable, Identifiable {
        let id: String
        let route: String
        let tripCount: Int
        let totalEarnings: Double
        let averageRating: Double
    }
    
    struct EarningsRecord: Codable, Identifiable {
        let id: String
        let date: Date
        let amount: Double
        let tripCount: Int
    }
}

// MARK: - Vehicle Service
class VehicleService: ObservableObject {
    static let shared = VehicleService()
    
    @Published var userVehicles: [Vehicle] = []
    @Published var isLoading = false
    
    private init() {
        loadStoredVehicles()
    }
    
    func addVehicle(
        make: String,
        model: String,
        year: Int,
        color: String,
        licensePlate: String,
        vehicleType: Vehicle.VehicleType,
        seatingCapacity: Int,
        amenities: [Vehicle.VehicleAmenity],
        photos: [Data]
    ) async -> Bool {
        guard let currentUser = AuthService.shared.currentUser else { return false }
        
        await MainActor.run {
            isLoading = true
        }
        
        let vehicle = Vehicle(
            id: UUID().uuidString,
            ownerID: currentUser.id,
            make: make,
            model: model,
            year: year,
            color: color,
            licensePlate: licensePlate,
            vehicleType: vehicleType,
            seatingCapacity: seatingCapacity,
            amenities: amenities,
            photos: photos,
            isVerified: false,
            insuranceVerified: false
        )
        
        await MainActor.run {
            userVehicles.append(vehicle)
            storeVehicles()
            isLoading = false
        }
        
        return true
    }
    
    func removeVehicle(_ vehicle: Vehicle) {
        userVehicles.removeAll { $0.id == vehicle.id }
        storeVehicles()
    }
    
    private func storeVehicles() {
        if let data = try? JSONEncoder().encode(userVehicles) {
            UserDefaults.standard.set(data, forKey: "user_vehicles")
        }
    }
    
    private func loadStoredVehicles() {
        if let data = UserDefaults.standard.data(forKey: "user_vehicles"),
           let vehicles = try? JSONDecoder().decode([Vehicle].self, from: data) {
            userVehicles = vehicles
        }
    }
}

// MARK: - Advanced Trip Service
class AdvancedTripService: ObservableObject {
    static let shared = AdvancedTripService()
    
    @Published var recurringTrips: [RecurringTrip] = []
    @Published var searchFilters = SearchFilters.default
    @Published var driverAnalytics: DriverAnalytics?
    @Published var isLoading = false
    
    private init() {
        loadStoredData()
        generateDemoAnalytics()
    }
    
    // MARK: - Recurring Trips
    func createRecurringTrip(
        fromCity: String,
        toCity: String,
        departureTime: String,
        pattern: RecurringTrip.RecurringPattern,
        pricePerPerson: Double,
        availableSeats: Int,
        vehicleID: String?,
        startDate: Date,
        endDate: Date?
    ) async -> Bool {
        guard let currentUser = AuthService.shared.currentUser else { return false }
        
        await MainActor.run {
            isLoading = true
        }
        
        let recurringTrip = RecurringTrip(
            id: UUID().uuidString,
            driverID: currentUser.id,
            fromCity: fromCity,
            toCity: toCity,
            departureTime: departureTime,
            recurringPattern: pattern,
            pricePerPerson: pricePerPerson,
            availableSeats: availableSeats,
            vehicleID: vehicleID,
            isActive: true,
            startDate: startDate,
            endDate: endDate
        )
        
        await MainActor.run {
            recurringTrips.append(recurringTrip)
            storeRecurringTrips()
            isLoading = false
        }
        
        return true
    }
    
    // MARK: - Advanced Search
    func searchTripsWithFilters(_ filters: SearchFilters) async -> [Trip] {
        await MainActor.run {
            isLoading = true
            searchFilters = filters
        }
        
        // Simulate API call with filters
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // In real app, this would filter results from backend
        let mockFilteredTrips = generateMockTripsWithFilters(filters)
        
        await MainActor.run {
            isLoading = false
        }
        
        return mockFilteredTrips
    }
    
    private func generateMockTripsWithFilters(_ filters: SearchFilters) -> [Trip] {
        // Generate mock trips that match the filters
        var trips: [Trip] = []
        
        for i in 1...5 {
            let price = Double.random(in: filters.priceRange)
            let rating = Double.random(in: filters.minRating...5.0)
            
            trips.append(Trip(
                id: "filtered_\(i)",
                driverID: "driver_\(i)",
                driverName: "Driver \(i)",
                driverRating: rating,
                fromCity: "City A",
                toCity: "City B",
                departureDate: "2025-06-\(15 + i)",
                departureTime: "10:00",
                availableSeats: Int.random(in: 1...4),
                pricePerPerson: price,
                description: "Filtered trip matching your preferences",
                status: "active"
            ))
        }
        
        return trips
    }
    
    // MARK: - Driver Analytics
    private func generateDemoAnalytics() {
        let analytics = DriverAnalytics(
            totalEarnings: 2847.50,
            monthlyEarnings: 485.25,
            totalTrips: 47,
            monthlyTrips: 8,
            averageRating: 4.8,
            totalDistance: 1847.3,
            fuelSavings: 234.50,
            co2Reduced: 145.2,
            topRoutes: [
                DriverAnalytics.RouteStats(
                    id: "1",
                    route: "NYC → Boston",
                    tripCount: 12,
                    totalEarnings: 540.0,
                    averageRating: 4.9
                ),
                DriverAnalytics.RouteStats(
                    id: "2",
                    route: "Boston → NYC",
                    tripCount: 10,
                    totalEarnings: 485.0,
                    averageRating: 4.7
                )
            ],
            earningsHistory: generateEarningsHistory()
        )
        
        driverAnalytics = analytics
    }
    
    private func generateEarningsHistory() -> [DriverAnalytics.EarningsRecord] {
        var history: [DriverAnalytics.EarningsRecord] = []
        let calendar = Calendar.current
        
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let earnings = Double.random(in: 0...150)
            let trips = earnings > 50 ? Int.random(in: 1...3) : 0
            
            history.append(DriverAnalytics.EarningsRecord(
                id: "\(i)",
                date: date,
                amount: earnings,
                tripCount: trips
            ))
        }
        
        return history.reversed()
    }
    
    // MARK: - Storage
    private func storeRecurringTrips() {
        if let data = try? JSONEncoder().encode(recurringTrips) {
            UserDefaults.standard.set(data, forKey: "recurring_trips")
        }
    }
    
    private func loadStoredData() {
        if let data = UserDefaults.standard.data(forKey: "recurring_trips"),
           let trips = try? JSONDecoder().decode([RecurringTrip].self, from: data) {
            recurringTrips = trips
        }
    }
}

// MARK: - Vehicle Management View
struct VehicleManagementView: View {
    @StateObject private var vehicleService = VehicleService.shared
    @State private var showingAddVehicle = false
    
    var body: some View {
        NavigationView {
            VStack {
                if vehicleService.userVehicles.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "car.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No vehicles added")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Add your vehicle to start offering rides")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Add Vehicle") {
                            showingAddVehicle = true
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(vehicleService.userVehicles) { vehicle in
                            VehicleRow(vehicle: vehicle)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                vehicleService.removeVehicle(vehicleService.userVehicles[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Vehicles")
            .navigationBarItems(
                trailing: Button("Add") {
                    showingAddVehicle = true
                }
            )
        }
        .sheet(isPresented: $showingAddVehicle) {
            AddVehicleView()
        }
    }
}

struct VehicleRow: View {
    let vehicle: Vehicle
    
    var body: some View {
        HStack(spacing: 12) {
            // Vehicle photo or icon
            Group {
                if let photoData = vehicle.photos.first,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: vehicle.vehicleType.icon)
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }
            .frame(width: 60, height: 60)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(vehicle.displayName)
                    .font(.headline)
                
                Text("\(vehicle.color) • \(vehicle.seatingCapacity) seats")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(vehicle.vehicleType.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    if vehicle.isVerified {
                        Text("Verified")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
                
                // Amenities
                if !vehicle.amenities.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(vehicle.amenities.prefix(3), id: \.self) { amenity in
                                Image(systemName: amenity.icon)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            if vehicle.amenities.count > 3 {
                                Text("+\(vehicle.amenities.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Vehicle View
struct AddVehicleView: View {
    @StateObject private var vehicleService = VehicleService.shared
    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var color = ""
    @State private var licensePlate = ""
    @State private var vehicleType = Vehicle.VehicleType.sedan
    @State private var seatingCapacity = 4
    @State private var selectedAmenities: Set<Vehicle.VehicleAmenity> = []
    @State private var vehiclePhotos: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var showingSuccess = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section("Vehicle Information") {
                    TextField("Make (e.g., Toyota)", text: $make)
                    TextField("Model (e.g., Camry)", text: $model)
                    
                    Picker("Year", selection: $year) {
                        ForEach(2000...Calendar.current.component(.year, from: Date()), id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    
                    TextField("Color", text: $color)
                    TextField("License Plate", text: $licensePlate)
                    
                    Picker("Vehicle Type", selection: $vehicleType) {
                        ForEach(Vehicle.VehicleType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    
                    Stepper("Seats: \(seatingCapacity)", value: $seatingCapacity, in: 2...8)
                }
                
                Section("Amenities") {
                    ForEach(Vehicle.VehicleAmenity.allCases, id: \.self) { amenity in
                        HStack {
                            Image(systemName: amenity.icon)
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text(amenity.displayName)
                            
                            Spacer()
                            
                            if selectedAmenities.contains(amenity) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedAmenities.contains(amenity) {
                                selectedAmenities.remove(amenity)
                            } else {
                                selectedAmenities.insert(amenity)
                            }
                        }
                    }
                }
                
                Section("Photos") {
                    Button("Add Photos") {
                        showingImagePicker = true
                    }
                    
                    if !vehiclePhotos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(vehiclePhotos.indices, id: \.self) { index in
                                    Image(uiImage: vehiclePhotos[index])
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(8)
                                        .clipped()
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    Task {
                        await addVehicle()
                    }
                }
                .disabled(!canSave || vehicleService.isLoading)
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            MultiImagePicker(selectedImages: $vehiclePhotos)
        }
        .alert("Vehicle Added! 🚗", isPresented: $showingSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your vehicle has been added successfully!")
        }
    }
    
    private var canSave: Bool {
        !make.isEmpty && !model.isEmpty && !color.isEmpty && !licensePlate.isEmpty
    }
    
    private func addVehicle() async {
        let photoData = vehiclePhotos.compactMap { $0.jpegData(compressionQuality: 0.8) }
        
        let success = await vehicleService.addVehicle(
            make: make,
            model: model,
            year: year,
            color: color,
            licensePlate: licensePlate,
            vehicleType: vehicleType,
            seatingCapacity: seatingCapacity,
            amenities: Array(selectedAmenities),
            photos: photoData
        )
        
        if success {
            showingSuccess = true
        }
    }
}

// MARK: - Advanced Search View
struct AdvancedSearchView: View {
    @StateObject private var tripService = AdvancedTripService.shared
    @State private var filteredTrips: [Trip] = []
    @State private var showingFilters = false
    @State private var hasSearched = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Header
                HStack {
                    Text("Advanced Search")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button("Filters") {
                        showingFilters = true
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
                .padding()
                
                // Active Filters Display
                if hasActiveFilters {
                    ActiveFiltersView(filters: tripService.searchFilters)
                        .padding(.horizontal)
                }
                
                // Search Button
                Button("Search with Filters") {
                    Task {
                        await searchWithFilters()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(tripService.isLoading)
                
                if tripService.isLoading {
                    ProgressView("Searching...")
                        .padding()
                }
                
                // Results
                if hasSearched {
                    if filteredTrips.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No trips match your filters")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("Try adjusting your search criteria")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else {
                        List(filteredTrips) { trip in
                            EnhancedTripCard(trip: trip)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingFilters) {
            SearchFiltersView(filters: $tripService.searchFilters)
        }
    }
    
    private var hasActiveFilters: Bool {
        let filters = tripService.searchFilters
        return filters.priceRange != SearchFilters.default.priceRange ||
               filters.vehicleTypes != SearchFilters.default.vehicleTypes ||
               !filters.requiredAmenities.isEmpty ||
               filters.minRating > 0 ||
               filters.instantBooking ||
               filters.verifiedDriversOnly
    }
    
    private func searchWithFilters() async {
        filteredTrips = await tripService.searchTripsWithFilters(tripService.searchFilters)
        hasSearched = true
    }
}

struct ActiveFiltersView: View {
    let filters: SearchFilters
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if filters.priceRange != SearchFilters.default.priceRange {
                    FilterChip(text: "$\(Int(filters.priceRange.lowerBound))-\(Int(filters.priceRange.upperBound))")
                }
                
                if filters.minRating > 0 {
                    FilterChip(text: "★ \(String(format: "%.1f", filters.minRating))+")
                }
                
                if filters.instantBooking {
                    FilterChip(text: "Instant Booking")
                }
                
                if filters.verifiedDriversOnly {
                    FilterChip(text: "Verified Drivers")
                }
                
                ForEach(Array(filters.requiredAmenities).prefix(2), id: \.self) { amenity in
                    FilterChip(text: amenity.displayName)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FilterChip: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(12)
    }
}

// MARK: - Search Filters View
struct SearchFiltersView: View {
    @Binding var filters: SearchFilters
    @State private var localFilters: SearchFilters
    @Environment(\.presentationMode) var presentationMode
    
    init(filters: Binding<SearchFilters>) {
        self._filters = filters
        self._localFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Price Range") {
                    VStack {
                        HStack {
                            Text("$\(Int(localFilters.priceRange.lowerBound))")
                            Spacer()
                            Text("$\(Int(localFilters.priceRange.upperBound))")
                        }
                        
                        // Note: This is a simplified range selector
                        // In a real app, you'd use a custom range slider
                        HStack {
                            Text("Min: $\(Int(localFilters.priceRange.lowerBound))")
                            Slider(value: Binding(
                                get: { localFilters.priceRange.lowerBound },
                                set: { newValue in
                                    localFilters.priceRange = newValue...localFilters.priceRange.upperBound
                                }
                            ), in: 0...200, step: 5)
                        }
                        
                        HStack {
                            Text("Max: $\(Int(localFilters.priceRange.upperBound))")
                            Slider(value: Binding(
                                get: { localFilters.priceRange.upperBound },
                                set: { newValue in
                                    localFilters.priceRange = localFilters.priceRange.lowerBound...newValue
                                }
                            ), in: 0...200, step: 5)
                        }
                    }
                }
                
                Section("Vehicle Types") {
                    ForEach(Vehicle.VehicleType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text(type.displayName)
                            
                            Spacer()
                            
                            if localFilters.vehicleTypes.contains(type) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if localFilters.vehicleTypes.contains(type) {
                                localFilters.vehicleTypes.remove(type)
                            } else {
                                localFilters.vehicleTypes.insert(type)
                            }
                        }
                    }
                }
                
                Section("Required Amenities") {
                    ForEach(Vehicle.VehicleAmenity.allCases, id: \.self) { amenity in
                        HStack {
                            Image(systemName: amenity.icon)
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text(amenity.displayName)
                            
                            Spacer()
                            
                            if localFilters.requiredAmenities.contains(amenity) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if localFilters.requiredAmenities.contains(amenity) {
                                localFilters.requiredAmenities.remove(amenity)
                            } else {
                                localFilters.requiredAmenities.insert(amenity)
                            }
                        }
                    }
                }
                
                Section("Driver Preferences") {
                    HStack {
                        Text("Minimum Rating")
                        Spacer()
                        Text(String(format: "%.1f", localFilters.minRating))
                    }
                    
                    Slider(value: $localFilters.minRating, in: 0...5, step: 0.1)
                    
                    Toggle("Instant Booking Only", isOn: $localFilters.instantBooking)
                    Toggle("Verified Drivers Only", isOn: $localFilters.verifiedDriversOnly)
                }
                
                Section("Trip Preferences") {
                    Stepper("Max Detour: \(localFilters.maxDetourMinutes) mins",
                           value: $localFilters.maxDetourMinutes,
                           in: 0...60,
                           step: 5)
                }
            }
            .navigationTitle("Search Filters")
            .navigationBarItems(
                leading: Button("Reset") {
                    localFilters = SearchFilters.default
                },
                trailing: Button("Apply") {
                    filters = localFilters
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Driver Dashboard View
struct DriverDashboardView: View {
    @StateObject private var tripService = AdvancedTripService.shared
    @State private var selectedTimeFrame = 0
    private let timeFrames = ["Week", "Month", "Year", "All Time"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Driver Dashboard")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Picker("Time Frame", selection: $selectedTimeFrame) {
                            ForEach(timeFrames.indices, id: \.self) { index in
                                Text(timeFrames[index]).tag(index)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding()
                    
                    if let analytics = tripService.driverAnalytics {
                        // Earnings Overview
                        EarningsOverviewCard(analytics: analytics, timeFrame: timeFrames[selectedTimeFrame])
                        
                        // Performance Metrics
                        PerformanceMetricsCard(analytics: analytics)
                        
                        // Environmental Impact
                        EnvironmentalImpactCard(analytics: analytics)
                        
                        // Top Routes
                        TopRoutesCard(routes: analytics.topRoutes)
                        
                        // Earnings Chart
                        EarningsChartCard(history: analytics.earningsHistory)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct EarningsOverviewCard: View {
    let analytics: DriverAnalytics
    let timeFrame: String
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Earnings Overview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("$\(String(format: "%.2f", analytics.monthlyEarnings))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("This Month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("$\(String(format: "%.2f", analytics.totalEarnings))")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Total Earned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(analytics.monthlyTrips)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Trips This Month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("$\(String(format: "%.2f", analytics.monthlyEarnings / Double(max(analytics.monthlyTrips, 1))))")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Avg per Trip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct PerformanceMetricsCard: View {
    let analytics: DriverAnalytics
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Performance")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 30) {
                VStack {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", analytics.averageRating))
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Text("Rating")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(analytics.totalTrips)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total Trips")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(String(format: "%.1f", analytics.totalDistance)) mi")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct EnvironmentalImpactCard: View {
    let analytics: DriverAnalytics
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                Text("Environmental Impact")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 30) {
                VStack {
                    Text("$\(String(format: "%.0f", analytics.fuelSavings))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Fuel Saved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(String(format: "%.1f", analytics.co2Reduced)) lbs")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("CO₂ Reduced")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct TopRoutesCard: View {
    let routes: [DriverAnalytics.RouteStats]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Top Routes")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(routes) { route in
                HStack {
                    VStack(alignment: .leading) {
                        Text(route.route)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(route.tripCount) trips • $\(String(format: "%.2f", route.totalEarnings))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", route.averageRating))
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
}

struct EarningsChartCard: View {
    let history: [DriverAnalytics.EarningsRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Earnings Trend (Last 30 Days)")
                .font(.headline)
                .padding(.horizontal)
            
            // Simple bar chart representation
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(history.suffix(14)) { record in
                        VStack {
                            Rectangle()
                                .fill(Color.green.opacity(0.7))
                                .frame(width: 20, height: max(record.amount / 10, 2))
                            
                            Text(record.date.formatted(.dateTime.day()))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 120)
        }
        .padding(.vertical)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

// MARK: - Multi Image Picker
struct MultiImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: MultiImagePicker
        
        init(_ parent: MultiImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImages.append(image)
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
