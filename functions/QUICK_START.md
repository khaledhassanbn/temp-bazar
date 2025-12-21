# Quick Start Guide - Store Subscription System

Get up and running in 5 minutes!

## ⚡ Quick Setup

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Build TypeScript

```bash
npm run build
```

### 3. Set Environment Variable

```bash
firebase functions:secrets:set PAYMOB_HMAC_SECRET
# Enter your Paymob HMAC secret when prompted
```

### 4. Deploy

```bash
# Deploy functions
firebase deploy --only functions

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Firestore indexes
firebase deploy --only firestore:indexes
```

### 5. Configure Paymob Webhook

1. Get webhook URL from Firebase Console → Functions → `paymobWebhookHandler`
2. Add to Paymob Dashboard → Settings → Webhooks
3. Select event: `TRANSACTION`

**Done!** 🎉

---

## 🧪 Quick Test

### Test Status Check (Flutter)

```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('checkStoreStatusCallable')
  .call({'storeId': 'your_store_id'});

print(result.data);
```

### Test Package Creation (Admin)

```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('createPackageCallable')
  .call({
    'name': 'Test Package',
    'days': 30,
    'price': 100.0,
    'features': ['Feature 1'],
    'orderIndex': 1
  });
```

---

## 📚 Next Steps

- 📖 Read [README.md](./README.md) for complete documentation
- 📱 See [FLUTTER_INTEGRATION.md](./FLUTTER_INTEGRATION.md) for Flutter setup
- 🚀 Check [DEPLOYMENT.md](./DEPLOYMENT.md) for production deployment
- 🔐 Review [ENVIRONMENT_VARIABLES.md](./ENVIRONMENT_VARIABLES.md) for secrets

---

## 🆘 Need Help?

- Check [Troubleshooting](./README.md#troubleshooting) section
- Review function logs: `firebase functions:log`
- Contact development team

---

**That's it!** Your subscription system is ready to use. 🚀

