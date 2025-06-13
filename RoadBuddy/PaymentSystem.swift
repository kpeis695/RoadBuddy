// PaymentSystem.swift - Add this as a new file
import SwiftUI
import Foundation

// MARK: - Payment Models
struct PaymentMethod: Codable, Identifiable {
    let id: String
    let type: PaymentType
    let last4: String
    let brand: String
    let expiryMonth: Int
    let expiryYear: Int
    let isDefault: Bool
    let nickname: String?
    
    enum PaymentType: String, Codable {
        case card = "card"
        case paypal = "paypal"
        case applePay = "apple_pay"
        
        var displayName: String {
            switch self {
            case .card: return "Credit Card"
            case .paypal: return "PayPal"
            case .applePay: return "Apple Pay"
            }
        }
        
        var icon: String {
            switch self {
            case .card: return "creditcard.fill"
            case .paypal: return "globe"
            case .applePay: return "apple.logo"
            }
        }
    }
    
    var displayName: String {
        if let nickname = nickname {
            return nickname
        }
        return "\(brand) •••• \(last4)"
    }
}

struct PaymentTransaction: Codable, Identifiable {
    let id: String
    let tripID: String
    let amount: Double
    let currency: String
    let status: TransactionStatus
    let paymentMethodID: String
    let createdAt: Date
    let description: String
    let refundAmount: Double?
    
    enum TransactionStatus: String, Codable {
        case pending = "pending"
        case completed = "completed"
        case failed = "failed"
        case refunded = "refunded"
        case partialRefund = "partial_refund"
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .completed: return "Completed"
            case .failed: return "Failed"
            case .refunded: return "Refunded"
            case .partialRefund: return "Partial Refund"
            }
        }
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .completed: return .green
            case .failed: return .red
            case .refunded: return .blue
            case .partialRefund: return .blue
            }
        }
    }
    
    var formattedAmount: String {
        return String(format: "$%.2f", amount)
    }
}

// MARK: - Payment Service
class PaymentService: ObservableObject {
    static let shared = PaymentService()
    
    @Published var paymentMethods: [PaymentMethod] = []
    @Published var transactions: [PaymentTransaction] = []
    @Published var isProcessing = false
    @Published var defaultPaymentMethod: PaymentMethod?
    
    private init() {
        loadStoredPaymentMethods()
        loadStoredTransactions()
        loadDefaultPaymentMethod()
    }
    
    // MARK: - Payment Processing
    func processPayment(
        amount: Double,
        paymentMethodID: String,
        tripID: String,
        description: String
    ) async -> Bool {
        await MainActor.run {
            isProcessing = true
        }
        
        // Simulate payment processing delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // In real app, this would call Stripe API
        let success = simulatePaymentProcessing()
        
        if success {
            let transaction = PaymentTransaction(
                id: UUID().uuidString,
                tripID: tripID,
                amount: amount,
                currency: "USD",
                status: .completed,
                paymentMethodID: paymentMethodID,
                createdAt: Date(),
                description: description,
                refundAmount: nil
            )
            
            await MainActor.run {
                transactions.insert(transaction, at: 0)
                storeTransactions()
                isProcessing = false
            }
        } else {
            await MainActor.run {
                isProcessing = false
            }
        }
        
        return success
    }
    
    private func simulatePaymentProcessing() -> Bool {
        // 90% success rate for demo
        return Double.random(in: 0...1) > 0.1
    }
    
    // MARK: - Payment Methods Management
    func addPaymentMethod(
        cardNumber: String,
        expiryMonth: Int,
        expiryYear: Int,
        cvc: String,
        nickname: String?
    ) async -> Bool {
        await MainActor.run {
            isProcessing = true
        }
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Validate card (basic validation)
        guard isValidCardNumber(cardNumber) else {
            await MainActor.run { isProcessing = false }
            return false
        }
        
        let brand = getCardBrand(cardNumber)
        let last4 = String(cardNumber.suffix(4))
        let isFirstCard = paymentMethods.isEmpty
        
        let paymentMethod = PaymentMethod(
            id: UUID().uuidString,
            type: .card,
            last4: last4,
            brand: brand,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            isDefault: isFirstCard,
            nickname: nickname
        )
        
        await MainActor.run {
            paymentMethods.append(paymentMethod)
            
            if isFirstCard {
                defaultPaymentMethod = paymentMethod
                storeDefaultPaymentMethod()
            }
            
            storePaymentMethods()
            isProcessing = false
        }
        
        return true
    }
    
