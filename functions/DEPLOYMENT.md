# Deployment Guide - Store Subscription System

Complete step-by-step guide for deploying the subscription system to production.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Environment Configuration](#environment-configuration)
- [Firestore Setup](#firestore-setup)
- [Deploying Functions](#deploying-functions)
- [Deploying Firestore Rules](#deploying-firestore-rules)
- [Paymob Configuration](#paymob-configuration)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

---

## ✅ Prerequisites

Before deploying, ensure you have:

- ✅ Node.js 22+ installed
- ✅ Firebase CLI installed (`npm install -g firebase-tools`)
- ✅ Firebase project created
- ✅ Firestore enabled in Firebase Console
- ✅ Billing enabled (required for Cloud Functions)
- ✅ Paymob account with HMAC secret

---

## 🚀 Initial Setup

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Build TypeScript

```bash
npm run build
```

Verify build succeeded:

```bash
# Should create lib/ directory with compiled JavaScript
ls lib/
```

### 3. Login to Firebase

```bash
firebase login
```

### 4. Initialize Firebase Project

```bash
firebase init
```

Select:
- ✅ Functions
- ✅ Firestore

---

## 🔐 Environment Configuration

### Option 1: Firebase Config (Recommended)

```bash
firebase functions:config:set paymob.hmac_secret="YOUR_HMAC_SECRET_HERE"
```

Verify:

```bash
firebase functions:config:get
```

### Option 2: Environment Secrets (Firebase v2)

```bash
# Set secret
firebase functions:secrets:set PAYMOB_HMAC_SECRET

# When prompted, enter your HMAC secret
```

### Option 3: .env File (Local Development Only)

Create `functions/.env`:

```env
PAYMOB_HMAC_SECRET=your_hmac_secret_here
```

**Note:** `.env` files are NOT deployed. Use Firebase config or secrets for production.

---

## 🗄️ Firestore Setup

### 1. Create Required Indexes

Create `firestore.indexes.json` in project root:

```json
{
  "indexes": [
    {
      "collectionGroup": "markets",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "isVisible",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "isActive",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "markets",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "expiryDate",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "isActive",
          "order": "ASCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Deploy indexes:

```bash
firebase deploy --only firestore:indexes
```

### 2. Verify Index Creation

1. Go to Firebase Console → Firestore → Indexes
2. Wait for indexes to build (may take a few minutes)
3. Verify both indexes show "Enabled" status

---

## 📦 Deploying Functions

### Deploy All Functions

```bash
firebase deploy --only functions
```

### Deploy Specific Function

```bash
# Deploy webhook only
firebase deploy --only functions:paymobWebhookHandler

# Deploy status check only
firebase deploy --only functions:checkStoreStatusCallable
```

### Deploy with Specific Region

Functions are configured to use `europe-west1` by default. To change:

Edit `functions/src/index.ts`:

```typescript
setGlobalOptions({
  maxInstances: 10,
  region: "us-central1", // Change region
});
```

### Verify Deployment

```bash
# List deployed functions
firebase functions:list
```

Expected output:

```
Function Name                      Status  Trigger
checkExpiredSubscriptionsScheduled Active  Schedule
checkStoreStatusCallable           Active  HTTPS Callable
createPackageCallable              Active  HTTPS Callable
deletePackageCallable              Active  HTTPS Callable
paymobWebhookHandler               Active  HTTPS
updatePackageCallable              Active  HTTPS Callable
```

---

## 🔒 Deploying Firestore Rules

### Deploy Rules

```bash
firebase deploy --only firestore:rules
```

### Verify Rules

1. Go to Firebase Console → Firestore → Rules
2. Verify rules are deployed correctly
3. Test rules using Rules Playground (optional)

### Test Rules Locally

```bash
# Start emulator
firebase emulators:start --only firestore

# In another terminal, test rules
# Use Firebase Console Rules Playground or write test scripts
```

---

## 💳 Paymob Configuration

### 1. Get Webhook URL

After deploying, get your webhook URL:

```bash
# Get function URL
firebase functions:config:get
```

Or find it in Firebase Console:
- Functions → `paymobWebhookHandler` → Copy URL

Example URL:
```
https://europe-west1-YOUR_PROJECT.cloudfunctions.net/paymobWebhookHandler
```

### 2. Configure Paymob Webhook

1. Login to Paymob Dashboard
2. Go to Settings → Webhooks
3. Add webhook URL:
   ```
   https://europe-west1-YOUR_PROJECT.cloudfunctions.net/paymobWebhookHandler
   ```
4. Select events: `TRANSACTION`
5. Save

### 3. Get HMAC Secret

1. In Paymob Dashboard → Settings → API Keys
2. Copy HMAC Secret
3. Set in Firebase (see [Environment Configuration](#environment-configuration))

### 4. Test Webhook

Use Paymob's test webhook feature or send a test request:

```bash
curl -X POST https://europe-west1-YOUR_PROJECT.cloudfunctions.net/paymobWebhookHandler \
  -H "Content-Type: application/json" \
  -d '{
    "obj": {
      "id": 123456,
      "amount_cents": 10000,
      "currency": "EGP",
      "is_paid": true,
      "is_refunded": false,
      "order": {
        "id": 789,
        "merchant_order_id": "test_store_id",
        "metadata": {
          "storeId": "test_store_id",
          "packageId": "test_package_id"
        }
      }
    },
    "type": "TRANSACTION",
    "hmac": "test_hmac"
  }'
```

**Note:** This will fail HMAC verification, but you can verify the endpoint is reachable.

---

## ✅ Verification

### 1. Test Functions

#### Test Status Check

```dart
// In Flutter app
final result = await FirebaseFunctions.instance
  .httpsCallable('checkStoreStatusCallable')
  .call({'storeId': 'test_store_id'});

print(result.data);
```

#### Test Package Creation (Admin Only)

```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('createPackageCallable')
  .call({
    'name': 'Test Package',
    'days': 30,
    'price': 100.0,
    'features': ['Feature 1', 'Feature 2'],
    'orderIndex': 1
  });

print(result.data);
```

### 2. Verify Scheduled Function

1. Go to Firebase Console → Functions
2. Find `checkExpiredSubscriptionsScheduled`
3. Check "Trigger" tab - should show schedule: `0 * * * *`
4. Check logs after 1 hour to verify it runs

### 3. Verify Firestore Rules

1. Go to Firebase Console → Firestore → Rules
2. Use Rules Playground to test:
   - Expired store cannot add products
   - Expired store cannot receive orders
   - Admin can manage packages

### 4. Test End-to-End Flow

1. Create a test store in Firestore
2. Set `expiryDate` to past date
3. Wait for scheduled function to run (or trigger manually)
4. Verify store is disabled:
   - `isActive = false`
   - `canAddProducts = false`
   - `canReceiveOrders = false`
   - `isVisible = false`

---

## 🐛 Troubleshooting

### Function Deployment Fails

**Error: "TypeScript compilation failed"**

```bash
# Check for TypeScript errors
cd functions
npm run build

# Fix errors, then redeploy
firebase deploy --only functions
```

**Error: "Permission denied"**

```bash
# Check Firebase login
firebase login

# Verify project access
firebase projects:list
```

**Error: "Billing not enabled"**

1. Go to Firebase Console → Project Settings → Billing
2. Enable billing (Blaze plan required for Cloud Functions)

### Webhook Not Receiving Requests

**Check Function Logs:**

```bash
firebase functions:log --only paymobWebhookHandler
```

**Common Issues:**

1. **HMAC verification failing**
   - Verify `PAYMOB_HMAC_SECRET` is set correctly
   - Check Paymob dashboard for correct secret

2. **CORS errors**
   - Function has `cors: true` in config
   - Verify Paymob can reach your function URL

3. **404 Not Found**
   - Verify function is deployed
   - Check function URL is correct in Paymob dashboard

### Scheduled Function Not Running

**Check Function Status:**

```bash
firebase functions:list
```

**Verify Schedule:**

1. Go to Firebase Console → Functions
2. Click on `checkExpiredSubscriptionsScheduled`
3. Check "Trigger" tab - should show schedule

**Check Logs:**

```bash
firebase functions:log --only checkExpiredSubscriptionsScheduled
```

**Manual Trigger (Testing):**

```bash
# Use Firebase Console to trigger manually
# Or use gcloud CLI:
gcloud scheduler jobs run checkExpiredSubscriptionsScheduled \
  --location=europe-west1
```

### Firestore Rules Not Working

**Verify Rules Deployed:**

```bash
firebase deploy --only firestore:rules
```

**Test in Rules Playground:**

1. Firebase Console → Firestore → Rules
2. Click "Rules Playground"
3. Test scenarios:
   - Expired store trying to add product
   - Active store adding product
   - Admin managing packages

**Common Issues:**

1. **Index missing**
   - Deploy indexes: `firebase deploy --only firestore:indexes`
   - Wait for indexes to build

2. **Rules syntax error**
   - Check `firestore.rules` for syntax errors
   - Use Firebase Console Rules Playground to validate

---

## 📊 Monitoring

### View Function Logs

```bash
# All functions
firebase functions:log

# Specific function
firebase functions:log --only paymobWebhookHandler

# Last 50 lines
firebase functions:log --limit 50
```

### Monitor Function Performance

1. Go to Firebase Console → Functions
2. Click on function name
3. View "Metrics" tab:
   - Invocations
   - Errors
   - Execution time
   - Memory usage

### Set Up Alerts

1. Go to Firebase Console → Functions
2. Click on function
3. Go to "Alerts" tab
4. Set up alerts for:
   - Error rate > threshold
   - Execution time > threshold
   - Memory usage > threshold

---

## 🔄 Updating Functions

### Update Single Function

```bash
# Make changes to function code
# Build
npm run build

# Deploy specific function
firebase deploy --only functions:checkStoreStatusCallable
```

### Update All Functions

```bash
npm run build
firebase deploy --only functions
```

### Rollback Function

```bash
# List function versions
firebase functions:list --only checkStoreStatusCallable

# Rollback to previous version (if available)
# Use Firebase Console → Functions → Function Name → Versions
```

---

## 📝 Deployment Checklist

Before going to production:

- [ ] All functions deployed successfully
- [ ] Firestore rules deployed
- [ ] Firestore indexes created and enabled
- [ ] Environment variables set (HMAC secret)
- [ ] Paymob webhook configured
- [ ] Scheduled function verified running
- [ ] Test webhook received successfully
- [ ] Test status check API works
- [ ] Test package CRUD works (admin)
- [ ] Test expired store is disabled
- [ ] Flutter app integrated and tested
- [ ] Monitoring and alerts configured

---

## 🎯 Next Steps

After deployment:

1. **Test with real Paymob payment**
2. **Monitor function logs for errors**
3. **Set up alerts for critical issues**
4. **Document function URLs for Flutter team**
5. **Create admin dashboard for package management**

---

## 📚 Additional Resources

- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Paymob Integration Guide](https://docs.paymob.com/)
- [Functions README](./README.md)
- [Flutter Integration Guide](./FLUTTER_INTEGRATION.md)

---

## 📞 Support

For deployment issues, contact the development team.

