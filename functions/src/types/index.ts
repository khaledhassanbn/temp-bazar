/**
 * Type definitions for the subscription system
 */

export interface Package {
  name: string;
  days: number;
  price: number;
  features: string[];
  orderIndex: number;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface Subscription {
  packageName: string;
  startDate: FirebaseFirestore.Timestamp;
  endDate: FirebaseFirestore.Timestamp;
  durationDays: number;
}

export interface Store {
  name: string;
  ownerUid: string;
  isActive: boolean;
  expiryDate: FirebaseFirestore.Timestamp | null;
  createdAt: FirebaseFirestore.Timestamp;
  canReceiveOrders: boolean;
  canAddProducts: boolean;
  subscription?: Subscription;
  deactivatedAt?: FirebaseFirestore.Timestamp;
}

export interface Payment {
  paymentId: string;
  packageId: string;
  packageName: string;
  amount: number;
  currency: string;
  status: string;
  createdAt: FirebaseFirestore.Timestamp;
  paymobOrderId?: string;
  paymobTransactionId?: string;
}

export interface StoreStatusResponse {
  isActive: boolean;
  needsRenewal: boolean;
  expiryDate: string | null;
  remainingDays: number;
  subscription: {
    packageName: string | null;
    startDate: string | null;
    endDate: string | null;
    durationDays: number | null;
  };
}

export interface PaymobWebhookPayload {
  obj: {
    id: number;
    amount_cents: number;
    currency: string;
    is_paid: boolean;
    is_refunded: boolean;
    integration_id: number;
    order: {
      id: number;
      created_at: string;
      delivery_needed: boolean;
      merchant: {
        id: number;
        created_at: string;
        phones: string[];
      };
      amount_cents: number;
      currency: string;
      is_payment_locked: boolean;
      merchant_order_id: string;
      wallet_notification: null | any;
      paid_amount_cents: number;
      notify_user_with_email: boolean;
      items: any[];
    };
    created_at: string;
    transaction_no: number;
    merchant_order_id: string;
    shipping_data: any;
    shipping_details: any;
    metadata?: {
      storeId?: string;
      packageId?: string;
    };
  };
  type: string;
  hmac?: string;
}

