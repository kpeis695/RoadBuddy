from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import uuid
from datetime import datetime, timedelta

app = Flask(__name__)
CORS(app)

# Sample data (in production, this would be a database)
trips = [
    {
        "id": "1",
        "driverName": "Sarah M.",
        "driverRating": 4.8,
        "route": "New York → Boston",
        "departureCity": "New York",
        "destinationCity": "Boston", 
        "departureTime": "2025-06-15T09:00:00Z",
        "availableSeats": 3,
        "totalSeats": 4,
        "pricePerPerson": 45.0,
        "estimatedDuration": "4h 30m",
        "carModel": "Honda Accord",
        "amenities": ["WiFi", "AC", "Music"],
        "pickupPoints": ["Penn Station", "Times Square"],
        "description": "Comfortable ride to Boston with stops in Manhattan"
    },
    {
        "id": "2", 
        "driverName": "John D.",
        "driverRating": 4.6,
        "route": "Boston → New York",
        "departureCity": "Boston",
        "destinationCity": "New York",
        "departureTime": "2025-06-16T14:00:00Z",
        "availableSeats": 2,
        "totalSeats": 4,
        "pricePerPerson": 50.0,
        "estimatedDuration": "4h 45m",
        "carModel": "Toyota Camry",
        "amenities": ["AC", "Phone Charging"],
        "pickupPoints": ["South Station", "Back Bay"],
        "description": "Direct route to NYC with comfortable seating"
    },
    {
        "id": "3",
        "driverName": "Mike R.",
        "driverRating": 4.9,
        "route": "New York → Philadelphia", 
        "departureCity": "New York",
        "destinationCity": "Philadelphia",
        "departureTime": "2025-06-17T11:00:00Z",
        "availableSeats": 1,
        "totalSeats": 4,
        "pricePerPerson": 35.0,
        "estimatedDuration": "2h 15m",
        "carModel": "BMW 3 Series",
        "amenities": ["WiFi", "AC", "Music", "Snacks"],
        "pickupPoints": ["Penn Station"],
        "description": "Quick trip to Philly in luxury vehicle"
    }
]

bookings = []
users = [
    {
        "id": "demo-user",
        "name": "Demo User", 
        "email": "demo@roadbuddy.com",
        "phone": "+1-555-0123",
        "rating": 4.7,
        "tripsCompleted": 15
    }
]

@app.route('/')
def home():
    return jsonify({
        "message": "🚗 RoadBuddy API is Live!",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "trips": "/api/trips",
            "search": "/api/trips/search", 
            "health": "/api/health"
        }
    })

@app.route('/api/health')
def health_check():
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "service": "RoadBuddy API",
        "version": "1.0.0"
    })

@app.route('/api/trips', methods=['GET'])
def get_trips():
    try:
        return jsonify({
            "success": True,
            "trips": trips,
            "count": len(trips)
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/api/trips/search', methods=['GET'])
def search_trips():
    try:
        query = request.args.get('q', '').lower()
        departure = request.args.get('from', '').lower()
        destination = request.args.get('to', '').lower()
        
        filtered_trips = trips
        
        if query:
            filtered_trips = [t for t in filtered_trips if 
                            query in t['route'].lower() or 
                            query in t['departureCity'].lower() or 
                            query in t['destinationCity'].lower()]
        
        if departure:
            filtered_trips = [t for t in filtered_trips if 
                            departure in t['departureCity'].lower()]
        
        if destination:
            filtered_trips = [t for t in filtered_trips if 
                            destination in t['destinationCity'].lower()]
        
        return jsonify({
            "success": True,
            "trips": filtered_trips,
            "count": len(filtered_trips),
            "query": {
                "search": query,
                "from": departure, 
                "to": destination
            }
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/api/trips', methods=['POST'])
def create_trip():
    try:
        data = request.get_json()
        
        new_trip = {
            "id": str(uuid.uuid4()),
            "driverName": data.get('driverName', 'Anonymous'),
            "driverRating": 4.5,
            "route": f"{data.get('from', '')} → {data.get('to', '')}",
            "departureCity": data.get('from', ''),
            "destinationCity": data.get('to', ''),
            "departureTime": data.get('departureTime', ''),
            "availableSeats": int(data.get('seats', 1)),
            "totalSeats": int(data.get('seats', 1)),
            "pricePerPerson": float(data.get('price', 0)),
            "estimatedDuration": data.get('duration', 'TBD'),
            "carModel": data.get('carModel', 'Standard Vehicle'),
            "amenities": data.get('amenities', []),
            "pickupPoints": data.get('pickupPoints', []),
            "description": data.get('description', '')
        }
        
        trips.append(new_trip)
        
        return jsonify({
            "success": True,
            "message": "Trip created successfully",
            "trip": new_trip
        }), 201
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 400

@app.route('/api/trips/<trip_id>/book', methods=['POST'])
def book_trip(trip_id):
    try:
        data = request.get_json()
        
        # Find the trip
        trip = next((t for t in trips if t['id'] == trip_id), None)
        if not trip:
            return jsonify({"success": False, "error": "Trip not found"}), 404
        
        # Check availability
        if trip['availableSeats'] <= 0:
            return jsonify({"success": False, "error": "No seats available"}), 400
        
        # Create booking
        booking = {
            "id": str(uuid.uuid4()),
            "tripId": trip_id,
            "userId": data.get('userId', 'demo-user'),
            "passengerCount": int(data.get('passengerCount', 1)),
            "status": "confirmed",
            "bookingTime": datetime.now().isoformat(),
            "totalPrice": trip['pricePerPerson'] * int(data.get('passengerCount', 1))
        }
        
        bookings.append(booking)
        
        # Update available seats
        trip['availableSeats'] -= int(data.get('passengerCount', 1))
        
        return jsonify({
            "success": True,
            "message": "Trip booked successfully",
            "booking": booking
        }), 201
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 400

@app.route('/api/users/<user_id>/bookings', methods=['GET'])
def get_user_bookings(user_id):
    try:
        user_bookings = [b for b in bookings if b['userId'] == user_id]
        
        # Add trip details to bookings
        detailed_bookings = []
        for booking in user_bookings:
            trip = next((t for t in trips if t['id'] == booking['tripId']), None)
            if trip:
                detailed_booking = {**booking, "trip": trip}
                detailed_bookings.append(detailed_booking)
        
        return jsonify({
            "success": True,
            "bookings": detailed_bookings,
            "count": len(detailed_bookings)
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

if __name__ == '__main__':
    # Use environment port for production (Render sets this)
    port = int(os.environ.get('PORT', 5000))
    # Listen on all interfaces for production
    app.run(host='0.0.0.0', port=port, debug=False)
