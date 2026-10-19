# ShopSphere 🛍️

**A modern Flutter shopping app powered by DummyJSON.**

ShopSphere is a mobile shopping experience built with Flutter, featuring product discovery, search and filtering, detailed product views, cart management, and authentication. It combines a polished, responsive interface with a feature-first architecture, Riverpod state management, API integration, and automated testing.

## ✨ Features

- **Authentication** — Sign in using the DummyJSON authentication API, with session credentials stored securely.
- **Product discovery** — Browse products with category filtering, search, sorting, and paginated loading.
- **Product details** — Explore product images, descriptions, pricing, discounts, ratings, stock availability, and reviews.
- **Shopping cart** — Add products, update quantities, remove items, and calculate subtotals, discounts, and totals.
- **Persistent cart** — Retain cart contents locally between app launches.
- **Profile & session management** — Access the authenticated user's profile and log out.
- **API error handling** — Handle failed requests and common authentication and loading errors.
- **Modern UI** — Material 3 styling with a consistent visual identity and responsive layouts.
- **Automated testing** — Unit and widget tests for core application behaviour.
- **Continuous integration** — GitHub Actions workflow for formatting, static analysis, and test execution.

## 🧰 Tech Stack

| Technology | Purpose |
|---|---|
| Flutter & Dart | Cross-platform mobile application |
| Riverpod | Reactive state management |
| Dio | HTTP requests and API integration |
| GoRouter | Application navigation |
| Flutter Secure Storage | Secure session credential storage |
| SharedPreferences | Local cart persistence |
| Cached Network Image | Network image loading and caching |
| DummyJSON | Authentication, products, and user data |
| Flutter Test | Unit and widget testing |
| GitHub Actions | Continuous integration |

## 🏗️ Architecture

ShopSphere follows a **feature-first project structure**, separating application setup and individual feature implementations.

```text
lib/
├── app/
│   └── app.dart
├── core/
│   ├── api/
│   ├── ...
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── products/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── cart/
│   │   ├── domain/
│   │   └── presentation/
│   └── profile/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── main.dart

test/
├── features/
│   ├── products/
│   └── cart/
└── widget_test.dart
```

*The tree illustrates the intended feature boundaries; individual files may vary in the implementation.*

### Design principles

- **Separation of concerns:** UI, domain models, data access, and state management have distinct responsibilities.
- **Reactive state:** Riverpod coordinates application state and updates the UI.
- **Centralized networking:** Dio provides the HTTP client and a common place for request configuration and error handling.
- **Maintainability:** Feature-based organization makes functionality easier to test and extend.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Dart SDK compatible with your Flutter installation
- Android Studio or another supported Flutter development environment
- An Android emulator, physical device, or supported desktop environment

### 1. Clone the repository

```bash
git clone https://github.com/Nerdparth/prosessed-flutter-assignment.git
cd prosessed-flutter-assignment
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the application

```bash
flutter run
```

Make sure a supported device or emulator is available. The application uses the DummyJSON API, so API-dependent functionality requires network connectivity.

## 🔐 Demo Credentials

Use the following DummyJSON demo account to test authentication:

| Field | Value |
|---|---|
| Username | `emilys` |
| Password | `emilyspass` |

These are public demo credentials provided for testing purposes, not production account credentials.

## 🌐 API Integration

ShopSphere uses [DummyJSON](https://dummyjson.com/) to retrieve sample commerce and authentication data.

| Functionality | Endpoint |
|---|---|
| User authentication | `POST /auth/login` |
| Current user profile | `GET /auth/me` |
| Product listing | `GET /products` |
| Product search | `GET /products/search` |
| Product categories | `GET /products/categories` |
| Products by category | `GET /products/category/{category}` |
| Product details | `GET /products/{id}` |
| Add-cart API demonstration | `POST /carts/add` |

**API base URL:** `https://dummyjson.com`

DummyJSON is a demonstration API. Operations such as adding a cart may return simulated responses rather than permanently modifying server-side data. ShopSphere maintains its own local cart state and persistence.

## 🧪 Testing & Code Quality

Run the test suite:

```bash
flutter test
```

Run static analysis:

```bash
flutter analyze
```

Format the code:

```bash
dart format lib test
```

Verify formatting without changing files:

```bash
dart format --output=none --set-exit-if-changed lib test
```

The current test suite covers product and review model parsing, cart-item calculations and serialization, cart state operations, and application startup.

### Continuous Integration

GitHub Actions runs the following checks on pushes and pull requests targeting `main`:

1. Install Flutter and project dependencies.
2. Verify Dart formatting.
3. Run `flutter analyze`.
4. Execute `flutter test`.

This helps catch formatting issues, static-analysis findings, and test regressions before changes are merged.

## 📱 Screenshots

Screenshots of the application can be added here to showcase the main user flows:

- Login and authentication
- Product listing and search
- Product details
- Shopping cart and price summary
- User profile

Save the images in a `screenshots/` directory and embed them using Markdown, for example:

```markdown
![Product listing](screenshots/products.png)
![Product details](screenshots/product-details.png)
![Shopping cart](screenshots/cart.png)
```

## 📦 Build an APK

To generate a release APK locally:

```bash
flutter build apk --release
```

The resulting APK is typically located at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

To build a smaller APK for multiple CPU architectures:

```bash
flutter build apk --split-per-abi
```

Install the release APK on a compatible Android device to verify the release build.

## 🛣️ Future Improvements

- Expand automated coverage for authentication, API failures, and navigation.
- Add more integration tests for complete shopping journeys.
- Introduce additional accessibility checks and UI polish.
- Automate release builds and artifact publishing through GitHub Actions.

## 👨‍💻 Author

**Parth Kapoor**

- GitHub: [@Nerdparth](https://github.com/Nerdparth)

---

Built with Flutter, Riverpod, and a love for thoughtful mobile experiences. 💜