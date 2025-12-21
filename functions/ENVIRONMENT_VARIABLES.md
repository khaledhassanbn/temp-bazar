# Environment Variables Guide

Complete guide for configuring environment variables for the subscription system.

## 📋 Required Variables

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `PAYMOB_HMAC_SECRET` | HMAC secret from Paymob dashboard for webhook verification | ✅ Yes | `abc123def456...` |

---

## 🔐 Setting Environment Variables

### Method 1: Firebase Functions Config (v1 - Legacy)

**Set variable:**

```bash
firebase functions:config:set paymob.hmac_secret="YOUR_HMAC_SECRET"
```

**Access in code:**

```typescript
const hmacSecret = functions.config().paymob.hmac_secret;
```

**Get current config:**

```bash
firebase functions:config:get
```

**Unset variable:**

```bash
firebase functions:config:unset paymob.hmac_secret
```

**Note:** This method is for Firebase Functions v1. For v2, use secrets (Method 2).

---

### Method 2: Firebase Secrets (v2 - Recommended)

**Set secret:**

```bash
firebase functions:secrets:set PAYMOB_HMAC_SECRET
```

When prompted, enter your HMAC secret.

**Access in code:**

```typescript
const hmacSecret = process.env.PAYMOB_HMAC_SECRET;
```

**List secrets:**

```bash
firebase functions:secrets:access PAYMOB_HMAC_SECRET
```

**Grant access to secret:**

```bash
firebase functions:secrets:grant PAYMOB_HMAC_SECRET
```

**Revoke access:**

```bash
firebase functions:secrets:revoke PAYMOB_HMAC_SECRET
```

---

### Method 3: .env File (Local Development Only)

**Create `.env` file in `functions/` directory:**

```env
PAYMOB_HMAC_SECRET=your_hmac_secret_here
```

**Add to `.gitignore`:**

```gitignore
# Environment variables
functions/.env
```

**Load in code (requires `dotenv` package):**

```bash
npm install dotenv
```

```typescript
import * as dotenv from 'dotenv';
dotenv.config();

const hmacSecret = process.env.PAYMOB_HMAC_SECRET;
```

**⚠️ Important:** `.env` files are NOT deployed to production. Use Firebase config or secrets for production.

---

### Method 4: Firebase Console (UI)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Functions** → **Configuration**
4. Click **Add Secret**
5. Enter:
   - **Name:** `PAYMOB_HMAC_SECRET`
   - **Value:** Your HMAC secret
6. Click **Save**

---

## 🔑 Getting Paymob HMAC Secret

1. Login to [Paymob Dashboard](https://accept.paymob.com/)
2. Go to **Settings** → **API Keys**
3. Copy **HMAC Secret**
4. Set in Firebase using one of the methods above

---

## ✅ Verification

### Check if Variable is Set

**Using Firebase CLI:**

```bash
# For config (v1)
firebase functions:config:get

# For secrets (v2)
firebase functions:secrets:access PAYMOB_HMAC_SECRET
```

**In code (for testing):**

```typescript
const hmacSecret = process.env.PAYMOB_HMAC_SECRET;

if (!hmacSecret) {
  console.error('PAYMOB_HMAC_SECRET is not set!');
} else {
  console.log('HMAC secret is configured');
}
```

### Test Webhook with Secret

After setting the secret, test the webhook:

```bash
curl -X POST https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/paymobWebhookHandler \
  -H "Content-Type: application/json" \
  -d '{
    "obj": { ... },
    "type": "TRANSACTION",
    "hmac": "calculated_hmac"
  }'
```

If HMAC verification fails, check:
1. Secret is set correctly
2. Secret matches Paymob dashboard
3. HMAC calculation is correct

---

## 🔄 Updating Variables

### Update Secret

```bash
firebase functions:secrets:set PAYMOB_HMAC_SECRET
```

Enter new value when prompted.

### Rotate Secret

If you need to rotate the HMAC secret:

1. **Get new secret from Paymob**
2. **Set new secret in Firebase:**
   ```bash
   firebase functions:secrets:set PAYMOB_HMAC_SECRET
   ```
3. **Update Paymob webhook configuration** (if needed)
4. **Redeploy functions:**
   ```bash
   firebase deploy --only functions
   ```

---

## 🛡️ Security Best Practices

1. **Never commit secrets to Git**
   - Add `.env` to `.gitignore`
   - Never hardcode secrets in code

2. **Use Firebase Secrets (v2) for production**
   - More secure than config
   - Encrypted at rest
   - Access controlled

3. **Rotate secrets regularly**
   - Change HMAC secret every 6-12 months
   - Update in both Paymob and Firebase

4. **Limit access to secrets**
   - Only grant access to necessary functions
   - Use Firebase IAM for access control

5. **Monitor secret access**
   - Check Firebase Console → Functions → Secrets
   - Review access logs

---

## 🐛 Troubleshooting

### Secret Not Found

**Error:** `PAYMOB_HMAC_SECRET not configured`

**Solution:**
1. Verify secret is set:
   ```bash
   firebase functions:secrets:access PAYMOB_HMAC_SECRET
   ```
2. Grant access to function:
   ```bash
   firebase functions:secrets:grant PAYMOB_HMAC_SECRET
   ```
3. Redeploy function:
   ```bash
   firebase deploy --only functions:paymobWebhookHandler
   ```

### HMAC Verification Failing

**Error:** `Invalid HMAC signature`

**Possible causes:**
1. Secret mismatch between Paymob and Firebase
2. Secret not set correctly
3. HMAC calculation error

**Solution:**
1. Verify secret in Paymob dashboard
2. Verify secret in Firebase:
   ```bash
   firebase functions:secrets:access PAYMOB_HMAC_SECRET
   ```
3. Check webhook logs:
   ```bash
   firebase functions:log --only paymobWebhookHandler
   ```

### Secret Access Denied

**Error:** `Permission denied to access secret`

**Solution:**
1. Grant access:
   ```bash
   firebase functions:secrets:grant PAYMOB_HMAC_SECRET
   ```
2. Check Firebase IAM permissions
3. Verify you're logged in:
   ```bash
   firebase login
   ```

---

## 📚 Additional Resources

- [Firebase Functions Configuration](https://firebase.google.com/docs/functions/config-env)
- [Firebase Secrets](https://firebase.google.com/docs/functions/secrets)
- [Paymob Documentation](https://docs.paymob.com/)

---

## 📝 Summary

**For Production:**
- ✅ Use Firebase Secrets (Method 2)
- ✅ Never use `.env` files
- ✅ Rotate secrets regularly

**For Local Development:**
- ✅ Use `.env` file (Method 3)
- ✅ Add to `.gitignore`
- ✅ Use `dotenv` package

**Quick Setup:**
```bash
# Set secret
firebase functions:secrets:set PAYMOB_HMAC_SECRET

# Grant access
firebase functions:secrets:grant PAYMOB_HMAC_SECRET

# Deploy
firebase deploy --only functions
```

---

## 🤝 Support

For issues with environment variables, contact the development team.

