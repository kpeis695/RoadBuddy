# RoadBuddy
Modern rideshare app for long-distance travel - iOS + Python Flask
# RoadBuddy 🚗

A modern, full-stack rideshare application for long-distance travel, connecting drivers and passengers for cost-effective journey sharing.

## 🌟 Features

### Core Functionality
- **Trip Posting & Booking** - Drivers post future trips, passengers book seats
- **Real-Time Tracking** - Live location tracking during trips
- **Payment Processing** - Secure credit card payments with split billing
- **User Authentication** - Secure login/signup with persistent sessions

### Advanced Features
- **Interactive Maps** - Route visualization with distance/time estimates
- **Rating System** - 5-star ratings and detailed reviews
- **Vehicle Management** - Add cars with photos and amenities
- **Driver Dashboard** - Earnings analytics and performance metrics
- **Push Notifications** - Trip updates and booking confirmations
- **Advanced Search** - Filter by price, vehicle type, and amenities

## 🛠 Tech Stack

### Frontend (iOS)
- **SwiftUI** - Modern iOS UI framework
- **MapKit** - Route visualization and location services
- **Core Location** - GPS tracking and location management
- **UserNotifications** - Push notification system

### Backend
- **Python Flask** - RESTful API server
- **SQLite** - Local database for development
- **Flask-CORS** - Cross-origin resource sharing


## 🚀 Getting Started

### Prerequisites
- iOS 15.0+ / Xcode 14+
- Python 3.8+
- pip (Python package manager)

### Backend Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/roadbuddy.git
   cd roadbuddy/Backend
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run the server**
   ```bash
   python app.py
   ```

   The API will be available at `http://localhost:5000`

### iOS Setup

1. **Open the project**
   ```bash
   cd ../iOS
   open RoadBuddy.xcodeproj
   ```

2. **Configure the project**
   - Set your development team in project settings
   - Update bundle identifier if needed

3. **Run the app**
   - Select a simulator or device
   - Press ⌘+R to build and run

## 📖 API Documentation

### Endpoints

#### Trips
- `GET /api/trips` - Get all available trips
- `POST /api/trips` - Create a new trip
- `GET /api/trips/search` - Search trips by criteria
- `POST /api/trips/{id}/book` - Book a trip

#### Users
- `POST /api/auth/login` - User login
- `POST /api/auth/signup` - User registration
- `GET /api/users/{id}/bookings` - Get user bookings

#### Health Check
- `GET /api/health` - Server health status

### Example Response
```json
{
  "id": "1",
  "driverName": "Sarah M.",
  "route": "New York → Boston",
  "departureTime": "2025-06-15T09:00:00Z",
  "availableSeats": 3,
  "pricePerPerson": 45.0,
  "estimatedDuration": "4h 30m"
}
```

## 🏗 Architecture

```
┌─────────────────┐    HTTP/REST     ┌─────────────────┐
│   iOS App       │ ◄──────────────► │  Flask Backend  │
│   (SwiftUI)     │                  │   (Python)      │
└─────────────────┘                  └─────────────────┘
        │                                     │
        ▼                                     ▼
┌─────────────────┐                  ┌─────────────────┐
│   Local Storage │                  │   SQLite DB     │
│   (UserDefaults)│                  │                 │
└─────────────────┘                  └─────────────────┘
```

## 🔮 Future Enhancements

- [ ] **Real-time Chat** - WebSocket messaging between drivers and passengers
- [ ] **Route Optimization** - AI-powered route suggestions with multiple stops
- [ ] **Carbon Footprint** - Environmental impact tracking and gamification
- [ ] **Push Notifications** - Enhanced notification system with rich content
- [ ] **Admin Dashboard** - Web-based management interface
- [ ] **Production Database** - PostgreSQL with proper scaling
- [ ] **Cloud Deployment** - AWS/Heroku deployment with CI/CD

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Your Name**
- GitHub: [@kpeis695](https://github.com/kpeis695)
- LinkedIn: [Sylvester Kpei](https://linkedin.com/in/ks200)
- Email: sek266@cornell.edu

## 🙏 Acknowledgments

- Built during summer 2025 as a learning project
- Inspired by modern rideshare platforms like BlaBlaCar
- Thanks to the SwiftUI and Flask communities for excellent documentation

---

⭐ If you found this project helpful, please give it a star on GitHub!
