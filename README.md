🚗 FuelFinder

FuelFinder is an iOS application that helps users find nearby fuel stations, view them on a map, and search locations efficiently using modern iOS architecture.

📱 Features
📍 Get user’s current location
🗺️ Display nearby fuel stations on map
🔍 Search for locations
📄 View station list in bottom sheet
⚡ Smooth and responsive UI
🧠 MVVM architecture for clean code
🏗️ Architecture

This project follows MVVM (Model-View-ViewModel) architecture:

FuelFinder
│
├── Models
├── Services
├── ViewModels
├── Views
└── Extensions
🔹 Layers Explanation
Models
Data structures for fuel stations and API responses
Services
APIService → Handles network calls
FuelRepository → Manages data logic
ViewModels
Business logic and state management
Example:
MainViewModel
LocationSearchViewModel
LocationManager
Views
UI layer using SwiftUI
Example:
FuelMapView
ContentView
StationListSheet
🛠️ Tech Stack
Swift
SwiftUI
MapKit
CoreLocation
MVVM Architecture
Combine (if used)
📍 Location Features
Real-time user location tracking
Permission handling
Nearby search functionality
🚀 Getting Started
1️⃣ Clone the repository
git clone https://github.com/ramchander010/FuelFinder.git
2️⃣ Open in Xcode
cd FuelFinder
open FuelFinder.xcodeproj
3️⃣ Run the app
Select Simulator or real device
Press ⌘ + R
🔐 Permissions Required

Add this in Info.plist:

<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby fuel stations</string>
📂 Project Structure
FuelFinder/
│
├── Models/
├── Services/
│   ├── APIService.swift
│   ├── FuelRepository.swift
│
├── ViewModels/
│   ├── LocationManager.swift
│   ├── LocationSearchViewModel.swift
│   ├── MainViewModel.swift
│
├── Views/
│   ├── ContentView.swift
│   ├── FuelMapView.swift
│   ├── StationListSheet.swift
│
├── Extensions/
├── Assets/
└── FuelFinderApp.swift
📸 Screenshots

Add screenshots here (Map view, station list, search UI)

🔮 Future Improvements
⛽ Filter by fuel type (Petrol/Diesel/CNG)
⭐ Favorite stations
📊 Price comparison
🌐 Backend integration for real-time data
🔔 Notifications for nearby stations
🤝 Contributing

Contributions are welcome!
