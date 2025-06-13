// CleanEnhancedProfiles.swift - Add this as a new file instead
import SwiftUI
import PhotosUI

// MARK: - Enhanced User Model
struct EnhancedUser: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let phone: String
    let rating: Double
    let tripsCompleted: Int
    let profileImageData: Data?
    let bio: String?
    let joinDate: Date
    let verificationStatus: VerificationStatus
    let preferences: UserPreferences
    let badges: [UserBadge]
    
    enum VerificationStatus: String, Codable, CaseIterable {
        case unverified = "unverified"
        case phoneVerified = "phone_verified"
        case emailVerified = "email_verified"
        case fullVerified = "full_verified"
        
        var displayName: String {
            switch self {
            case .unverified: return "Unverified"
            case .phoneVerified: return "Phone Verified"
            case .emailVerified: return "Email Verified"
            case .fullVerified: return "Fully Verified"
            }
        }
        
        var color: Color {
            switch self {
            case .unverified: return .gray
            case .phoneVerified: return .orange
            case .emailVerified: return .blue
            case .fullVerified: return .green
            }
        }
        
        var icon: String {
            switch self {
            case .unverified: return "person.crop.circle"
            case .phoneVerified: return "phone.circle.fill"
            case .emailVerified: return "envelope.circle.fill"
            case .fullVerified: return "checkmark.shield.fill"
            }
        }
    }
}

struct UserPreferences: Codable {
    let musicPreference: String?
    let smokingAllowed: Bool
    let petsAllowed: Bool
    let conversationLevel: ConversationLevel
    let maxDetourMinutes: Int
    
    enum ConversationLevel: String, Codable, CaseIterable {
        case quiet = "quiet"
        case some = "some"
        case chatty = "chatty"
        
        var displayName: String {
            switch self {
            case .quiet: return "Quiet ride"
            case .some: return "Some conversation"
            case .chatty: return "Love to chat"
            }
        }
        
        var icon: String {
            switch self {
            case .quiet: return "speaker.slash"
            case .some: return "speaker.2"
            case .chatty: return "speaker.3"
            }
        }
    }
}

struct UserBadge: Codable, Identifiable {
    let id: String
    let type: BadgeType
    let earnedDate: Date
    let description: String
    
    enum BadgeType: String, Codable, CaseIterable {
        case earlyAdopter = "early_adopter"
        case frequentTraveler = "frequent_traveler"
        case highRated = "high_rated"
        case safeDriving = "safe_driving"
        case helpful = "helpful"
        case punctual = "punctual"
        
        var displayName: String {
            switch self {
            case .earlyAdopter: return "Early Adopter"
            case .frequentTraveler: return "Frequent Traveler"
            case .highRated: return "Highly Rated"
            case .safeDriving: return "Safe Driver"
            case .helpful: return "Helpful"
            case .punctual: return "Always On Time"
            }
        }
        
        var icon: String {
            switch self {
            case .earlyAdopter: return "star.circle.fill"
            case .frequentTraveler: return "airplane.circle.fill"
            case .highRated: return "heart.circle.fill"
            case .safeDriving: return "car.circle.fill"
            case .helpful: return "hands.sparkles.fill"
            case .punctual: return "clock.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .earlyAdopter: return .purple
            case .frequentTraveler: return .blue
            case .highRated: return .red
            case .safeDriving: return .green
            case .helpful: return .orange
            case .punctual: return .yellow
            }
        }
    }
}

// MARK: - Review Model
struct TripReview: Codable, Identifiable {
    let id: String
    let tripID: String
    let reviewerID: String
    let reviewerName: String
    let revieweeID: String
    let revieweeName: String
    let rating: Int // 1-5 stars
    let comment: String?
    let categories: [ReviewCategory]
    let createdAt: Date
    let isDriverReview: Bool // true if reviewing driver, false if reviewing passenger
    
    struct ReviewCategory: Codable {
        let category: String
        let rating: Int
        
        static let driverCategories = [
            "Safety", "Punctuality", "Communication", "Vehicle Condition"
        ]
        
        static let passengerCategories = [
            "Punctuality", "Communication", "Respectfulness"
        ]
    }
}

// MARK: - Profile Service
class ProfileService: ObservableObject {
    static let shared = ProfileService()
    
    @Published var enhancedUser: EnhancedUser?
    @Published var userReviews: [TripReview] = []
    @Published var receivedRatings: [TripReview] = []
    @Published var isLoading = false
    
