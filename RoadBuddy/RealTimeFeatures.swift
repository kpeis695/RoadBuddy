// RealTimeFeatures.swift - Add this as a new file
import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

// MARK: - Real-Time Trip Status
enum TripStatus: String, CaseIterable {
    case scheduled = "scheduled"
    case driverEnRoute = "driver_enroute"
    case arrived = "arrived"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .driverEnRoute: return "Driver En Route"
        case .arrived: return "Driver Arrived"
        case .inProgress: return "Trip In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .scheduled: return .blue
        case .driverEnRoute: return .orange
        case .arrived: return .green
        case .inProgress: return .purple
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .scheduled: return "clock"
        case .driverEnRoute: return "car.fill"
        case .arrived: return "location.circle.fill"
        case .inProgress: return "road.lanes"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}

// MARK: - Live Trip Data
struct LiveTripData {
    let tripID: String
    let driverLocation: CLLocationCoordinate2D?
    let status: TripStatus
    let estimatedArrival: String?
    let lastUpdated: Date
    
    init(tripID: String, driverLocation: CLLocationCoordinate2D?, status: TripStatus, estimatedArrival: String?, lastUpdated: Date) {
        self.tripID = tripID
        self.driverLocation = driverLocation
        self.status = status
        self.estimatedArrival = estimatedArrival
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Real-Time Service
class RealTimeService: NSObject, ObservableObject {
    static let shared = RealTimeService()
    
    @Published var activeTripData: LiveTripData?
    @Published var isTracking = false
    @Published var notifications: [TripNotification] = []
    
    private var trackingTimer: Timer?
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        setupLocationManager()
        requestNotificationPermission()
        loadStoredNotifications()
    }
    
    // MARK: - Location Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Trip Tracking
    func startTracking(tripID: String) {
        isTracking = true
        
        // Start polling for live updates every 30 seconds
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await self.fetchLiveTripData(tripID: tripID)
            }
        }
        
        // Get initial data
        Task {
            await fetchLiveTripData(tripID: tripID)
        }
    }
    
    func stopTracking() {
        isTracking = false
        trackingTimer?.invalidate()
        trackingTimer = nil
        activeTripData = nil
    }
    
    private func fetchLiveTripData(tripID: String) async {
        // In real app, this would call your backend API
        // For demo, we'll simulate live data
        let simulatedStatuses: [TripStatus] = [.scheduled, .driverEnRoute, .arrived, .inProgress]
        let randomStatus = simulatedStatuses.randomElement() ?? .scheduled
        
        // Simulate driver moving (for demo)
        let baseLocation = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        let randomOffset = Double.random(in: -0.01...0.01)
        let driverLocation = CLLocationCoordinate2D(
            latitude: baseLocation.latitude + randomOffset,
            longitude: baseLocation.longitude + randomOffset
        )
        
        let liveData = LiveTripData(
            tripID: tripID,
            driverLocation: driverLocation,
            status: randomStatus,
            estimatedArrival: "5 mins",
            lastUpdated: Date()
        )
        
        await MainActor.run {
            let previousStatus = activeTripData?.status
            activeTripData = liveData
            
            // Send notification if status changed
            if let prevStatus = previousStatus, prevStatus != randomStatus {
                sendStatusNotification(newStatus: randomStatus)
            }
        }
    }
    
    // MARK: - Notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied")
            }
        }
    }
    
    func sendStatusNotification(newStatus: TripStatus) {
        let notification = TripNotification(
            id: UUID().uuidString,
            title: "Trip Update",
            message: "Your trip status changed to: \(newStatus.displayName)",
            timestamp: Date(),
            type: .statusUpdate
        )
        
        addNotification(notification)
        scheduleLocalNotification(notification)
    }
    
    func sendBookingConfirmation(tripID: String) {
        let notification = TripNotification(
            id: UUID().uuidString,
            title: "Booking Confirmed! 🎉",
            message: "Your trip has been successfully booked. You'll receive updates as your departure time approaches.",
            timestamp: Date(),
            type: .bookingConfirmed
        )
        
        addNotification(notification)
        scheduleLocalNotification(notification)
    }
    
    private func addNotification(_ notification: TripNotification) {
        notifications.insert(notification, at: 0) // Add to front
        storeNotifications()
        
        // Keep only last 50 notifications
        if notifications.count > 50 {
            notifications = Array(notifications.prefix(50))
        }
    }
    
    private func scheduleLocalNotification(_ notification: TripNotification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.message
        content.sound = .default
        content.badge = NSNumber(value: notifications.count)
        
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Storage
    private func storeNotifications() {
        if let data = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(data, forKey: "trip_notifications")
        }
    }
    
    private func loadStoredNotifications() {
        if let data = UserDefaults.standard.data(forKey: "trip_notifications"),
           let stored = try? JSONDecoder().decode([TripNotification].self, from: data) {
            notifications = stored
        }
    }
    
    func clearNotifications() {
        notifications.removeAll()
        storeNotifications()
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

// MARK: - Location Manager Delegate
extension RealTimeService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Handle location updates for driver tracking
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location permission granted")
        case .denied, .restricted:
            print("❌ Location permission denied")
        default:
            break
        }
    }
}

// MARK: - Trip Notification Model
struct TripNotification: Codable, Identifiable {
    let id: String
    let title: String
    let message: String
    let timestamp: Date
    let type: NotificationType
    
    enum NotificationType: String, Codable {
        case bookingConfirmed = "booking_confirmed"
        case statusUpdate = "status_update"
        case driverMessage = "driver_message"
        case tripReminder = "trip_reminder"
        
