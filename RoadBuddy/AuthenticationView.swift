// AuthenticationView.swift - Add this as a new file
import SwiftUI

// MARK: - Auth Response Models
struct AuthResponse: Codable {
    let success: Bool
    let message: String
    let user: User?
    let token: String?
}

// MARK: - Authentication Service
class AuthService: ObservableObject {
    static let shared = AuthService()
    @Published var currentUser: User?
    @Published var isLoggedIn = false
    @Published var isLoading = false
    
    private let baseURL = "http://localhost:5001/api/auth"
    
    private init() {
        loadStoredUser()
    }
    
    // MARK: - Login
    func login(email: String, password: String) async -> Bool {
        await MainActor.run {
            isLoading = true
        }
        
        // For demo purposes, accept any email/password
        // In real app, this would call your backend
        let demoUser = User(
            id: UUID().uuidString,
            name: "Demo User",
            email: email,
            phone: "+1234567890",
            rating: 4.8,
            tripsCompleted: 15
        )
        
        await MainActor.run {
            self.currentUser = demoUser
            self.isLoggedIn = true
            self.storeUser(demoUser)
            self.isLoading = false
        }
        
        return true
    }
    
    // MARK: - Sign Up
    func signUp(name: String, email: String, phone: String, password: String) async -> Bool {
        await MainActor.run {
            isLoading = true
        }
        
        // For demo purposes, just create a user directly
        // In real app, this would call your backend
        let newUser = User(
            id: UUID().uuidString,
            name: name,
            email: email,
            phone: phone,
            rating: 5.0,
            tripsCompleted: 0
        )
        
        await MainActor.run {
            self.currentUser = newUser
            self.isLoggedIn = true
            self.storeUser(newUser)
            self.isLoading = false
        }
        
        return true
    }
    
    // MARK: - Logout
    func logout() {
        currentUser = nil
        isLoggedIn = false
        clearStoredUser()
    }
    
    // MARK: - Storage
    private func storeUser(_ user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "stored_user")
            UserDefaults.standard.set(true, forKey: "is_logged_in")
        }
    }
    
    private func loadStoredUser() {
        if let userData = UserDefaults.standard.data(forKey: "stored_user"),
           let user = try? JSONDecoder().decode(User.self, from: userData),
           UserDefaults.standard.bool(forKey: "is_logged_in") {
            self.currentUser = user
            self.isLoggedIn = true
        }
    }
    
    private func clearStoredUser() {
        UserDefaults.standard.removeObject(forKey: "stored_user")
        UserDefaults.standard.set(false, forKey: "is_logged_in")
    }
}

// MARK: - Main Authentication View
struct AuthenticationView: View {
    @StateObject private var authService = AuthService.shared
    @State private var showingSignup = false
    
    var body: some View {
        if authService.isLoggedIn {
            MainAppView()
        } else {
            if showingSignup {
                SignupView(showingSignup: $showingSignup)
            } else {
                LoginView(showingSignup: $showingSignup)
            }
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @Binding var showingSignup: Bool
    @StateObject private var authService = AuthService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Logo and Title
            VStack(spacing: 20) {
                Image(systemName: "car.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("RoadBuddy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("Share the Journey, Split the Cost")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Login Form
            VStack(spacing: 20) {
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                if authService.isLoading {
                    ProgressView("Signing in...")
                        .padding()
                } else {
                    Button("Sign In") {
                        Task {
                            let success = await authService.login(email: email, password: password)
                            if !success {
                                errorMessage = "Invalid email or password"
                                showingError = true
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canLogin ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(!canLogin)
                }
                
                // Demo login button
                Button("Demo Login") {
                    Task {
                        // For demo, just create a fake user
                        let demoUser = User(
                            id: "demo_user",
                            name: "Demo User",
                            email: "demo@roadbuddy.com",
                            phone: "+1234567890",
                            rating: 4.8,
                            tripsCompleted: 12
                        )
                        await MainActor.run {
                            authService.currentUser = demoUser
                            authService.isLoggedIn = true
                        }
                    }
                }
                .foregroundColor(.blue)
            }
            .padding()
            
            Spacer()
            
            // Sign up link
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.gray)
                
                Button("Sign Up") {
                    showingSignup = true
                }
                .foregroundColor(.blue)
            }
            .padding(.bottom, 30)
        }
        .padding()
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var canLogin: Bool {
        !email.isEmpty && !password.isEmpty && !authService.isLoading
    }
}

// MARK: - Signup View
struct SignupView: View {
    @Binding var showingSignup: Bool
    @StateObject private var authService = AuthService.shared
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Create Account")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Join the RoadBuddy community")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Signup Form
                    VStack(spacing: 20) {
                        VStack(spacing: 15) {
                            TextField("Full Name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            
                            TextField("Phone Number", text: $phone)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                            
                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        if authService.isLoading {
                            ProgressView("Creating account...")
                                .padding()
                        } else {
                            Button("Create Account") {
                                if password != confirmPassword {
                                    errorMessage = "Passwords don't match"
                                    showingError = true
                                    return
                                }
                                
                                Task {
                                    let success = await authService.signUp(
                                        name: name,
                                        email: email,
                                        phone: phone,
                                        password: password
                                    )
                                    if !success {
                                        errorMessage = "Failed to create account"
                                        showingError = true
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSignup ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .disabled(!canSignup)
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    showingSignup = false
                }
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var canSignup: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        !phone.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !authService.isLoading
    }
}

// MARK: - Main App View (your existing ContentView)
struct MainAppView: View {
    @StateObject private var tripViewModel = TripViewModel()
    @StateObject private var authService = AuthService.shared
    @StateObject private var realTimeService = RealTimeService.shared
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .environmentObject(tripViewModel)
            
            SearchTripsView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .environmentObject(tripViewModel)
            
            PostTripView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Post Trip")
                }
                .environmentObject(tripViewModel)
            
            MyTripsView()
                .tabItem {
                    Image(systemName: "car.fill")
                    Text("My Trips")
                }
                .environmentObject(authService)
            
            NotificationsView()
                .tabItem {
                    Image(systemName: realTimeService.notifications.isEmpty ? "bell" : "bell.badge")
                        .foregroundColor(realTimeService.notifications.isEmpty ? .primary : .red)
                    Text("Notifications")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .environmentObject(authService)
        }
    }
}

// MARK: - Enhanced Profile View
struct EnhancedProfileView: View {
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
                        ProfileOptionRow(icon: "person.fill", title: "Edit Profile", action: {})
                        ProfileOptionRow(icon: "car.fill", title: "My Vehicles", action: {})
                        ProfileOptionRow(icon: "creditcard.fill", title: "Payment Methods", action: {})
                        ProfileOptionRow(icon: "star.fill", title: "Reviews", action: {})
                        ProfileOptionRow(icon: "questionmark.circle.fill", title: "Help & Support", action: {})
                        ProfileOptionRow(icon: "gearshape.fill", title: "Settings", action: { showingSettings = true })
                        
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
        }
    }
}

struct ProfileOptionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                    .foregroundColor(.blue)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
}
