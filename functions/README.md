# Firebase Cloud Functions - Store Subscription System

Complete production-ready backend for managing store subscriptions with Paymob integration, automatic expiry handling, and comprehensive security.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Setup & Installation](#setup--installation)
- [Environment Variables](#environment-variables)
- [Functions](#functions)
- [Firestore Structure](#firestore-structure)
- [Deployment](#deployment)
- [Flutter Integration](#flutter-integration)
- [Security](#security)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This system provides:

1. **Paymob Webhook Integration** - Secure payment processing and subscription renewal
2. **Automatic Expiry Management** - Scheduled function that disables expired subscriptions hourly
3. **Status Checking API** - Real-time subscription status for Flutter app
4. **Package Management** - Admin CRUD operations for subscription packages
5. **Facebook Data Deletion Endpoint** - Compliant callback for Facebook Login users
6. **Firestore Security Rules** - Server-side enforcement of subscription restrictions

---

## 🏗️ Architecture

### Functions Structure

```
functions/
├── src/
│   ├── index.ts                 # Main entry point, exports all functions
│   ├── types/
│   │   └── index.ts            # TypeScript interfaces
│   ├── paymob/
│   │   └── webhook.ts          # Paymob webhook handler
│   ├── subscriptions/
│   │   ├── checkExpired.ts     # Scheduled function for expiry
│   │   └── checkStatus.ts      # Status checking API
│   ├── packages/
│   │   └── crud.ts             # Package management (CRUD)
│   └── utils/
│       ├── auth.ts             # Authentication utilities
│       └── hmac.ts             # HMAC verification
├── package.json
├── tsconfig.json
└── README.md
```

### Data Flow

```
1. Store Owner → Paymob Payment → Webhook → Update Store Subscription
2. Scheduled Function (Hourly) → Check Expired → Disable Stores
3. Flutter App → checkStoreStatus → Return Status → UI Updates
4. Admin → Package CRUD → Update Packages Collection
```

---

## 🚀 Setup & Installation

### Prerequisites

- Node.js 22+
- Firebase CLI (`npm install -g firebase-tools`)
- Firebase project with Firestore enabled
- Paymob account with HMAC secret

### Installation Steps

1. **Install Dependencies**

```bash
cd functions
npm install
```

2. **Build TypeScript**

```bash
npm run build
```

3. **Set Environment Variables**

```bash
firebase functions:config:set paymob.hmac_secret="YOUR_HMAC_SECRET"
```

Or use `.env` file (see [Environment Variables](#environment-variables))

4. **Deploy Functions**

```bash
firebase deploy --only functions
```

---

## 🔐 Environment Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `PAYMOB_HMAC_SECRET` | HMAC secret from Paymob dashboard | `abc123...` |
| `FACEBOOK_APP_SECRET` | Facebook App secret for verifying signed deletion requests | `your_fb_app_secret` |

### Setting Environment Variables

**Option 1: Firebase Config (Recommended for Production)**

```bash
firebase functions:config:set paymob.hmac_secret="YOUR_SECRET"
```

**Option 2: Environment File**

Create `.env` in `functions/` directory:

```env
PAYMOB_HMAC_SECRET=your_hmac_secret_here
```

**Option 3: Firebase Console**

1. Go to Firebase Console → Functions → Configuration
2. Add secret: `PAYMOB_HMAC_SECRET`

---

## 📦 Functions

### 1. `paymobWebhookHandler`

**Type:** HTTP Request  
**Method:** POST  
**URL:** `https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/paymobWebhookHandler`

**Purpose:** Handles Paymob payment webhooks and renews store subscriptions.

**Request Body:**
```json
{
  "obj": {
    "id": 123456,
    "amount_cents": 10000,
    "currency": "EGP",
    "is_paid": true,
    "is_refunded": false,
    "order": {
      "id": 789,
      "merchant_order_id": "storeId123",
      "metadata": {
        "storeId": "storeId123",
        "packageId": "packageId456"
      }
    }
  },
  "type": "TRANSACTION",
  "hmac": "signature..."
}
```

**Response:**
```json
{
  "success": true,
  "message": "Subscription renewed successfully",
  "storeId": "storeId123",
  "expiryDate": "2024-12-31T23:59:59.000Z"
}
```

**Security:**
- Validates HMAC signature
- Only processes `is_paid = true` and `is_refunded = false`
- Server-only logic (tamper-proof)

---

### 2. `checkExpiredSubscriptionsScheduled`

**Type:** Scheduled Function  
**Schedule:** Every hour (`0 * * * *`)  
**Timezone:** Africa/Cairo

**Purpose:** Automatically disables expired store subscriptions.

**Actions:**
- Finds stores where `expiryDate <= now` and `isActive = true`
- Sets:
  - `isActive = false`
  - `canAddProducts = false`
  - `canReceiveOrders = false`
  - `deactivatedAt = now`
  - `status = "expired"`
  - `isVisible = false`

**Processing:**
- Batched processing (400 stores per batch)
- Pagination support for large datasets
- Comprehensive logging

---

### 3. `checkStoreStatusCallable`

**Type:** Callable Function  
**Authentication:** Required

**Purpose:** Returns current subscription status for a store.

**Request:**
```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('checkStoreStatusCallable')
  .call({'storeId': 'storeId123'});
```

**Response:**
```json
{
  "isActive": true,
  "needsRenewal": false,
  "expiryDate": "2024-12-31T23:59:59.000Z",
  "remainingDays": 30,
  "subscription": {
    "packageName": "Premium Package",
    "startDate": "2024-12-01T00:00:00.000Z",
    "endDate": "2024-12-31T23:59:59.000Z",
    "durationDays": 30
  }
}
```

**Use Cases:**
- Check if store can add products
- Check if store can receive orders
- Show renewal dialog
- Redirect to pricing page

---

### 4. Package Management Functions

#### `createPackageCallable`

**Type:** Callable Function  
**Authentication:** Admin only

**Request:**
```json
{
  "name": "Premium Package",
  "days": 30,
  "price": 100.00,
  "features": ["Feature 1", "Feature 2"],
  "orderIndex": 1
}
```

**Response:**
```json
{
  "packageId": "packageId123",
  "message": "Package created successfully"
}
```

#### `updatePackageCallable`

**Type:** Callable Function  
**Authentication:** Admin only

**Request:**
```json
{
  "packageId": "packageId123",
  "name": "Updated Name",
  "price": 150.00
}
```

#### `deletePackageCallable`

**Type:** Callable Function  
**Authentication:** Admin only

**Request:**
```json
{
  "packageId": "packageId123"
}
```

---

### 5. `facebookDataDeletionRequest`

**Type:** HTTP Request  
**Method:** POST  
**URL:** `https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/facebookDataDeletionRequest`

**Purpose:** Handles the [Facebook User Data Deletion Callback](https://developers.facebook.com/docs/development/release/mandatory-submission-requirements/data-deletion-callback/) required for apps that offer Facebook Login. The function:

1. Validates the `signed_request` sent by Facebook using `FACEBOOK_APP_SECRET`.
2. Records the deletion request inside `facebookDeletionRequests/{confirmationCode}` for auditing.
3. Returns a `confirmation_code` and `url` as mandated by Facebook.

**Request Body (x-www-form-urlencoded or JSON):**

```
signed_request=abc.def
```

**Response:**

```json
{
  "url": "https://bazar-suez.web.app/facebook-data-deletion?request_id=fb-delete-123-1700000000000",
  "confirmation_code": "fb-delete-123-1700000000000"
}
```

**Setup Instructions:**

1. Set the secret:  
   ```bash
   firebase functions:config:set facebook.app_secret="YOUR_FB_APP_SECRET"
   ```
   or deploy using `.env`/Console (variable name `FACEBOOK_APP_SECRET`).
2. In your Facebook App Dashboard → **Settings > Advanced** → **Data Deletion Request URL**, add:  
   `https://europe-west1-YOUR_PROJECT.cloudfunctions.net/facebookDataDeletionRequest`
3. (Optional) Create a simple status page on `https://bazar-suez.web.app/facebook-data-deletion` that explains your deletion process. The function already includes a status URL parameter pointing to that route.

---

## 🗄️ Firestore Structure

### Stores Collection (`/markets/{storeId}`)

```typescript
{
  name: string;
  ownerUid: string;
  isActive: boolean;              // Subscription active status
  expiryDate: Timestamp | null;  // When subscription expires
  createdAt: Timestamp;
  canReceiveOrders: boolean;      // Can receive orders
  canAddProducts: boolean;        // Can add products
  subscription?: {
    packageName: string;
    startDate: Timestamp;
    endDate: Timestamp;
    durationDays: number;
  };
  deactivatedAt?: Timestamp;     // When subscription was deactivated
  status: "active" | "expired";  // Store status
  isVisible: boolean;             // Visible in public listings
}
```

### Packages Collection (`/packages/{packageId}`)

```typescript
{
  name: string;
  days: number;
  price: number;
  features: string[];
  orderIndex: number;
  createdAt: Timestamp;
}
```

### Payments Subcollection (`/markets/{storeId}/payments/{paymentId}`)

```typescript
{
  paymentId: string;
  packageId: string;
  packageName: string;
  amount: number;
  currency: string;
  status: string;
  createdAt: Timestamp;
  paymobOrderId?: string;
  paymobTransactionId?: string;
}
```

---

## 🚢 Deployment

### Initial Deployment

```bash
# 1. Build TypeScript
cd functions
npm run build

# 2. Deploy functions
firebase deploy --only functions

# 3. Deploy Firestore rules
firebase deploy --only firestore:rules
```

### Update Single Function

```bash
firebase deploy --only functions:checkStoreStatusCallable
```

### View Logs

```bash
firebase functions:log
```

### Test Locally

```bash
# Start emulator
firebase emulators:start --only functions,firestore

# In another terminal, test function
curl -X POST http://localhost:5001/YOUR_PROJECT/europe-west1/paymobWebhookHandler \
  -H "Content-Type: application/json" \
  -d '{"obj": {...}, "type": "TRANSACTION"}'
```

---

## 📱 Flutter Integration

See [FLUTTER_INTEGRATION.md](./FLUTTER_INTEGRATION.md) for complete Flutter integration guide.

### Quick Start

1. **Check Store Status**

```dart
import 'package:cloud_functions/cloud_functions.dart';

Future<Map<String, dynamic>> checkStoreStatus(String storeId) async {
  final result = await FirebaseFunctions.instance
    .httpsCallable('checkStoreStatusCallable')
    .call({'storeId': storeId});
  
  return result.data as Map<String, dynamic>;
}
```

2. **Hide Expired Stores**

```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
    .collection('markets')
    .where('isVisible', isEqualTo: true)
    .where('isActive', isEqualTo: true)
    .snapshots(),
  builder: (context, snapshot) {
    // Display stores
  },
)
```

3. **Block Adding Products**

```dart
Future<bool> canAddProduct(String storeId) async {
  final status = await checkStoreStatus(storeId);
  return status['isActive'] == true && 
         status['canAddProducts'] == true;
}
```

---

## 🔒 Security

### HMAC Verification

All Paymob webhooks are verified using HMAC-SHA512:

```typescript
const hmac = crypto
  .createHmac("sha512", hmacSecret)
  .update(JSON.stringify(payload.obj))
  .digest("hex");
```

### Firestore Security Rules

- Expired stores cannot add products
- Expired stores cannot receive orders
- Only admins can manage packages
- Store owners can only update their own stores

See `firestore.rules` for complete rules.

### Authentication

- All callable functions require authentication
- Admin functions verify `role === "admin"` or `userStatus === "admin"`
- Store operations verify ownership

---

## 🐛 Troubleshooting

### Function Not Deploying

```bash
# Check TypeScript errors
npm run build

# Check Firebase CLI version
firebase --version

# Check Node.js version (must be 22+)
node --version
```

### Webhook Not Working

1. Check HMAC secret is set correctly
2. Verify Paymob webhook URL is correct
3. Check function logs: `firebase functions:log`
4. Verify payload structure matches expected format

### Expired Stores Not Disabling

1. Check scheduled function is deployed
2. Verify function logs for errors
3. Check Firestore indexes are created
4. Verify `expiryDate` field exists on stores

### Flutter App Can't Call Functions

1. Verify Firebase is initialized in Flutter
2. Check user is authenticated
3. Verify function name matches exactly
4. Check Firebase project configuration

---

## 📚 Additional Resources

- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [Paymob Integration Guide](https://docs.paymob.com/)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Flutter Firebase Setup](https://firebase.flutter.dev/)

---

## 📝 License

This code is part of the Bazar Suez project.

---

## 🤝 Support

For issues or questions, please contact the development team.

