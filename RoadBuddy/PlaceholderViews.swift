//
//  PlaceholderViews.swift
//  RoadBuddy
//
//  Created by Sylvester Kpei on 6/10/25.
//
// PlaceholderViews.swift - Add this as a new file
import SwiftUI

// MARK: - Edit Profile View
struct SimpleEditProfileView: View {
    @StateObject private var profileService = ProfileService.shared
    @State private var name = ""
    @State private var bio = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Full Name", text: $name)
                    
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("About") {
                    Text("Update your profile information here. Changes will be saved automatically.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    profileService.updateBio(bio)
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                if let user = profileService.enhancedUser {
                    name = user.name
                    bio = user.bio ?? ""
                }
            }
        }
    }
}

// MARK: - Trip Preferences View
struct SimpleTripPreferencesView: View {
    @StateObject private var profileService = ProfileService.shared
    @State private var musicPreference = ""
    @State private var smokingAllowed = false
    @State private var petsAllowed = true
    @State private var conversationLevel = UserPreferences.ConversationLevel.some
    @State private var maxDetourMinutes = 10
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section("Trip Preferences") {
                    HStack {
                        Text("Music Preference")
                        Spacer()
                        TextField("Any", text: $musicPreference)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Toggle("Smoking Allowed", isOn: $smokingAllowed)
                    Toggle("Pets Allowed", isOn: $petsAllowed)
                    
                    Picker("Conversation Level", selection: $conversationLevel) {
                        ForEach(UserPreferences.ConversationLevel.allCases, id: \.self) { level in
                            HStack {
                                Image(systemName: level.icon)
                                Text(level.displayName)
                            }
                            .tag(level)
                        }
                    }
                    
                    Stepper("Max Detour: \(maxDetourMinutes) mins", value: $maxDetourMinutes, in: 0...30, step: 5)
                }
                
                Section("About Preferences") {
                    Text("These preferences help match you with compatible travel companions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Trip Preferences")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    let preferences = UserPreferences(
                        musicPreference: musicPreference.isEmpty ? nil : musicPreference,
                        smokingAllowed: smokingAllowed,
                        petsAllowed: petsAllowed,
                        conversationLevel: conversationLevel,
                        maxDetourMinutes: maxDetourMinutes
                    )
                    profileService.updatePreferences(preferences)
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                if let user = profileService.enhancedUser {
                    musicPreference = user.preferences.musicPreference ?? ""
                    smokingAllowed = user.preferences.smokingAllowed
                    petsAllowed = user.preferences.petsAllowed
                    conversationLevel = user.preferences.conversationLevel
                    maxDetourMinutes = user.preferences.maxDetourMinutes
                }
            }
        }
    }
}

// MARK: - Reviews List View
struct SimpleReviewsListView: View {
    @StateObject private var profileService = ProfileService.shared
    @State private var selectedSegment = 0
    
    var body: some View {
        VStack {
            Picker("Reviews", selection: $selectedSegment) {
                Text("Received").tag(0)
                Text("Given").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if selectedSegment == 0 {
                // Received Reviews
                if profileService.receivedRatings.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No reviews received yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Complete more trips to start receiving reviews!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    List(profileService.receivedRatings) { review in
                        SimpleReviewRow(review: review)
                    }
                }
            } else {
                // Given Reviews
                if profileService.userReviews.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "pencil.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No reviews given yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("After completing trips, you can review your experience!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    List(profileService.userReviews) { review in
                        SimpleReviewRow(review: review)
                    }
                }
            }
        }
        .navigationTitle("Reviews & Ratings")
    }
}

struct SimpleReviewRow: View {
    let review: TripReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(review.reviewerName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= review.rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
            }
            
            if let comment = review.comment, !comment.isEmpty {
                Text(comment)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Help & Support View
struct HelpSupportView: View {
    @State private var selectedQuestion: String?
    
    private let faqItems = [
        ("How do I book a trip?", "Simply search for your destination, select a trip that matches your schedule, and tap 'Book'. You'll need to add a payment method first."),
        ("How do I become a driver?", "Add your vehicle in the 'My Vehicles' section, verify your insurance, and start posting trips!"),
        ("What if I need to cancel?", "You can cancel confirmed trips from the 'My Trips' section. Cancellation policies may apply."),
        ("How do payments work?", "Payments are processed securely through our payment system. Funds are transferred after trip completion."),
        ("What about safety?", "All users go through verification. We recommend meeting in public places and sharing trip details with friends."),
        ("How are ratings calculated?", "Ratings are based on passenger and driver reviews after each completed trip.")
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section("Frequently Asked Questions") {
                    ForEach(faqItems, id: \.0) { question, answer in
                        DisclosureGroup(question) {
                            Text(answer)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        }
                    }
                }
                
                Section("Contact Support") {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                        Text("Email Support")
                        Spacer()
                        Text("support@roadbuddy.com")
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.green)
                        Text("Call Support")
                        Spacer()
                        Text("1-800-ROADBUDDY")
                            .foregroundColor(.blue)
                    }
                }
                
                Section("App Information") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Help & Support")
        }
    }
}
