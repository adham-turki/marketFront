# TradeSuper Flutter App Setup Guide

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio / VS Code
- Android Emulator, Physical Device, or Web Browser (Chrome)
- Node.js and npm (for backend)

## Backend Setup

1. **Navigate to backend directory:**

   ```bash
   cd marketBack
   ```

2. **Install dependencies:**

   ```bash
   npm install
   ```

3. **Set up environment variables:**

   ```bash
   cp env.example .env
   # Edit .env with your database credentials
   ```

4. **Start the backend server:**

   ```bash
   npm start
   # or
   node server.js
   ```

5. **Verify backend is running:**
   - Backend should be accessible at `http://localhost:3000`
   - Health check endpoint: `http://localhost:3000/api/health`

## Flutter App Setup

1. **Navigate to Flutter app directory:**

   ```bash
   cd marketFront
   ```

2. **Install Flutter dependencies:**

   ```bash
   flutter pub get
   ```

3. **Run the app:**

   **For Android Emulator/Device:**

   ```bash
   flutter run
   ```

   **For Web (Chrome with Device Preview):**

   ```bash
   flutter run -d chrome
   ```

## Web Platform Setup

### Enable Web Support

If you haven't enabled web support yet:

```bash
flutter config --enable-web
```

### Device Preview Controls

When running on web, you'll see Device Preview controls:

- **Device Selector**: Choose from various device presets (iPhone, Android, Tablet, etc.)
- **Orientation Toggle**: Switch between portrait and landscape
- **Frame Toggle**: Show/hide device frame
- **Settings**: Customize preview options

## Testing the App

### Device Preview Features (Web)

- **Device Emulation**: Test different device sizes and orientations
- **Responsive Design**: See how the app looks on various screen sizes
- **Platform Switching**: Toggle between different device presets
- **Orientation Testing**: Test portrait and landscape modes

### 1. Splash Screen

- App starts with a beautiful animated splash screen
- Automatically navigates to login screen after 3 seconds

### 2. Login Screen

- Enter valid email and password
- Form validation is implemented
- Error handling for invalid credentials
- Navigation to register screen

### 3. Register Screen

- Comprehensive registration form
- Role selection (customer, supermarket, owner, admin)
- Business account fields for relevant roles
- Password strength validation
- Form validation

### 4. Home Screen

- Displays user information after successful login
- Quick action cards for future features
- Logout functionality
- **Connection Test Button**: Tap the WiFi icon to test backend connectivity

## Backend Connection Testing

The app includes a connection test feature:

1. **Login to the app**
2. **Tap the WiFi icon in the app bar**
3. **Check the console output** for connection test results

Expected output:

```
✅ Backend connection successful
Response: {status: 'OK', timestamp: '...', uptime: ..., environment: 'development'}

🧪 Testing Auth Endpoints...
✅ Login endpoint validation working (400 expected)
✅ Register endpoint validation working (400 expected)
✅ Auth endpoints test completed
```

## Network Configuration

The app is configured to connect to the backend at:

- **Android Emulator**: `http://10.0.2.2:3000/api`
- **Web Browser (Chrome)**: `http://localhost:3000/api`
- **Physical Device**: Update `baseUrl` in `lib/core/network/api_service.dart`

## Features Implemented

### ✅ Completed

- Splash screen with animations
- Login screen with validation
- Register screen with role selection
- Home screen with user info
- Backend API integration
- Error handling and loading states
- Modern UI design with Material 3
- Form validation
- Navigation between screens

### 🔄 In Progress

- JWT token implementation
- Persistent authentication
- User profile management

### 📋 Planned

- Product catalog
- Shopping cart
- Order management
- Push notifications
- Offline support

## Troubleshooting

### Backend Connection Issues

1. Ensure backend server is running on port 3000
2. Check firewall settings
3. Verify network configuration in `api_service.dart`

### Flutter Build Issues

1. Run `flutter clean`
2. Run `flutter pub get`
3. Check Flutter version compatibility

### Database Issues

1. Verify database credentials in `.env`
2. Check database connection in backend logs
3. Ensure database tables are created

## Development Notes

- **No JWT yet**: Authentication is working but tokens are temporary
- **Form validation**: Client-side validation implemented
- **Error handling**: Comprehensive error messages for users
- **Responsive design**: Works on different screen sizes
- **Theme support**: Light/dark theme ready

## Next Steps

1. Implement JWT token authentication
2. Add persistent login state
3. Implement user profile management
4. Add product catalog functionality
5. Implement shopping cart features