    func setDefaultPaymentMethod(_ paymentMethod: PaymentMethod) {
        // Update all payment methods
        paymentMethods = paymentMethods.map { method in
            PaymentMethod(
                id: method.id,
                type: method.type,
                last4: method.last4,
                brand: method.brand,
                expiryMonth: method.expiryMonth,
                expiryYear: method.expiryYear,
                isDefault: method.id == paymentMethod.id,
                nickname: method.nickname
            )
        }
        
        defaultPaymentMethod = paymentMethod
        storePaymentMethods()
        storeDefaultPaymentMethod()
    }
    
    func removePaymentMethod(_ paymentMethod: PaymentMethod) {
        paymentMethods.removeAll { $0.id == paymentMethod.id }
        
        if defaultPaymentMethod?.id == paymentMethod.id {
            defaultPaymentMethod = paymentMethods.first
            storeDefaultPaymentMethod()
        }
        
        storePaymentMethods()
    }
    
    // MARK: - Refunds
    func processRefund(transactionID: String, amount: Double) async -> Bool {
        await MainActor.run {
            isProcessing = true
        }
        
        // Simulate refund processing
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        if let index = transactions.firstIndex(where: { $0.id == transactionID }) {
            let originalTransaction = transactions[index]
            let newStatus: PaymentTransaction.TransactionStatus =
                amount >= originalTransaction.amount ? .refunded : .partialRefund
            
            let updatedTransaction = PaymentTransaction(
                id: originalTransaction.id,
                tripID: originalTransaction.tripID,
                amount: originalTransaction.amount,
                currency: originalTransaction.currency,
                status: newStatus,
                paymentMethodID: originalTransaction.paymentMethodID,
                createdAt: originalTransaction.createdAt,
                description: originalTransaction.description,
                refundAmount: amount
            )
            
            await MainActor.run {
                transactions[index] = updatedTransaction
                storeTransactions()
                isProcessing = false
            }
            
            return true
        }
        
        await MainActor.run {
            isProcessing = false
        }
        return false
    }
    
    // MARK: - Card Validation
    private func isValidCardNumber(_ cardNumber: String) -> Bool {
        let cleaned = cardNumber.replacingOccurrences(of: " ", with: "")
        return cleaned.count >= 13 && cleaned.count <= 19 && cleaned.allSatisfy(\.isNumber)
    }
    
    private func getCardBrand(_ cardNumber: String) -> String {
        let cleaned = cardNumber.replacingOccurrences(of: " ", with: "")
        
        if cleaned.hasPrefix("4") {
            return "Visa"
        } else if cleaned.hasPrefix("5") || (cleaned.hasPrefix("2") && cleaned.count >= 2) {
            return "Mastercard"
        } else if cleaned.hasPrefix("3") {
            return "American Express"
        } else {
            return "Unknown"
        }
    }
    
    // MARK: - Storage
    private func storePaymentMethods() {
        if let data = try? JSONEncoder().encode(paymentMethods) {
            UserDefaults.standard.set(data, forKey: "payment_methods")
        }
    }
    
    private func loadStoredPaymentMethods() {
        if let data = UserDefaults.standard.data(forKey: "payment_methods"),
           let methods = try? JSONDecoder().decode([PaymentMethod].self, from: data) {
            paymentMethods = methods
        }
    }
    
    private func storeTransactions() {
        if let data = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(data, forKey: "payment_transactions")
        }
    }
    
    private func loadStoredTransactions() {
        if let data = UserDefaults.standard.data(forKey: "payment_transactions"),
           let stored = try? JSONDecoder().decode([PaymentTransaction].self, from: data) {
            transactions = stored
        }
    }
    
    private func storeDefaultPaymentMethod() {
        if let method = defaultPaymentMethod,
           let data = try? JSONEncoder().encode(method) {
            UserDefaults.standard.set(data, forKey: "default_payment_method")
        }
    }
    
    private func loadDefaultPaymentMethod() {
        if let data = UserDefaults.standard.data(forKey: "default_payment_method"),
           let method = try? JSONDecoder().decode(PaymentMethod.self, from: data) {
            defaultPaymentMethod = method
        }
    }
}

// MARK: - Enhanced Booking View with Payment
struct PaymentBookingView: View {
    let trip: Trip
    @StateObject private var paymentService = PaymentService.shared
    @State private var passengerCount = 1
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var showingPaymentMethods = false
    @State private var showingAddCard = false
    @State private var isProcessingPayment = false
    @State private var paymentSuccess = false
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
                    