    private init() {
        loadEnhancedProfile()
        loadReviews()
    }
    
    // MARK: - Profile Management
    func updateProfileImage(_ imageData: Data) async {
        await MainActor.run {
            if let user = enhancedUser {
                enhancedUser = EnhancedUser(
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    phone: user.phone,
                    rating: user.rating,
                    tripsCompleted: user.tripsCompleted,
                    profileImageData: imageData,
                    bio: user.bio,
                    joinDate: user.joinDate,
                    verificationStatus: user.verificationStatus,
                    preferences: user.preferences,
                    badges: user.badges
                )
                storeEnhancedProfile()
            }
        }
    }
    
    func updateBio(_ bio: String) {
        guard let user = enhancedUser else { return }
        
        enhancedUser = EnhancedUser(
            id: user.id,
            name: user.name,
            email: user.email,
            phone: user.phone,
            rating: user.rating,
            tripsCompleted: user.tripsCompleted,
            profileImageData: user.profileImageData,
            bio: bio,
            joinDate: user.joinDate,
            verificationStatus: user.verificationStatus,
            preferences: user.preferences,
            badges: user.badges
        )
        storeEnhancedProfile()
    }
    
    func updatePreferences(_ preferences: UserPreferences) {
        guard let user = enhancedUser else { return }
        
        enhancedUser = EnhancedUser(
            id: user.id,
            name: user.name,
            email: user.email,
            phone: user.phone,
            rating: user.rating,
            tripsCompleted: user.tripsCompleted,
            profileImageData: user.profileImageData,
            bio: user.bio,
            joinDate: user.joinDate,
            verificationStatus: user.verificationStatus,
            preferences: preferences,
            badges: user.badges
        )
        storeEnhancedProfile()
    }
    
    // MARK: - Reviews & Ratings
    func submitReview(
        tripID: String,
        revieweeID: String,
        revieweeName: String,
        rating: Int,
        comment: String?,
        categoryRatings: [TripReview.ReviewCategory],
        isDriverReview: Bool
    ) async {
        guard let currentUser = AuthService.shared.currentUser else { return }
        
        let review = TripReview(
            id: UUID().uuidString,
            tripID: tripID,
            reviewerID: currentUser.id,
            reviewerName: currentUser.name,
            revieweeID: revieweeID,
            revieweeName: revieweeName,
            rating: rating,
            comment: comment,
            categories: categoryRatings,
            createdAt: Date(),
            isDriverReview: isDriverReview
        )
        
        await MainActor.run {
            userReviews.insert(review, at: 0)
            storeReviews()
        }
    }
    
    // MARK: - Storage
    private func storeEnhancedProfile() {
        if let user = enhancedUser,
           let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "enhanced_user_profile")
        }
    }
    
    private func loadEnhancedProfile() {
        if let data = UserDefaults.standard.data(forKey: "enhanced_user_profile"),
           let user = try? JSONDecoder().decode(EnhancedUser.self, from: data) {
            enhancedUser = user
        } else {
            createEnhancedProfileFromBasic()
        }
    }
    
    private func createEnhancedProfileFromBasic() {
        guard let basicUser = AuthService.shared.currentUser else { return }
        
        let defaultPreferences = UserPreferences(
            musicPreference: nil,
            smokingAllowed: false,
            petsAllowed: true,
            conversationLevel: .some,
            maxDetourMinutes: 10
        )
        
        enhancedUser = EnhancedUser(
            id: basicUser.id,
            name: basicUser.name,
            email: basicUser.email,
            phone: basicUser.phone,
            rating: basicUser.rating,
            tripsCompleted: basicUser.tripsCompleted,
            profileImageData: nil,
            bio: nil,
            joinDate: Date(),
            verificationStatus: .unverified,
            preferences: defaultPreferences,
            badges: []
        )
        storeEnhancedProfile()
    }
    
    private func storeReviews() {
        if let data = try? JSONEncoder().encode(userReviews) {
            UserDefaults.standard.set(data, forKey: "user_reviews")
        }
    }
    
    private func loadReviews() {
        if let data = UserDefaults.standard.data(forKey: "user_reviews"),
           let reviews = try? JSONDecoder().decode([TripReview].self, from: data) {
            userReviews = reviews
        }
        
        loadDemoReceivedRatings()
    }
    
    private func loadDemoReceivedRatings() {
        let demoReviews = [
            TripReview(
                id: "demo1",
                tripID: "trip1",
                reviewerID: "user2",
                reviewerName: "Sarah M.",
                revieweeID: AuthService.shared.currentUser?.id ?? "user1",
                revieweeName: AuthService.shared.currentUser?.name ?? "You",
                rating: 5,
                comment: "Great passenger! Very punctual and friendly.",
                categories: [
                    TripReview.ReviewCategory(category: "Punctuality", rating: 5),
                    TripReview.ReviewCategory(category: "Communication", rating: 5),
                    TripReview.ReviewCategory(category: "Respectfulness", rating: 5)
                ],
                createdAt: Date().addingTimeInterval(-86400),
                isDriverReview: false
            )
        ]
        
        receivedRatings = demoReviews
    }
}

