# ClosetTwin

An iOS app that helps you find the perfect fit for clothing by analyzing your body measurements against garment specifications.

## Features

- **Body Measurements**: Track and manage multiple measurement sets
- **Fit Analysis**: Get detailed fit evaluations using basic and advanced algorithms
- **QR Code Integration**: Scan partner QR codes for instant garment measurements
- **Avatar Sharing**: Share your measurements with friends for gift shopping
- **CloudKit Sync**: All data syncs securely across your devices

## Architecture

### Core Components

- **Models**: Data models for users, measurements, garments, and fit results
- **FitEngine**: Advanced fit analysis with basic and advanced modes
- **CloudKitStore**: Secure cloud storage using CloudKit
- **AuthManager**: Sign in with Apple authentication
- **QRKit**: QR code generation and scanning
- **DesignSystem**: Consistent UI components and styling

### Key Features

#### Fit Analysis
- **Basic Mode**: Simple circumference-based fit evaluation
- **Advanced Mode**: Physics-inspired strain analysis with fabric stretch considerations
- **Ease Tables**: Category-specific ease requirements for different fits

#### QR Integration
- Generate QR codes for sharing avatars
- Scan partner QR codes for garment measurements
- Support for partner payload validation

#### Data Management
- CloudKit private database for user data
- Public database for shared avatars
- Local caching and offline support

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- CloudKit enabled Apple ID

## Setup

1. Clone the repository
2. Open `ClosetTwin.xcodeproj` in Xcode
3. Configure CloudKit capabilities in your Apple Developer account
4. Update the bundle identifier to match your team
5. Build and run

## Project Structure

```
ClosetTwin/
├── Models/              # Data models and types
├── FitEngine/          # Fit analysis algorithms
├── Storage/            # CloudKit integration
├── Auth/               # Authentication
├── DesignSystem/       # UI components and styling
├── QRKit/              # QR code functionality
├── Features/           # App screens and features
│   ├── Home/          # Main dashboard
│   ├── Closet/        # Garment management
│   ├── Scan/          # QR scanning
│   ├── Profile/       # User profile and settings
│   └── Onboarding/    # First-time setup
└── Tests/             # Unit tests
```

## Testing

Run unit tests to verify fit analysis algorithms:

```bash
xcodebuild test -scheme ClosetTwin -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Privacy & Security

- All user data stored in CloudKit private database
- Shared avatars contain only measurement data (no personal information)
- Sign in with Apple for secure authentication
- No external SDKs or third-party tracking

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