        var icon: String {
            switch self {
            case .bookingConfirmed: return "checkmark.circle.fill"
            case .statusUpdate: return "info.circle.fill"
            case .driverMessage: return "message.fill"
            case .tripReminder: return "clock.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .bookingConfirmed: return .green
            case .statusUpdate: return .blue
            case .driverMessage: return .purple
            case .tripReminder: return .orange
            }
        }
    }
}

// MARK: - Live Trip Tracking View
struct LiveTripTrackingView: View {
    let booking: Booking
    @StateObject private var realTimeService = RealTimeService.shared
    @StateObject private var locationService = LocationService()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        VStack(spacing: 0) {
            // Status Bar
            if let liveData = realTimeService.activeTripData {
                StatusBar(liveData: liveData)
                    .padding()
                    .background(liveData.status.color.opacity(0.1))
            }
            
            // Map View
            ZStack {
                Map(position: .constant(.region(region))) {
                    // Trip route markers
                    if let trip = booking.trip {
                        Marker(trip.fromCity, coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060))
                            .tint(.green)
                        
                        Marker(trip.toCity, coordinate: CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589))
                            .tint(.red)
                    }
                    
                    // Live driver location
                    if let driverLocation = realTimeService.activeTripData?.driverLocation {
                        Marker("Driver", coordinate: driverLocation)
                            .tint(.blue)
                    }
                }
                
                // Tracking indicator
                if realTimeService.isTracking {
                    VStack {
                        HStack {
                            Spacer()
                            HStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(realTimeService.isTracking ? 1.0 : 0.5)
                                    .animation(.easeInOut(duration: 1).repeatForever(), value: realTimeService.isTracking)
                                
                                Text("LIVE")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                            .padding()
                        }
                        Spacer()
                    }
                }
            }
            
            // Trip Details
            TripDetailsBottomSheet(booking: booking)
                .background(Color.white)
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .shadow(radius: 10)
        }
        .navigationTitle("Live Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            realTimeService.startTracking(tripID: booking.tripID)
        }
        .onDisappear {
            realTimeService.stopTracking()
        }
    }
}

// MARK: - Status Bar
struct StatusBar: View {
    let liveData: LiveTripData
    
    var body: some View {
        HStack {
            Image(systemName: liveData.status.icon)
                .foregroundColor(liveData.status.color)
            
            VStack(alignment: .leading) {
                Text(liveData.status.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let eta = liveData.estimatedArrival {
                    Text("ETA: \(eta)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("Updated \(timeAgo(liveData.lastUpdated))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 {
            return "\(seconds)s ago"
        } else {
            return "\(seconds/60)m ago"
        }
    }
}

// MARK: - Trip Details Bottom Sheet
struct TripDetailsBottomSheet: View {
    let booking: Booking
    @State private var showingMessages = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 6)
            
            if let trip = booking.trip {
                // Trip info
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("\(trip.fromCity) → \(trip.toCity)")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("$\(Int(booking.totalPrice))")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("Driver: \(trip.driverName)")
                        Spacer()
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", trip.driverRating))
                                .font(.caption)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    Text("\(booking.passengerCount) passenger\(booking.passengerCount > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Action buttons
                HStack(spacing: 15) {
                    Button(action: { showingMessages = true }) {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("Message Driver")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        // Call driver
                        if let url = URL(string: "tel://+1234567890") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Call Driver")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingMessages) {
            MessagingView(trip: booking.trip!)
        }
    }
}

// MARK: - Notifications View
struct NotificationsView: View {
    @StateObject private var realTimeService = RealTimeService.shared
    
    var body: some View {
        NavigationView {
            Group {
                if realTimeService.notifications.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No notifications yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("You'll receive updates about your trips here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(realTimeService.notifications) { notification in
                            NotificationRow(notification: notification)
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarItems(
                trailing: Button("Clear All") {
                    realTimeService.clearNotifications()
                }
                .disabled(realTimeService.notifications.isEmpty)
            )
        }
    }
}

struct NotificationRow: View {
    let notification: TripNotification
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.type.icon)
                .foregroundColor(notification.type.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                Text(notification.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Basic Messaging View
struct MessagingView: View {
    let trip: Trip
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                // Messages list
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                        }
                    }
                    .padding()
                }
                
                // Message input
                HStack {
                    TextField("Type a message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Send") {
                        sendMessage()
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Chat with \(trip.driverName)")
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                loadDemoMessages()
            }
        }
    }
    
    private func sendMessage() {
        let message = ChatMessage(
            id: UUID().uuidString,
            text: messageText,
            senderName: "You",
            isFromCurrentUser: true,
            timestamp: Date()
        )
        
        messages.append(message)
        messageText = ""
        
        // Simulate driver response after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let response = ChatMessage(
                id: UUID().uuidString,
                text: "Thanks for the message! I'll be there shortly. 🚗",
                senderName: trip.driverName,
                isFromCurrentUser: false,
                timestamp: Date()
            )
            messages.append(response)
        }
    }
    
    private func loadDemoMessages() {
        messages = [
            ChatMessage(
                id: "1",
                text: "Hi! I'm your driver for today's trip. Looking forward to the ride!",
                senderName: trip.driverName,
                isFromCurrentUser: false,
                timestamp: Date().addingTimeInterval(-3600)
            ),
            ChatMessage(
                id: "2",
                text: "Hello! Thank you, looking forward to it too!",
                senderName: "You",
                isFromCurrentUser: true,
                timestamp: Date().addingTimeInterval(-3500)
            )
        ]
    }
}

struct ChatMessage: Identifiable, Codable {
    let id: String
    let text: String
    let senderName: String
    let isFromCurrentUser: Bool
    let timestamp: Date
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding()
                    .background(message.isFromCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 250, alignment: message.isFromCurrentUser ? .trailing : .leading)
            
            if !message.isFromCurrentUser {
                Spacer()
            }
        }
    }
}

// MARK: - Helper Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