// MARK: - Profile Views
struct CleanProfileHeaderView: View {
    let user: EnhancedUser?
    @Binding var showingImagePicker: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            // Profile Image
            Button(action: { showingImagePicker = true }) {
                Group {
                    if let imageData = user?.profileImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .shadow(radius: 2)
                )
                .overlay(
                    Image(systemName: "camera.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .background(Color.white)
                        .clipShape(Circle())
                        .offset(x: 35, y: 35)
                )
            }
            
            if let user = user {
                VStack(spacing: 8) {
                    Text(user.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let bio = user.bio {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                    
                    // Stats Row
                    HStack(spacing: 30) {
                        VStack(spacing: 4) {
                            Text("\(user.tripsCompleted)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Trips")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text(String(format: "%.1f", user.rating))
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= Int(user.rating.rounded()) ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                }
                            }
                            
                            Text("Rating")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text(user.joinDate.formatted(.dateTime.year()))
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Member Since")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

// MARK: - Review Submission View
struct ReviewSubmissionView: View {
    let trip: Trip
    let revieweeID: String
    let revieweeName: String
    let isDriverReview: Bool
    
    @StateObject private var profileService = ProfileService.shared
    @State private var rating = 5
    @State private var comment = ""
    @State private var categoryRatings: [String: Int] = [:]
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    @Environment(\.presentationMode) var presentationMode
    
    private var categories: [String] {
        isDriverReview ? TripReview.ReviewCategory.driverCategories : TripReview.ReviewCategory.passengerCategories
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Trip Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rate Your Experience")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(trip.fromCity) → \(trip.toCity)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("with \(revieweeName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Overall Rating
                    VStack(spacing: 15) {
                        Text("Overall Rating")
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: { rating = star }) {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.title)
                                        .foregroundColor(star <= rating ? .yellow : .gray)
                                }
                            }
                        }
                        
                        Text(getRatingText(rating))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Category Ratings
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Category Ratings")
                            .font(.headline)
                        
                        ForEach(categories, id: \.self) { category in
                            HStack {
                                Text(category)
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: 4) {
                                    ForEach(1...5, id: \.self) { star in
                                        Button(action: { categoryRatings[category] = star }) {
                                            Image(systemName: star <= (categoryRatings[category] ?? 5) ? "star.fill" : "star")
                                                .foregroundColor(star <= (categoryRatings[category] ?? 5) ? .yellow : .gray)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Comment
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Comments (Optional)")
                            .font(.headline)
                        
                        TextField("Share your experience...", text: $comment, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    Spacer()
                    
                    // Submit Button
                    Button("Submit Review") {
                        Task {
                            await submitReview()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isSubmitting)
                    
                    if isSubmitting {
                        ProgressView("Submitting review...")
                    }
                }
                .padding()
            }
            .navigationTitle("Review")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert("Review Submitted! 🌟", isPresented: $showingSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Thank you for your feedback!")
        }
        .onAppear {
            // Initialize category ratings
            for category in categories {
                categoryRatings[category] = 5
            }
        }
    }
    
    private func submitReview() async {
        isSubmitting = true
        
        let categoryReviews = categoryRatings.map { key, value in
            TripReview.ReviewCategory(category: key, rating: value)
        }
        
        await profileService.submitReview(
            tripID: trip.id,
            revieweeID: revieweeID,
            revieweeName: revieweeName,
            rating: rating,
            comment: comment.isEmpty ? nil : comment,
            categoryRatings: categoryReviews,
            isDriverReview: isDriverReview
        )
        
        isSubmitting = false
        showingSuccess = true
    }
    
    private func getRatingText(_ rating: Int) -> String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent"
        default: return ""
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
