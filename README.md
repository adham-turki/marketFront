# TradeSuper Mobile App

A comprehensive B2B/B2C wholesale-retail platform mobile application built with Flutter.

## 🚀 Features

- **Multi-role Support**: Owner, Admin, Supermarket, Customer interfaces
- **Product Management**: Browse, search, and manage products
- **Shopping Cart**: Add items, manage quantities, apply promotions
- **Order Management**: Place orders, track status, view history
- **Loyalty Program**: Earn and redeem points, track tiers
- **Promotions & Coupons**: Apply discounts and special offers
- **Real-time Notifications**: Push notifications for updates
- **Offline Support**: Local data caching and offline functionality

## 🛠️ Technology Stack

- **Framework**: Flutter
- **State Management**: Provider
- **Navigation**: Go Router
- **HTTP Client**: Dio
- **Local Storage**: Hive, Shared Preferences
- **UI Components**: Material Design 3
- **Maps**: Google Maps Flutter
- **Notifications**: Firebase Messaging
- **QR/Barcode**: Mobile Scanner

## 📋 Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code
- Android SDK / Xcode (for mobile development)

## 🚀 Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd marketFront
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/          # App constants and configurations
│   ├── services/           # Core services (API, storage, etc.)
│   ├── utils/              # Utility functions
│   ├── theme/              # App theme and styling
│   └── network/            # Network configuration
├── data/
│   ├── models/             # Data models
│   ├── repositories/       # Repository layer
│   └── datasources/        # Data sources (remote/local)
├── presentation/
│   ├── providers/          # State management providers
│   ├── screens/            # UI screens
│   │   ├── auth/           # Authentication screens
│   │   ├── owner/          # Owner-specific screens
│   │   ├── admin/          # Admin-specific screens
│   │   ├── supermarket/    # Supermarket-specific screens
│   │   ├── customer/       # Customer-specific screens
│   │   └── shared/         # Shared screens
│   └── widgets/            # Reusable UI components
└── main.dart               # App entry point
```

## 🔧 Configuration

### Environment Setup

1. Create a `.env` file in the root directory
2. Add your configuration variables:
   ```
   API_BASE_URL=http://localhost:3000/api/v1
   FIREBASE_PROJECT_ID=your-project-id
   ```

### Backend Connection

The app connects to the TradeSuper backend API. Make sure the backend server is running and accessible.

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## 📱 Building for Production

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

## 🔐 Authentication

The app supports JWT-based authentication with the following user roles:

- **Owner**: Platform manager with full access
- **Admin**: Trader/Supplier managing products and orders
- **Supermarket**: B2B buyer with wholesale access
- **Customer**: B2C buyer with retail access

## 💰 Commission Structure

- **B2C Orders**: 7% commission
- **B2B Orders**: 3% commission

## 📊 Features by Role

### Owner Dashboard

- Platform overview and metrics
- Revenue analytics and commission tracking
- User management and approval system
- System settings and configuration

### Admin (Trader) Features

- Product management with bulk operations
- Inventory tracking and alerts
- Order management and fulfillment
- Promotion creation and scheduling
- Customer analytics and insights

### Supermarket (B2B) Features

- Wholesale catalog with B2B pricing
- Bulk ordering with quantity breaks
- Reorder templates and auto-ordering
- Order history and tracking
- Volume discounts and special offers

### Customer (B2C) Features

- Product catalog with retail pricing
- Shopping cart with promotions
- Loyalty program and points tracking
- Wishlist and favorites
- Order tracking and history

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License.

## 📞 Support

For support and questions, please contact the development team.