                    // Passenger Selection
                    if trip.availableSeats > 0 {
                        VStack(spacing: 15) {
                            Text("Trip Details")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack {
                                Text("Passengers")
                                Spacer()
                                Stepper("\(passengerCount)", value: $passengerCount, in: 1...trip.availableSeats)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    
                    // Payment Method Selection
                    VStack(spacing: 15) {
                        HStack {
                            Text("Payment Method")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("Manage") {
                                showingPaymentMethods = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        if let paymentMethod = selectedPaymentMethod ?? paymentService.defaultPaymentMethod {
                            PaymentMethodRow(paymentMethod: paymentMethod, isSelected: true)
                                .onTapGesture {
                                    showingPaymentMethods = true
                                }
                        } else {
                            Button("Add Payment Method") {
                                showingAddCard = true
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                        }
                    }
                    
                    // Price Breakdown
                    PriceBreakdownView(
                        pricePerPerson: trip.pricePerPerson,
                        passengerCount: passengerCount,
                        totalPrice: totalPrice
                    )
                    
                    if let errorMessage = errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    // Payment Button
                    Button("Pay \(String(format: "$%.2f", totalPrice))") {
                        Task {
                            await processPayment()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canPay ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(!canPay || isProcessingPayment)
                    
                    if isProcessingPayment {
                        ProgressView("Processing payment...")
                    }
                }
                .padding()
            }
            .navigationTitle("Payment")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showingPaymentMethods) {
            PaymentMethodsView(selectedPaymentMethod: $selectedPaymentMethod)
        }
        .sheet(isPresented: $showingAddCard) {
            AddPaymentMethodView()
        }
        .alert("Payment Successful! 🎉", isPresented: $paymentSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your trip has been booked and payment processed successfully!")
        }
        .onAppear {
            selectedPaymentMethod = paymentService.defaultPaymentMethod
        }
    }
    
    private var canPay: Bool {
        trip.availableSeats > 0 &&
        (selectedPaymentMethod != nil || paymentService.defaultPaymentMethod != nil) &&
        !isProcessingPayment
    }
    
    private func processPayment() async {
        guard let paymentMethod = selectedPaymentMethod ?? paymentService.defaultPaymentMethod else {
            errorMessage = "Please select a payment method"
            return
        }
        
        isProcessingPayment = true
        errorMessage = nil
        
        let success = await paymentService.processPayment(
            amount: totalPrice,
            paymentMethodID: paymentMethod.id,
            tripID: trip.id,
            description: "Trip from \(trip.fromCity) to \(trip.toCity)"
        )
        
        if success {
            // Also book the trip
            let bookingSuccess = await BookingService.shared.bookTrip(
                trip: trip,
                passengerCount: passengerCount,
                pickupLocation: nil,
                dropoffLocation: nil
            )
            
            if bookingSuccess {
                paymentSuccess = true
                RealTimeService.shared.sendBookingConfirmation(tripID: trip.id)
            } else {
                errorMessage = "Payment processed but booking failed. Please contact support."
            }
        } else {
            errorMessage = "Payment failed. Please try again or use a different payment method."
        }
        
        isProcessingPayment = false
    }
}

// MARK: - Price Breakdown View
struct PriceBreakdownView: View {
    let pricePerPerson: Double
    let passengerCount: Int
    let totalPrice: Double
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Price Breakdown")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                HStack {
                    Text("\(String(format: "$%.2f", pricePerPerson)) × \(passengerCount) passenger\(passengerCount > 1 ? "s" : "")")
                    Spacer()
                    Text(String(format: "$%.2f", totalPrice))
                }
                
                HStack {
                    Text("Service fee")
                    Spacer()
                    Text("$0.00")
                        .foregroundColor(.green)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Text(String(format: "$%.2f", totalPrice))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Payment Methods View
struct PaymentMethodsView: View {
    @Binding var selectedPaymentMethod: PaymentMethod?
    @StateObject private var paymentService = PaymentService.shared
    @State private var showingAddCard = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                if paymentService.paymentMethods.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "creditcard.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No payment methods")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Add a payment method to book trips")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Add Payment Method") {
                            showingAddCard = true
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                } else {
                    List {
                        Section("Payment Methods") {
                            ForEach(paymentService.paymentMethods) { method in
                                PaymentMethodRow(
                                    paymentMethod: method,
                                    isSelected: selectedPaymentMethod?.id == method.id
                                )
                                .onTapGesture {
                                    selectedPaymentMethod = method
                                    presentationMode.wrappedValue.dismiss()
                                }
                                .swipeActions {
                                    Button("Delete", role: .destructive) {
                                        paymentService.removePaymentMethod(method)
                                    }
                                    
                                    if !method.isDefault {
                                        Button("Set Default") {
                                            paymentService.setDefaultPaymentMethod(method)
                                        }
                                        .tint(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Payment Methods")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    showingAddCard = true
                }
            )
        }
        .sheet(isPresented: $showingAddCard) {
            AddPaymentMethodView()
        }
    }
}

// MARK: - Payment Method Row
struct PaymentMethodRow: View {
    let paymentMethod: PaymentMethod
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: paymentMethod.type.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(paymentMethod.displayName)
                    .font(.headline)
                
                HStack {
                    Text("Expires \(paymentMethod.expiryMonth)/\(paymentMethod.expiryYear)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if paymentMethod.isDefault {
                        Text("• DEFAULT")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(10)
    }
}

// MARK: - Add Payment Method View
struct AddPaymentMethodView: View {
    @StateObject private var paymentService = PaymentService.shared
    @State private var cardNumber = ""
    @State private var expiryMonth = ""
    @State private var expiryYear = ""
    @State private var cvc = ""
    @State private var nickname = ""
    @State private var showingSuccess = false
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Card Preview
                    CreditCardPreview(
                        cardNumber: cardNumber,
                        expiryMonth: expiryMonth,
                        expiryYear: expiryYear
                    )
                    
                    // Form
                    VStack(spacing: 15) {
                        TextField("Card Number", text: $cardNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: cardNumber) {
                                cardNumber = formatCardNumber(cardNumber)
                            }
                        
                        HStack {
                            TextField("MM", text: $expiryMonth)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .frame(maxWidth: 60)
                            
                            Text("/")
                                .font(.title2)
                            
                            TextField("YY", text: $expiryYear)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .frame(maxWidth: 60)
                            
                            Spacer()
                            
                            TextField("CVC", text: $cvc)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .frame(maxWidth: 80)
                        }
                        
                        TextField("Nickname (optional)", text: $nickname)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    if let errorMessage = errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Button("Add Card") {
                        Task {
                            await addCard()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canAddCard ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(!canAddCard || paymentService.isProcessing)
                    
                    if paymentService.isProcessing {
                        ProgressView("Adding card...")
                    }
                }
                .padding()
            }
            .navigationTitle("Add Payment Method")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert("Card Added Successfully! 🎉", isPresented: $showingSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private var canAddCard: Bool {
        !cardNumber.isEmpty &&
        !expiryMonth.isEmpty &&
        !expiryYear.isEmpty &&
        !cvc.isEmpty &&
        cardNumber.replacingOccurrences(of: " ", with: "").count >= 13
    }
    
    private func addCard() async {
        errorMessage = nil
        
        guard let month = Int(expiryMonth), month >= 1 && month <= 12 else {
            errorMessage = "Invalid expiry month"
            return
        }
        
        guard let year = Int(expiryYear), year >= 24 else {
            errorMessage = "Invalid expiry year"
            return
        }
        
        let success = await paymentService.addPaymentMethod(
            cardNumber: cardNumber.replacingOccurrences(of: " ", with: ""),
            expiryMonth: month,
            expiryYear: 2000 + year,
            cvc: cvc,
            nickname: nickname.isEmpty ? nil : nickname
        )
        
        if success {
            showingSuccess = true
        } else {
            errorMessage = "Failed to add card. Please check your details."
        }
    }
    
    private func formatCardNumber(_ input: String) -> String {
        let digits = input.replacingOccurrences(of: " ", with: "")
        let formatted = digits.enumerated().map { index, character in
            return (index % 4 == 0 && index > 0) ? " \(character)" : "\(character)"
        }.joined()
        return String(formatted.prefix(19)) // Max 16 digits + 3 spaces
    }
}

// MARK: - Credit Card Preview
struct CreditCardPreview: View {
    let cardNumber: String
    let expiryMonth: String
    let expiryYear: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("RoadBuddy")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "creditcard.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text(cardNumber.isEmpty ? "•••• •••• •••• ••••" : cardNumber)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .tracking(2)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("CARDHOLDER")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    Text("Your Name")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("EXPIRES")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(expiryMonth.isEmpty ? "MM" : expiryMonth)/\(expiryYear.isEmpty ? "YY" : expiryYear)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(20)
        .frame(height: 180)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(15)
        .shadow(radius: 10)
    }
}

// MARK: - Payment History View
struct PaymentHistoryView: View {
    @StateObject private var paymentService = PaymentService.shared
    
    var body: some View {
        NavigationView {
            Group {
                if paymentService.transactions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No transactions yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Your payment history will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(paymentService.transactions) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                }
            }
            .navigationTitle("Payment History")
        }
    }
}

struct TransactionRow: View {
    let transaction: PaymentTransaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(transaction.description)
                    .font(.headline)
                
                Spacer()
                
                Text(transaction.formattedAmount)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            HStack {
                Text(transaction.status.displayName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(transaction.status.color)
                    .cornerRadius(8)
                
                Spacer()
                
                Text(transaction.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let refundAmount = transaction.refundAmount {
                Text("Refunded: \(String(format: "$%.2f", refundAmount))")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}
