// EnhancedBookingSystem.swift - Add this as a new file
import SwiftUI
import Foundation

// MARK: - Enhanced Booking Models
enum BookingStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case confirmed = "confirmed"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .confirmed: return .green
        case .completed: return .blue
        case .cancelled: return .red
        }
    }
}

// MARK: - Booking Service
class BookingService: ObservableObject {
    static let shared = BookingService()
    @Published var userBookings: [Booking] = []
    @Published var userPostedTrips: [Trip] = []
    @Published var isLoading = false
    
    private let apiService = APIService.shared
    
    private init() {
        loadStoredBookings()
        loadStoredPostedTrips()
    }
    
    // MARK: - Book a Trip
    func bookTrip(
        trip: Trip,
        passengerCount: Int,
        pickupLocation: String?,
        dropoffLocation: String?
    ) async -> Bool {
        guard let currentUser = AuthService.shared.currentUser else {
            return false
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let booking = try await apiService.bookTrip(
                tripID: trip.id,
                userID: currentUser.id,
                passengerCount: passengerCount
            )
            
            await MainActor.run {
                // Add booking to local list
                userBookings.append(booking)
                
                // Store in UserDefaults for persistence
                storeBookings()
                isLoading = false
            }
            
            return true
        } catch {
            print("Booking error: \(error)")
            await MainActor.run {
                isLoading = false
            }
            return false
        }
    }
    
    // MARK: - Load User Data
    func loadUserData() async {
        guard let currentUser = AuthService.shared.currentUser else { return }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Load bookings
            let bookings = try await apiService.fetchUserBookings(userID: currentUser.id)
            
            await MainActor.run {
                userBookings = bookings
                storeBookings()
            }
        } catch {
            print("Failed to load user bookings: \(error)")
            // Load from local storage if API fails
            await MainActor.run {
                loadStoredBookings()
            }
        }
        
        // Load posted trips (we'll add this API endpoint later)
        await loadPostedTrips()
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Add Posted Trip
    func addPostedTrip(_ trip: Trip) async {
        await MainActor.run {
            userPostedTrips.append(trip)
            storePostedTrips()
        }
    }
    
    private func loadPostedTrips() async {
        // Load from local storage for now
        await MainActor.run {
            loadStoredPostedTrips()
        }
    }
    
    // MARK: - Cancel Booking
    func cancelBooking(bookingID: String) async -> Bool {
        await MainActor.run {
            isLoading = true
        }
        
        // In real app, call API to cancel booking
        await MainActor.run {
            if let index = userBookings.firstIndex(where: { $0.id == bookingID }) {
                // For now, just remove the booking since we can't modify the status
                // In a real app, you'd update the booking status via API
                userBookings.remove(at: index)
                storeBookings()
            }
            isLoading = false
        }
        
        return true
    }
    
    // MARK: - Storage
    private func storeBookings() {
        if let data = try? JSONEncoder().encode(userBookings) {
            UserDefaults.standard.set(data, forKey: "user_bookings")
        }
    }
    
    private func loadStoredBookings() {
        if let data = UserDefaults.standard.data(forKey: "user_bookings"),
           let bookings = try? JSONDecoder().decode([Booking].self, from: data) {
            userBookings = bookings
        }
    }
    
    private func storePostedTrips() {
        if let data = try? JSONEncoder().encode(userPostedTrips) {
            UserDefaults.standard.set(data, forKey: "user_posted_trips")
        }
    }
    
    private func loadStoredPostedTrips() {
        if let data = UserDefaults.standard.data(forKey: "user_posted_trips"),
           let trips = try? JSONDecoder().decode([Trip].self, from: data) {
            userPostedTrips = trips
        }
    }
}

