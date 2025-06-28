# Health Tracker App

A comprehensive Flutter health and fitness tracking application that helps users monitor their daily activities, set goals, and maintain a healthy lifestyle.

## 🚀 Features

### 📊 **Dashboard & Tracking**
- Real-time activity tracking with GPS
- Daily progress overview (distance, calories, steps)
- Weekly summary and statistics
- Interactive map with route visualization

### 🎯 **Goals & Achievements**
- Customizable daily and weekly goals
- Real-time progress tracking
- Achievement notifications when goals are completed
- Goal management interface

### 📱 **Core Functionality**
- Activity tracking (walking, running)
- Route recording with GPS
- Calorie calculation based on activity
- Session history and analytics

### 🛠️ **Data Management**
- Clear today's data
- Clear historical data
- Complete reset functionality
- Export/backup options

### 🔐 **Authentication**
- Firebase Authentication
- Google Sign-In integration
- Secure user sessions

## 🏗️ **Technical Stack**

- **Framework**: Flutter 3.x
- **Backend**: Firebase (Auth, Firestore)
- **Maps**: OpenStreetMap with flutter_map
- **State Management**: Built-in StatefulWidget
- **Local Storage**: SharedPreferences
- **Location**: Geolocator package

## 📁 **Project Structure**

```
health_app/
├── lib/
│   ├── models/          # Data models
│   ├── services/        # Business logic & data services
│   ├── page/           # UI screens
│   ├── widgets/        # Reusable UI components
│   ├── utils/          # Utility functions
│   └── common/         # Common resources
├── assets/             # Images and icons
└── android/ios/       # Platform-specific code
```

## 🚀 **Getting Started**

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK
- Android Studio / VS Code
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/105727702/tracking_health.git
   cd tracking_health/health_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project
   - Follow the detailed setup guide in [`health_app/FIREBASE_SETUP.md`](health_app/FIREBASE_SETUP.md)
   - Copy `firebase_options.dart.template` to `firebase_options.dart`
   - Add your Firebase configuration (never commit this file!)
   - Or use Firebase CLI: `flutterfire configure`

4. **Run the app**
   ```bash
   flutter run
   ```

## 📱 **Screenshots**

- Dashboard with daily progress
- Goal setting interface
- Map tracking view
- Achievement notifications
- Data management options

## 🎯 **How to Use**

1. **Getting Started**: Sign in with Google or create an account
2. **Set Goals**: Navigate to Goals Settings to customize your targets
3. **Start Tracking**: Use the Map tab to begin activity tracking
4. **Monitor Progress**: Check your dashboard for real-time updates
5. **View History**: Access your activity history and statistics
6. **Manage Data**: Use Data Management to reset or clear data

## 🔄 **Key Features Overview**

### Goals System
- Set custom daily goals (distance, calories, steps)
- Set weekly targets and active days goals
- Visual progress indicators
- Achievement celebrations

### Activity Tracking
- GPS-based route recording
- Real-time distance and calorie tracking
- Multiple activity types support
- Session history storage

### Data Management
- Clear today's data only
- Clear historical data (keep today)
- Complete reset to defaults
- Secure data handling

## 🛡️ **Security & Privacy**

- Firebase Authentication for secure login
- Local data encryption
- No personal data sharing
- User-controlled data management

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 **Support**

For support and questions:
- Create an issue on GitHub
- Check the documentation
- Review the FAQ section

## 🎉 **Acknowledgments**

- Flutter team for the amazing framework
- Firebase for backend services
- OpenStreetMap for mapping data
- Contributors and testers

---

**Happy tracking! 🏃‍♂️💪**
