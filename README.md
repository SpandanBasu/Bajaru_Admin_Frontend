# Bajaru Admin

Internal operations dashboard for the Bajaru delivery ecosystem. Admins can manage procurement, packing orders, catalog, deliveries, riders, and monitor key metrics—all from a mobile-first Flutter app.

## Features

- **Authentication** — Truecaller one-tap login or WhatsApp OTP fallback
- **Dashboard** — Overview of pending orders, today’s deliveries, and key stats
- **Procurement** — Generate and manage daily procurement lists by pincode
- **Packing Orders** — View and manage orders awaiting packing; mark items ready
- **Deliveries** — Track orders by status (Pending, Out for delivery, Rejected, Delivered); filter by pincode, rider, payment type
- **Riders** — View online riders, active deliveries per rider, and assign route batches
- **Catalog** — Manage products and inventory across service areas

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.x |
| State Management | Riverpod |
| Auth | Truecaller SDK / WhatsApp OTP |
| HTTP | Dio |
| Storage | flutter_secure_storage (JWT) |
| Fonts | Google Fonts (Poppins) |

## Prerequisites

- Flutter SDK 3.x (Dart ^3.9.2)
- Android Studio / Xcode (for device or emulator)
- Bajaru Backend running (see [Bajaru_Backend](../Bajaru_Backend/README.md))

## Setup

### 1. Install dependencies

```bash
cd bajaru_admin_frontend
flutter pub get
```

### 2. Configure environment

Create a `.env` file in the project root and set your backend URL:

```bash
touch .env
```

Edit `.env`:

| Environment | API_BASE_URL (scheme + host + `/api/v1`, no path after version) |
|-------------|--------------|
| Android emulator | `http://10.0.2.2:8080/api/v1` |
| iOS simulator | `http://localhost:8080/api/v1` |
| Physical device | `http://<your-LAN-ip>:8080/api/v1` |
| Cloudflare tunnel | `https://<subdomain>.trycloudflare.com/api/v1` |

[ApiPaths](lib/core/api/api_paths.dart) holds every route; paths start with `/` so Dio concatenates correctly with the base URL.

Example:

```
API_BASE_URL=http://192.168.1.5:8080/api/v1
```

### 3. Run the app

```bash
flutter run
```

## Project Structure

```
lib/
├── app.dart                    # App shell, auth gate, theme
├── main.dart                   # Entry point, loads .env
├── core/
│   ├── api/                    # AdminApiClient, ApiPaths (all routes)
│   ├── constants/              # AppColors, dimensions, text styles
│   ├── models/                 # DeliveryOrder, CatalogProduct, Rider, etc.
│   ├── network/                # Auth storage, token service
│   ├── providers/             # nav_provider
│   └── services/               # Auth, admin services
├── features/
│   ├── auth/                   # Login, OTP
│   ├── dashboard/              # Stats, overview
│   ├── procurement/            # Daily procurement list
│   ├── orders/                 # Packing orders
│   ├── riders/                 # Riders, route batches
│   ├── deliveries/             # Delivery management
│   └── catalog/                # Product catalog, inventory
└── widgets/                    # Shared components
```

## Backend Integration

The app talks to the [Bajaru Backend](../Bajaru_Backend/) admin APIs. Main endpoints:

| Endpoint | Purpose |
|----------|---------|
| `GET /api/admin/dashboard/stats` | Dashboard metrics |
| `GET /api/admin/procurement/items` | Procurement list |
| `GET /api/admin/packing/orders` | Packing orders |
| `GET /api/admin/deliveries` | Delivery orders |
| `GET /api/admin/riders` | Riders list |
| `GET /api/admin/riders/route-batches` | Route batches |
| `GET /api/admin/inventory-management/products` | Catalog products |

Admin role is required for all these endpoints.

## Build

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

## License

Proprietary — All rights reserved.
