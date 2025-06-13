//
//  APIService.swift
//  RoadBuddy
//
//  Created by Sylvester Kpei on 6/9/25.
//
// APIService.swift - Handles all backend communication
import Foundation

// MARK: - Data Models
struct Trip: Codable, Identifiable {
    let id: String
    let driverID: String
    let driverName: String
    let driverRating: Double
    let fromCity: String
    let toCity: String
    let departureDate: String
    let departureTime: String
    let availableSeats: Int
    let pricePerPerson: Double
    let description: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case driverID = "driver_id"
        case driverName = "driver_name"
        case driverRating = "driver_rating"
        case fromCity = "from_city"
        case toCity = "to_city"
        case departureDate = "departure_date"
        case departureTime = "departure_time"
        case availableSeats = "available_seats"
        case pricePerPerson = "price_per_person"
        case description
        case status
    }
}

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let phone: String
    let rating: Double
    let tripsCompleted: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, rating
        case tripsCompleted = "trips_completed"
    }
}

struct Booking: Codable, Identifiable {
    let id: String
    let tripID: String
    let userID: String
    let passengerCount: Int
    let totalPrice: Double
    let status: String
    let bookingDate: String
    let trip: Trip?
    
    enum CodingKeys: String, CodingKey {
        case id
        case tripID = "trip_id"
        case userID = "user_id"
        case passengerCount = "passenger_count"
        case totalPrice = "total_price"
        case status
        case bookingDate = "booking_date"
        case trip
    }
}

// MARK: - API Response Models
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: String?
}

struct TripsResponse: Codable {
    let success: Bool
    let trips: [Trip]
    let count: Int
}

struct TripResponse: Codable {
    let success: Bool
    let trip: Trip
}

struct BookingResponse: Codable {
    let success: Bool
    let message: String
    let booking: Booking
}

struct UserResponse: Codable {
    let success: Bool
    let user: User
}

struct BookingsResponse: Codable {
    let success: Bool
    let bookings: [Booking]
    let count: Int
}

// MARK: - API Service
class APIService: ObservableObject {
    static let shared = APIService()
    private let baseURL = "http://localhost:5000/api"
    
    private init() {}
    
    // MARK: - Trip Endpoints
    
    /// Fetch all available trips
    func fetchTrips() async throws -> [Trip] {
        let url = URL(string: "\(baseURL)/trips")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(TripsResponse.self, from: data)
        
        if response.success {
            return response.trips
        } else {
            throw APIError.serverError("Failed to fetch trips")
        }
    }
    
    /// Search trips with filters
    func searchTrips(from: String?, to: String?, date: String?) async throws -> [Trip] {
        var components = URLComponents(string: "\(baseURL)/trips/search")!
        var queryItems: [URLQueryItem] = []
        
        if let from = from, !from.isEmpty {
            queryItems.append(URLQueryItem(name: "from", value: from))
        }
        if let to = to, !to.isEmpty {
            queryItems.append(URLQueryItem(name: "to", value: to))
        }
        if let date = date, !date.isEmpty {
            queryItems.append(URLQueryItem(name: "date", value: date))
        }
        
        components.queryItems = queryItems
        
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let response = try JSONDecoder().decode(TripsResponse.self, from: data)
        
        if response.success {
            return response.trips
        } else {
            throw APIError.serverError("Failed to search trips")
        }
    }
    
    /// Create a new trip
    func createTrip(
        driverName: String,
        fromCity: String,
        toCity: String,
        departureDate: String,
        departureTime: String,
        availableSeats: Int,
        pricePerPerson: Double,
        description: String
    ) async throws -> Trip {
        let url = URL(string: "\(baseURL)/trips")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let tripData = [
            "driver_name": driverName,
            "from_city": fromCity,
            "to_city": toCity,
            "departure_date": departureDate,
            "departure_time": departureTime,
            "available_seats": availableSeats,
            "price_per_person": pricePerPerson,
            "description": description
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: tripData)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TripResponse.self, from: data)
        
        if response.success {
            return response.trip
        } else {
            throw APIError.serverError("Failed to create trip")
        }
    }
    
    /// Book a trip
    func bookTrip(tripID: String, userID: String, passengerCount: Int) async throws -> Booking {
        let url = URL(string: "\(baseURL)/trips/\(tripID)/book")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bookingData = [
            "user_id": userID,
            "passenger_count": passengerCount
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: bookingData)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(BookingResponse.self, from: data)
        
        if response.success {
            return response.booking
        } else {
            throw APIError.serverError("Failed to book trip")
        }
    }
    
    // MARK: - User Endpoints
    
    /// Get user profile
    func fetchUser(userID: String) async throws -> User {
        let url = URL(string: "\(baseURL)/users/\(userID)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(UserResponse.self, from: data)
        
        if response.success {
            return response.user
        } else {
            throw APIError.serverError("Failed to fetch user")
        }
    }
    
    /// Get user's bookings
    func fetchUserBookings(userID: String) async throws -> [Booking] {
        let url = URL(string: "\(baseURL)/users/\(userID)/bookings")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(BookingsResponse.self, from: data)
        
        if response.success {
            return response.bookings
        } else {
            throw APIError.serverError("Failed to fetch bookings")
        }
    }
}

// MARK: - Error Handling
enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .serverError(let message):
            return message
        }
    }
}

// MARK: - Date Helpers
extension DateFormatter {
    static let apiDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static let apiTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

// MARK: - View Model for Trip Management
@MainActor
class TripViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func loadTrips() async {
        isLoading = true
        errorMessage = nil
        
        do {
            trips = try await apiService.fetchTrips()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func searchTrips(from: String?, to: String?, date: Date?) async {
        isLoading = true
        errorMessage = nil
        
        let dateString = date?.formatted(.iso8601.year().month().day())
        
        do {
            trips = try await apiService.searchTrips(from: from, to: to, date: dateString)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createTrip(
        driverName: String,
        fromCity: String,
        toCity: String,
        departureDate: Date,
        departureTime: Date,
        availableSeats: Int,
        pricePerPerson: Double,
        description: String
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        let dateString = DateFormatter.apiDate.string(from: departureDate)
        let timeString = DateFormatter.apiTime.string(from: departureTime)
        
        do {
            let newTrip = try await apiService.createTrip(
                driverName: driverName,
                fromCity: fromCity,
                toCity: toCity,
                departureDate: dateString,
                departureTime: timeString,
                availableSeats: availableSeats,
                pricePerPerson: pricePerPerson,
                description: description
            )
            
            trips.append(newTrip)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