// MARK: - Enhanced Booking View
struct EnhancedBookingView: View {
    let trip: Trip
    @StateObject private var bookingService = BookingService.shared
    @State private var passengerCount = 1
    @State private var pickupLocation = ""
    @State private var dropoffLocation = ""
    @State private var showingPickupPicker = false
    @State private var showingDropoffPicker = false
    @State private var isBooking = false
    @State private var bookingSuccess = false
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    
    var totalPrice: Double {
        trip.pricePerPerson * Double(passengerCount)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Trip Summary
                    TripSummaryCard(trip: trip)
                    
                    // Booking Details
                    VStack(spacing: 15) {
                        Text("Booking Details")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Passenger count
                        HStack {
                            Text("Passengers")
                            Spacer()
                            Stepper("\(passengerCount)", value: $passengerCount, in: 1...trip.availableSeats)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        
                        // Pickup location
                        VStack {
                            HStack {
                                Text("Pickup Location")
                                Spacer()
                                Button("Set") {
                                    showingPickupPicker = true
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            
                            if !pickupLocation.isEmpty {
                                Text(pickupLocation)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text("Tap 'Set' to choose pickup location")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        
                        // Dropoff location
                        VStack {
                            HStack {
                                Text("Drop-off Location")
                                Spacer()
                                Button("Set") {
                                    showingDropoffPicker = true
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            
                            if !dropoffLocation.isEmpty {
                                Text(dropoffLocation)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text("Tap 'Set' to choose drop-off location")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // Price breakdown
                    VStack(spacing: 10) {
                        Text("Price Breakdown")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            Text("$\(Int(trip.pricePerPerson)) × \(passengerCount) passenger\(passengerCount > 1 ? "s" : "")")
                            Spacer()
                            Text("$\(Int(totalPrice))")
                                .fontWeight(.bold)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Text("$\(Int(totalPrice))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    if let errorMessage = errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    // Book button
                    Button("Confirm Booking - $\(Int(totalPrice))") {
                        Task {
                            await bookTrip()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background((isBooking || trip.availableSeats == 0) ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isBooking || trip.availableSeats == 0)
                    
                    if isBooking {
                        ProgressView("Processing booking...")
                    }
                }
                .padding()
            }
            .navigationTitle("Book Trip")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showingPickupPicker) {
            LocationSelectionView(
                selectedLocation: $pickupLocation,
                title: "Pickup Location",
                nearCity: trip.fromCity
            )
        }
        .sheet(isPresented: $showingDropoffPicker) {
            LocationSelectionView(
                selectedLocation: $dropoffLocation,
                title: "Drop-off Location",
                nearCity: trip.toCity
            )
        }
        .alert("Booking Confirmed!", isPresented: $bookingSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your trip has been booked successfully! Check 'My Trips' for details.")
        }
    }
    
    private func bookTrip() async {
        isBooking = true
        errorMessage = nil
        
        let success = await bookingService.bookTrip(
            trip: trip,
            passengerCount: passengerCount,
            pickupLocation: pickupLocation.isEmpty ? nil : pickupLocation,
            dropoffLocation: dropoffLocation.isEmpty ? nil : dropoffLocation
        )
        
        if success {
            bookingSuccess = true
        } else {
            errorMessage = "Failed to book trip. Please try again."
        }
        
        isBooking = false
    }
}

// MARK: - Trip Summary Card
struct TripSummaryCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Trip Summary")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(trip.fromCity) → \(trip.toCity)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(trip.departureDate) at \(trip.departureTime)")
                        .foregroundColor(.secondary)
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
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Location Selection View
struct LocationSelectionView: View {
    @Binding var selectedLocation: String
    let title: String
    let nearCity: String
    @Environment(\.presentationMode) var presentationMode
    
    // Common locations for demo
    private var commonLocations: [String] {
        [
            "\(nearCity) Train Station",
            "\(nearCity) Airport",
            "\(nearCity) Downtown",
            "\(nearCity) Mall",
            "\(nearCity) University",
            "Custom Location..."
        ]
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Common Locations") {
                    ForEach(commonLocations, id: \.self) { location in
                        Button(location) {
                            selectedLocation = location
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Enhanced My Trips View
struct EnhancedMyTripsView: View {
    @StateObject private var bookingService = BookingService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Tab selector
                Picker("Trip Type", selection: $selectedTab) {
                    Text("My Bookings").tag(0)
                    Text("My Posted Trips").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    MyBookingsView()
                } else {
                    MyPostedTripsView()
                }
            }
            .navigationTitle("My Trips")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await bookingService.loadUserData()
            }
        }
    }
}

// MARK: - My Bookings View
struct MyBookingsView: View {
    @StateObject private var bookingService = BookingService.shared
    
    var body: some View {
        if bookingService.isLoading {
            ProgressView("Loading your trips...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if bookingService.userBookings.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "car.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("No trips booked yet")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("Browse available trips and book your first ride!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(bookingService.userBookings) { booking in
                        BookingCard(booking: booking)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - My Posted Trips View
struct MyPostedTripsView: View {
    @StateObject private var bookingService = BookingService.shared
    
    var body: some View {
        if bookingService.userPostedTrips.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("No trips posted yet")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("Offer a ride and help others travel!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(bookingService.userPostedTrips) { trip in
                        PostedTripCard(trip: trip)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Booking Card
struct BookingCard: View {
    let booking: Booking
    @StateObject private var bookingService = BookingService.shared
    @State private var showingCancelAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status badge
            HStack {
                Text(booking.status.capitalized)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(booking.status == "confirmed" ? Color.green : Color.orange)
                    .cornerRadius(8)
                
                Spacer()
                
                Text("$\(Int(booking.totalPrice))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            if let trip = booking.trip {
                // Trip details
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(trip.fromCity) → \(trip.toCity)")
                        .font(.headline)
                    
                    Text("\(trip.departureDate) at \(trip.departureTime)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Driver: \(trip.driverName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(booking.passengerCount) passenger\(booking.passengerCount > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Action buttons
            if booking.status == "confirmed" {
                HStack {
                    NavigationLink(destination: LiveTripTrackingView(booking: booking)) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Track Trip")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Button("Cancel Trip") {
                        showingCancelAlert = true
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
        .alert("Cancel Trip", isPresented: $showingCancelAlert) {
            Button("Cancel", role: .destructive) {
                Task {
                    await bookingService.cancelBooking(bookingID: booking.id)
                }
            }
            Button("Keep Trip", role: .cancel) { }
        } message: {
            Text("Are you sure you want to cancel this trip? This action cannot be undone.")
        }
    }
}

// MARK: - Posted Trip Card
struct PostedTripCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("YOUR TRIP")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(8)
                
                Spacer()
                
                Text("$\(Int(trip.pricePerPerson))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("\(trip.fromCity) → \(trip.toCity)")
                    .font(.headline)
                
                Text("\(trip.departureDate) at \(trip.departureTime)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(trip.availableSeats) seats available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Button("Edit Trip") {
                    // TODO: Implement trip editing
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("View Bookings") {
                    // TODO: Show who booked this trip
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
