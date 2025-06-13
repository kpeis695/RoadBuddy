// ContentView.swift - Now with authentication
import SwiftUI

struct ContentView: View {
    var body: some View {
        AuthenticationView()
    }
}

// HomeView.swift - Shows real trips from backend
struct HomeView: View {
    @EnvironmentObject var tripViewModel: TripViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("RoadBuddy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Share the Journey, Split the Cost")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    // Quick actions
                    VStack(spacing: 15) {
                        NavigationLink(destination: SearchTripsView().environmentObject(tripViewModel)) {
                            ActionButton(title: "Find a Ride", icon: "magnifyingglass", color: .blue)
                        }
                        
                        NavigationLink(destination: PostTripView().environmentObject(tripViewModel)) {
                            ActionButton(title: "Offer a Ride", icon: "car.fill", color: .green)
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // Real trips from backend
                    HStack {
                        Text("Available Trips")
                            .font(.headline)
                        
                        Spacer()
                        
                        if tripViewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(.horizontal)
                    
                    if let errorMessage = tripViewModel.errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    // Trip list
                    if tripViewModel.trips.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "car.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No trips available")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(tripViewModel.trips) { trip in
                                EnhancedTripCard(trip: trip)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
            .task {
                print("🔍 About to load trips from backend...")
                await tripViewModel.loadTrips()
                print("✅ Trips loaded: \(tripViewModel.trips.count)")
                print("📝 Trip details: \(tripViewModel.trips)")
            }
        }
    }
}

// SearchTripsView.swift - Search real backend data
struct SearchTripsView: View {
    @EnvironmentObject var tripViewModel: TripViewModel
    @State private var fromCity = ""
    @State private var toCity = ""
    @State private var selectedDate = Date()
    @State private var passengers = 1
    @State private var hasSearched = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Find Your Ride")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 15) {
                    // From city
                    HStack {
                        Image(systemName: "location.circle")
                        TextField("From city", text: $fromCity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // To city
                    HStack {
                        Image(systemName: "location.circle.fill")
                        TextField("To city", text: $toCity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Date picker
                    DatePicker("Travel Date", selection: $selectedDate, displayedComponents: .date)
                    
                    // Passengers
                    Stepper("Passengers: \(passengers)", value: $passengers, in: 1...4)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                Button("Search Trips") {
                    Task {
                        print("🔍 Searching trips...")
                        await tripViewModel.searchTrips(
                            from: fromCity.isEmpty ? nil : fromCity,
                            to: toCity.isEmpty ? nil : toCity,
                            date: selectedDate
                        )
                        hasSearched = true
                        print("✅ Search completed: \(tripViewModel.trips.count) trips found")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(tripViewModel.isLoading)
                
                NavigationLink(destination: AdvancedSearchView()) {
                    Text("Advanced Search & Filters")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(10)
                }
                
                // Search results
                VStack(alignment: .leading) {
                    HStack {
                        Text(hasSearched ? "Search Results" : "All Available Trips")
                            .font(.headline)
                        
                        Spacer()
                        
                        if tripViewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    if let errorMessage = tripViewModel.errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    if tripViewModel.trips.isEmpty && hasSearched {
                        VStack(spacing: 15) {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No trips found")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("Try different cities or dates")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(tripViewModel.trips) { trip in
                                    EnhancedTripCard(trip: trip)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .task {
                if !hasSearched {
                    await tripViewModel.loadTrips()
                }
            }
        }
    }
}

// PostTripView.swift - Posts to real backend
struct PostTripView: View {
    @EnvironmentObject var tripViewModel: TripViewModel
    @StateObject private var bookingService = BookingService.shared
    @State private var driverName = "You"
    @State private var fromCity = ""
    @State private var toCity = ""
    @State private var departureDate = Date()
    @State private var departureTime = Date()
    @State private var availableSeats = 1
    @State private var pricePerPerson = ""
    @State private var description = ""
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Offer a Ride")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 15) {
                        // Route information
                        Group {
                            TextField("From city", text: $fromCity)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("To city", text: $toCity)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Date and time
                        DatePicker("Departure Date", selection: $departureDate, displayedComponents: .date)
                        DatePicker("Departure Time", selection: $departureTime, displayedComponents: .hourAndMinute)
                        
                        // Trip details
                        Stepper("Available Seats: \(availableSeats)", value: $availableSeats, in: 1...7)
                        
                        TextField("Price per person ($)", text: $pricePerPerson)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                        TextField("Trip description (optional)", text: $description, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    if let errorMessage = tripViewModel.errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button("Post Trip") {
                        Task {
                            guard let price = Double(pricePerPerson), !fromCity.isEmpty, !toCity.isEmpty else {
                                return
                            }
                            
                            print("🚗 Posting trip: \(fromCity) → \(toCity)")
                            let success = await tripViewModel.createTrip(
                                driverName: driverName,
                                fromCity: fromCity,
                                toCity: toCity,
                                departureDate: departureDate,
                                departureTime: departureTime,
                                availableSeats: availableSeats,
                                pricePerPerson: price,
                                description: description
                            )
                            
                            if success {
                                showingSuccess = true
                                // Clear form
                                fromCity = ""
                                toCity = ""
                                pricePerPerson = ""
                                description = ""
                                availableSeats = 1
                                print("✅ Trip posted successfully!")
                                
                                // Add to user's posted trips
                                if let lastTrip = tripViewModel.trips.last {
                                    await bookingService.addPostedTrip(lastTrip)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canPostTrip ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(!canPostTrip || tripViewModel.isLoading)
                    
                    if tripViewModel.isLoading {
                        ProgressView("Posting trip...")
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
            .alert("Trip Posted!", isPresented: $showingSuccess) {
                Button("OK") { }
            } message: {
                Text("Your trip has been posted successfully!")
            }
        }
    }
    
    private var canPostTrip: Bool {
        !fromCity.isEmpty && !toCity.isEmpty && !pricePerPerson.isEmpty && Double(pricePerPerson) != nil
    }
}

// MyTripsView.swift - Enhanced with real functionality
struct MyTripsView: View {
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
            .navigationBarHidden(true)
            .task {
                await bookingService.loadUserData()
            }
        }
    }
}

// ProfileView.swift - Enhanced with authentication
struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingImagePicker = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Profile Header
                    VStack(spacing: 15) {
                        // Profile Image
                        Button(action: { showingImagePicker = true }) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.blue)
                        }
                        
                        if let user = authService.currentUser {
                            Text(user.name)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 20) {
                                VStack {
                                    Text("\(user.tripsCompleted)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("Trips")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text(String(format: "%.1f", user.rating))
                                            .fontWeight(.bold)
                                    }
                                    Text("Rating")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack {
                                    Text("Member")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("Since 2025")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    
                    // Profile Options
                    VStack(spacing: 15) {
                        ProfileOption(icon: "person.fill", title: "Edit Profile")
                        ProfileOption(icon: "car.fill", title: "My Vehicles")
                        ProfileOption(icon: "creditcard.fill", title: "Payment Methods")
                        ProfileOption(icon: "star.fill", title: "Reviews")
                        ProfileOption(icon: "questionmark.circle.fill", title: "Help & Support")
                        ProfileOption(icon: "gearshape.fill", title: "Settings")
                        
                        // Logout button
                        Button(action: {
                            authService.logout()
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square.fill")
                                    .foregroundColor(.red)
                                Text("Logout")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
    }
}

// Supporting Views
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color)
        .foregroundColor(.white)
        .cornerRadius(10)
    }
}

struct RealTripCard: View {
    let trip: Trip
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
                
                Button("Book Ride") {
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
        .sheet(isPresented: $showingBooking) {
            EnhancedBookingView(trip: trip)
        }
    }
}

struct BookingView: View {
    let trip: Trip
    @State private var passengerCount = 1
    @State private var isBooking = false
    @State private var bookingSuccess = false
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    
    var totalPrice: Double {
        trip.pricePerPerson * Double(passengerCount)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Trip details
                VStack(alignment: .leading, spacing: 10) {
                    Text("Book Your Ride")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\(trip.fromCity) → \(trip.toCity)")
                        .font(.headline)
                    
                    Text("\(trip.departureDate) at \(trip.departureTime)")
                        .foregroundColor(.secondary)
                    
                    Text("Driver: \(trip.driverName)")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Passenger selection
                VStack {
                    Stepper("Passengers: \(passengerCount)", value: $passengerCount, in: 1...trip.availableSeats)
                    
                    Text("Total: $\(Int(totalPrice))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
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
                Button("Book Trip - $\(Int(totalPrice))") {
                    Task {
                        await bookTrip()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isBooking ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(isBooking)
                
                if isBooking {
                    ProgressView("Booking trip...")
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert("Booking Confirmed!", isPresented: $bookingSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your trip has been booked successfully!")
        }
    }
    
    private func bookTrip() async {
        isBooking = true
        errorMessage = nil
        
        do {
            print("🎫 Booking trip: \(trip.id)")
            let _ = try await APIService.shared.bookTrip(
                tripID: trip.id,
                userID: "user1",
                passengerCount: passengerCount
            )
            bookingSuccess = true
            print("✅ Trip booked successfully!")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Booking failed: \(error)")
        }
        
        isBooking = false
    }
}

struct ProfileOption: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
