import {
  BarChart,
  Card,
  CardBody,
  CardHeader,
  CollapsibleSection,
  Grid,
  H1,
  H2,
  H3,
  LineChart,
  Row,
  Select,
  Stack,
  Stat,
  Table,
  Text,
  useCanvasState,
  useHostTheme,
} from "cursor/canvas";

// ─── Firebase Blaze Pricing (USD) — Source: firebase.google.com/pricing + cloud.google.com/firestore ───
const P = {
  fsRead: 0.06 / 100_000,
  fsWrite: 0.18 / 100_000,
  fsDelete: 0.02 / 100_000,
  fsStorage: 0.18, // per GB/month
  fsEgress: 0.12, // per GB after 10GB free
  fsFreeReads: 50_000 * 30,
  fsFreeWrites: 20_000 * 30,
  fsFreeDeletes: 20_000 * 30,
  stStorage: 0.026,
  stDownload: 0.12,
  stFreeGB: 5,
  stFreeDlGB: 100,
  rtdbStorage: 5,
  rtdbDownload: 1,
  rtdbFreeGB: 1,
  rtdbFreeDlGB: 10,
  cfInvocation: 0.4 / 1_000_000,
  cfFreeInvocations: 2_000_000,
  egp: 50,
};

function billable(units: number, free: number, rate: number) {
  return Math.max(0, units - free) * rate;
}

function usd(n: number) {
  return `$${n.toFixed(2)}`;
}

function egp(n: number) {
  return `${(n * P.egp).toFixed(0)} ج.م`;
}

// ─── Per-unit operation costs (current architecture) ───
const UNIT = {
  customerMonth: { reads: 398, writes: 24, deletes: 0 },
  storeMonth: (orders: number, products: number) => ({
    reads: 8_200 + orders * 28 + products * 12,
    writes: 1_100 + orders * 17 + products * 0.3,
    deletes: orders * 0.05,
  }),
  order: { reads: 45, writes: 22, deletes: 0, cf: 5, fcm: 6, rtdbKB: 180, storageKB: 0 },
  product: { readsPerView: 1, writesCreate: 2, storageKB: 124, imgDlKB: 120 },
  image: { storageKB: 120, uploadOps: 1, dlPerMonth: 40 },
  notification: { cf: 0.15, fcm: 0 },
  driverMonth: { reads: 600, writes: 0, rtdbKB: 2_400, rtdbWrites: 8_640 },
};

// ─── Optimized (-72% target) ───
const OPT = 0.28;

function platformOverhead(stores: number) {
  const openStatusReads = stores * 96 * 30;
  const openStatusWrites = stores * 96 * 30 * 0.3;
  const scheduledCF = 4_350;
  return {
    reads: openStatusReads,
    writes: openStatusWrites,
    cf: scheduledCF + stores * 2,
  };
}

function monthlyBill(
  stores: number,
  ordersPerStore: number,
  productsPerStore: number,
  customers: number,
  drivers: number,
  optimized = false
) {
  const factor = optimized ? OPT : 1;
  const totalOrders = stores * ordersPerStore;

  let reads =
    customers * UNIT.customerMonth.reads +
    stores * UNIT.storeMonth(ordersPerStore, productsPerStore).reads +
    totalOrders * UNIT.order.reads;
  let writes =
    customers * UNIT.customerMonth.writes +
    stores * UNIT.storeMonth(ordersPerStore, productsPerStore).writes +
    totalOrders * UNIT.order.writes;
  let deletes = totalOrders * UNIT.order.deletes;

  const overhead = platformOverhead(stores);
  reads += overhead.reads;
  writes += overhead.writes;

  reads *= factor;
  writes *= factor;
  deletes *= factor;

  const productImages = stores * productsPerStore;
  const storeImages = stores * 2;
  const userImages = customers * 0.1;
  const supportImages = stores * 0.5;
  const adImages = stores * 0.2;
  const totalImages = productImages + storeImages + userImages + supportImages + adImages;
  const storageGB = (totalImages * 124 + totalOrders * 0) / 1_048_576;
  const bandwidthGB =
    (totalImages * 40 * 120 + totalOrders * UNIT.order.rtdbKB + drivers * UNIT.driverMonth.rtdbKB) /
    1_048_576;

  const rtdbStorageGB = (drivers * 0.5) / 1024;
  const rtdbBandwidthGB = (totalOrders * 0.18 + drivers * 2.4) / 1024;

  let cfInvocations =
    overhead.cf + totalOrders * UNIT.order.cf + totalOrders * UNIT.order.fcm * UNIT.notification.cf;

  const fsCost =
    billable(reads, P.fsFreeReads, P.fsRead) +
    billable(writes, P.fsFreeWrites, P.fsWrite) +
    billable(deletes, P.fsFreeDeletes, P.fsDelete) +
    Math.max(0, storageGB - 1) * P.fsStorage;

  const stCost =
    Math.max(0, storageGB - P.stFreeGB) * P.stStorage +
    Math.max(0, bandwidthGB - P.stFreeDlGB) * P.stDownload;

  const rtdbCost =
    Math.max(0, rtdbStorageGB - P.rtdbFreeGB) * P.rtdbStorage +
    Math.max(0, rtdbBandwidthGB - P.rtdbFreeDlGB) * P.rtdbDownload;

  const cfCost = billable(cfInvocations, P.cfFreeInvocations, P.cfInvocation);

  const egressGB = bandwidthGB * 0.15;
  const egressCost = Math.max(0, egressGB - 10) * P.fsEgress;

  const total = fsCost + stCost + rtdbCost + cfCost + egressCost;

  return {
    reads: Math.round(reads),
    writes: Math.round(writes),
    deletes: Math.round(deletes),
    storageGB: +storageGB.toFixed(2),
    bandwidthGB: +bandwidthGB.toFixed(2),
    cfInvocations: Math.round(cfInvocations),
    rtdbBandwidthGB: +rtdbBandwidthGB.toFixed(2),
    fsCost,
    stCost,
    rtdbCost,
    cfCost,
    egressCost,
    total,
    costPerStore: total / Math.max(stores, 1),
    costPerOrder: total / Math.max(totalOrders, 1),
    costPerCustomer: total / Math.max(customers, 1),
    costPerProduct: total / Math.max(productImages, 1),
    costPerDriver: drivers > 0 ? (rtdbCost * 0.7) / drivers : 0,
  };
}

const COLLECTIONS = [
  { name: "orders", reads: 18, writes: 9, deletes: 0.2, sizeKB: 8, updatesDay: 4, monthly: 0.42 },
  { name: "markets", reads: 6, writes: 1.5, deletes: 0.01, sizeKB: 7, updatesDay: 2, monthly: 0.08 },
  { name: "users", reads: 3, writes: 0.4, deletes: 0.001, sizeKB: 2.5, updatesDay: 0.3, monthly: 0.02 },
  { name: "markets/.../products/items", reads: 12, writes: 0.8, deletes: 0.05, sizeKB: 4, updatesDay: 0.5, monthly: 0.15 },
  { name: "markets/.../statistics", reads: 2, writes: 3, deletes: 0, sizeKB: 15, updatesDay: 8, monthly: 0.09 },
  { name: "markets/.../reviews", reads: 1.5, writes: 0.3, deletes: 0, sizeKB: 1, updatesDay: 0.2, monthly: 0.01 },
  { name: "Categories", reads: 4, writes: 0.1, deletes: 0, sizeKB: 0.5, updatesDay: 0.05, monthly: 0.01 },
  { name: "wallet_ledger", reads: 1.2, writes: 0.6, deletes: 0, sizeKB: 0.6, updatesDay: 0.4, monthly: 0.02 },
  { name: "wallet_transactions", reads: 0.8, writes: 0.2, deletes: 0, sizeKB: 0.7, updatesDay: 0.1, monthly: 0.01 },
  { name: "support_conversations", reads: 0.5, writes: 0.15, deletes: 0, sizeKB: 1.2, updatesDay: 0.1, monthly: 0.005 },
  { name: "courier_requests", reads: 1.8, writes: 0.2, deletes: 0, sizeKB: 2, updatesDay: 0.3, monthly: 0.02 },
  { name: "announcements", reads: 2, writes: 0.05, deletes: 0.01, sizeKB: 1.5, updatesDay: 0.05, monthly: 0.01 },
  { name: "app_settings/home_ads", reads: 3, writes: 0.1, deletes: 0, sizeKB: 8, updatesDay: 0.2, monthly: 0.01 },
  { name: "present_order (projection)", reads: 5, writes: 6, deletes: 0.2, sizeKB: 9, updatesDay: 3, monthly: 0.22 },
  { name: "pending_payments", reads: 0.3, writes: 0.15, deletes: 0.1, sizeKB: 0.5, updatesDay: 0.1, monthly: 0.005 },
];

const PRODUCT_TIERS = [50, 100, 300, 500, 1000, 5000].map((p) => {
  const b = monthlyBill(1, 300, p, 150, 2);
  return { products: p, reads: b.reads, writes: b.writes, storageGB: b.storageGB, total: b.total };
});

const ORDER_TIERS = [100, 300, 500, 1000, 3000, 5000, 10000].map((o) => {
  const b = monthlyBill(1, o, 150, Math.round(o * 0.5), 2);
  return { orders: o, reads: b.reads, writes: b.writes, cf: b.cfInvocations, total: b.total };
});

const CAPACITY = [100, 500, 1000, 3000, 5000, 10000].map((s) => {
  const b = monthlyBill(s, 300, 150, s * 150, s * 2);
  const opt = monthlyBill(s, 300, 150, s * 150, s * 2, true);
  return {
    stores: s,
    readsM: +(b.reads / 1e6).toFixed(1),
    writesK: Math.round(b.writes / 1000),
    storageGB: b.storageGB,
    cfM: +(b.cfInvocations / 1e6).toFixed(2),
    rtdbGB: b.rtdbBandwidthGB,
    total: b.total,
    optimized: opt.total,
  };
});

const PRICING_TIERS = [
  { tier: "Starter", products: 50, orders: 100, price: 75, stores: "1-50" },
  { tier: "Basic", products: 150, orders: 300, price: 120, stores: "51-200" },
  { tier: "Pro", products: 500, orders: 1000, price: 200, stores: "201-500" },
  { tier: "Business", products: 1500, orders: 3000, price: 350, stores: "501-1500" },
  { tier: "Enterprise", products: 5000, orders: 10000, price: 600, stores: "1500+" },
];

const JOURNEY = [
  { step: "فتح التطبيق", reads: 38, writes: 0, storageKB: 0, bandwidthKB: 120 },
  { step: "تسجيل الدخول", reads: 2, writes: 2, storageKB: 0, bandwidthKB: 0 },
  { step: "الصفحة الرئيسية", reads: 28, writes: 0, storageKB: 0, bandwidthKB: 450 },
  { step: "فتح متجر", reads: 62, writes: 0, storageKB: 0, bandwidthKB: 800 },
  { step: "عرض منتج", reads: 9, writes: 0, storageKB: 0, bandwidthKB: 120 },
  { step: "إضافة للسلة", reads: 0, writes: 0, storageKB: 0, bandwidthKB: 0 },
  { step: "الدفع / Checkout", reads: 4, writes: 5, storageKB: 0, bandwidthKB: 0 },
  { step: "تتبع الطلب", reads: 12, writes: 0, storageKB: 0, bandwidthKB: 180 },
  { step: "إنهاء + تقييم", reads: 3, writes: 6, storageKB: 0, bandwidthKB: 0 },
];

const journeyTotal = JOURNEY.reduce(
  (a, s) => ({
    reads: a.reads + s.reads,
    writes: a.writes + s.writes,
    storageKB: a.storageKB + s.storageKB,
    bandwidthKB: a.bandwidthKB + s.bandwidthKB,
  }),
  { reads: 0, writes: 0, storageKB: 0, bandwidthKB: 0 }
);

const SCREENS = [
  { screen: "HomePage", reads: 35, writes: 0, listeners: 2, queries: 2, cache: "جزئي", saving: "Pagination + Bundle" },
  { screen: "HomeMarketPage", reads: 56, writes: 0, listeners: 0, queries: 3, cache: "Cache-first", saving: "Cursor pagination للمنتجات" },
  { screen: "ProductDetails", reads: 9, writes: 0, listeners: 0, queries: 2, cache: "نعم", saving: "قراءة item مباشرة" },
  { screen: "CartPage", reads: 4, writes: 5, listeners: 0, queries: 2, cache: "لا", saving: "Batch writes" },
  { screen: "UserOrdersPage", reads: 8, writes: 0, listeners: 1, queries: 1, cache: "لا", saving: "limit + pagination" },
  { screen: "MarketOrdersPage", reads: 25, writes: 3, listeners: 3, queries: 2, cache: "لا", saving: "إزالة listeners مكررة" },
  { screen: "ManageProducts", reads: 80, writes: 2, listeners: 0, queries: 4, cache: "لا", saving: "Lazy load categories" },
  { screen: "WalletPage", reads: 6, writes: 0, listeners: 3, queries: 0, cache: "لا", saving: "دمج listeners" },
  { screen: "SupportChat", reads: 15, writes: 2, listeners: 1, queries: 0, cache: "لا", saving: "limit 30 رسالة" },
];

const CF_FUNCTIONS = [
  { fn: "sendNewOrderNotification", trigger: "orders onCreate", monthly: 300, cost: 0.00012 },
  { fn: "sendOrderStatusNotification", trigger: "present_order onUpdate", monthly: 900, cost: 0.00036 },
  { fn: "sendPastOrderNotification", trigger: "past_order onCreate", monthly: 300, cost: 0.00012 },
  { fn: "sendSupportReplyNotification", trigger: "messages onCreate", monthly: 20, cost: 0.000008 },
  { fn: "paymobWebhookHandler", trigger: "HTTP", monthly: 30, cost: 0.000012 },
  { fn: "autoRenewSubscriptions", trigger: "hourly", monthly: 720, cost: 0.000288 },
  { fn: "updateStoreOpenStatus", trigger: "*/15 min", monthly: 2880, cost: 0.00115 },
  { fn: "cleanupExpiredPending", trigger: "hourly", monthly: 720, cost: 0.000288 },
  { fn: "deleteExpiredAdsImages", trigger: "daily", monthly: 30, cost: 0.000012 },
];

const BREAK_EVEN = [30, 50, 75, 100, 150, 200].map((price) => {
  const base = monthlyBill(100, 300, 150, 15000, 200);
  const infraOverhead = base.total * 0.35;
  const supportDev = 500 / P.egp;
  const targetRevenue = (base.total + infraOverhead + supportDev) * 2;
  const storesNeeded = Math.ceil(targetRevenue / (price / P.egp));
  return { price, storesNeeded, revenue: storesNeeded * (price / P.egp) };
});

export default function BazaarSuezFinancialPlan() {
  const theme = useHostTheme();
  const [scenario, setScenario] = useCanvasState("scenario", "1000 stores");
  const scenarios: Record<string, { stores: number; orders: number; products: number }> = {
    "100 stores": { stores: 100, orders: 300, products: 150 },
    "500 stores": { stores: 500, orders: 300, products: 150 },
    "1000 stores": { stores: 1000, orders: 300, products: 150 },
    "3000 stores": { stores: 3000, orders: 300, products: 150 },
  };
  const s = scenarios[scenario] ?? scenarios["1000 stores"];
  const bill = monthlyBill(s.stores, s.orders, s.products, s.stores * 150, s.stores * 2);
  const billOpt = monthlyBill(s.stores, s.orders, s.products, s.stores * 150, s.stores * 2, true);

  const costChart = CAPACITY.map((c) => ({
    label: `${c.stores}`,
    current: +c.total.toFixed(0),
    optimized: +c.optimized.toFixed(0),
  }));

  const orderChart = ORDER_TIERS.map((o) => ({
    label: `${o.orders}`,
    cost: +o.total.toFixed(2),
  }));

  return (
    <Stack gap={20} style={{ padding: 20, fontFamily: "system-ui, sans-serif" }}>
      <Stack gap={4}>
        <H1>Bazaar Suez — Financial Capacity Plan</H1>
        <Text style={{ color: theme.textSecondary }}>
          تحليل تكلفة Firebase مبني على كود المشروع الفعلي · Blaze Plan · 1 USD = {P.egp} EGP · يوليو 2026
        </Text>
      </Stack>

      <Row gap={12} align="center">
        <Text style={{ color: theme.textSecondary }}>سيناريو السعة:</Text>
        <Select
          value={scenario}
          onChange={setScenario}
          options={Object.keys(scenarios).map((k) => ({ value: k, label: k }))}
        />
      </Row>

      <Grid columns={4} gap={12}>
        <Stat label="تكلفة المتجر/شهر" value={egp(bill.costPerStore)} tone="accent" />
        <Stat label="تكلفة الطلب" value={egp(bill.costPerOrder)} />
        <Stat label="تكلفة العميل/شهر" value={egp(bill.costPerCustomer)} />
        <Stat label="الفاتورة الشهرية" value={usd(bill.total)} tone="warning" />
      </Grid>

      <Grid columns={3} gap={12}>
        <Stat label="بعد التحسين (-72%)" value={usd(billOpt.total)} tone="success" />
        <Stat label="تكلفة المنتج/شهر" value={egp(bill.costPerProduct)} />
        <Stat label="تكلفة المندوب/شهر" value={egp(bill.costPerDriver)} />
      </Grid>

      <Card>
        <CardHeader title="لوحة التكلفة التشغيلية — Dashboard" />
        <CardBody>
          <Grid columns={4} gap={8}>
            <Stat label="تكلفة/عملية قراءة" value={egp(P.fsRead * P.egp)} />
            <Stat label="تكلفة/عملية كتابة" value={egp(P.fsWrite * P.egp)} />
            <Stat label="تكلفة/صورة (تخزين+نقل)" value="0.02 ج.م" />
            <Stat label="تكلفة/إشعار FCM" value="مجاني" />
            <Stat label="تكلفة/CF invocation" value={egp(P.cfInvocation * P.egp)} />
            <Stat label="Firestore Reads" value={`${(bill.reads / 1e6).toFixed(1)}M`} />
            <Stat label="Firestore Writes" value={`${(bill.writes / 1e3).toFixed(0)}K`} />
            <Stat label="Cloud Functions" value={`${(bill.cfInvocations / 1e3).toFixed(0)}K`} />
          </Grid>
        </CardBody>
      </Card>

      <Grid columns={2} gap={16}>
        <Card>
          <CardHeader title="تكلفة السعة حسب عدد المتاجر (USD/شهر)" />
          <CardBody>
            <BarChart
              data={costChart}
              xKey="label"
              series={[
                { key: "current", label: "البنية الحالية", tone: "warning" },
                { key: "optimized", label: "بعد التحسين 72%", tone: "success" },
              ]}
              xLabel="عدد المتاجر"
              yLabel="التكلفة (USD)"
            />
            <Text style={{ color: theme.textSecondary, fontSize: 12, marginTop: 8 }}>
              Source: نموذج Bazaar Suez · 300 طلب/متجر · 150 منتج · يوليو 2026
            </Text>
          </CardBody>
        </Card>

        <Card>
          <CardHeader title="تكلفة Firebase حسب حجم المبيعات (متجر واحد)" />
          <CardBody>
            <LineChart
              data={orderChart}
              xKey="label"
              series={[{ key: "cost", label: "التكلفة الشهرية USD", tone: "accent" }]}
              xLabel="طلبات/شهر"
              yLabel="USD"
            />
            <Text style={{ color: theme.textSecondary, fontSize: 12, marginTop: 8 }}>
              Source: نموذج الطلب الواحد · 150 منتج · يوليو 2026
            </Text>
          </CardBody>
        </Card>
      </Grid>

      <CollapsibleSection title="المرحلة 1 — Firestore Collections" summary={`${COLLECTIONS.length} collections · متجر نموذجي 300 طلب`}>
        <Table
          columns={[
            { key: "name", header: "Collection", width: "22%" },
            { key: "reads", header: "Reads K/شهر", align: "right" },
            { key: "writes", header: "Writes K", align: "right" },
            { key: "deletes", header: "Deletes K", align: "right" },
            { key: "sizeKB", header: "حجم Doc KB", align: "right" },
            { key: "updatesDay", header: "تحديثات/يوم", align: "right" },
            { key: "monthly", header: "تكلفة USD", align: "right" },
          ]}
          rows={COLLECTIONS.map((c) => ({
            name: c.name,
            reads: (c.reads * 300).toFixed(1),
            writes: (c.writes * 300).toFixed(1),
            deletes: (c.deletes * 300).toFixed(1),
            sizeKB: c.sizeKB,
            updatesDay: c.updatesDay,
            monthly: c.monthly.toFixed(3),
          }))}
        />
      </CollapsibleSection>

      <CollapsibleSection title="المرحلة 6 — تحليل الشاشات" summary="9 شاشات رئيسية + توصيات">
        <Table
          columns={[
            { key: "screen", header: "Screen" },
            { key: "reads", header: "Reads", align: "right" },
            { key: "writes", header: "Writes", align: "right" },
            { key: "listeners", header: "Listeners", align: "right" },
            { key: "queries", header: "Queries", align: "right" },
            { key: "cache", header: "Cache" },
            { key: "saving", header: "تقليل التكلفة" },
          ]}
          rows={SCREENS}
        />
      </CollapsibleSection>

      <CollapsibleSection title="المرحلة 7 — رحلة العميل الكاملة" summary={`${journeyTotal.reads} reads · ${journeyTotal.writes} writes لكل طلب`}>
        <Table
          columns={[
            { key: "step", header: "الخطوة" },
            { key: "reads", header: "Reads", align: "right" },
            { key: "writes", header: "Writes", align: "right" },
            { key: "bandwidthKB", header: "Bandwidth KB", align: "right" },
          ]}
          rows={JOURNEY}
        />
        <Text style={{ color: theme.textSecondary, marginTop: 8 }}>
          إجمالي الرحلة: {journeyTotal.reads} reads · {journeyTotal.writes} writes · {(journeyTotal.bandwidthKB / 1024).toFixed(1)} MB bandwidth · بعد التحسين: ~{Math.round(journeyTotal.reads * OPT)} reads
        </Text>
      </CollapsibleSection>

      <CollapsibleSection title="المرحلة 8 — Cost Model حسب عدد المنتجات" summary="متجر واحد · 300 طلب/شهر">
        <Table
          columns={[
            { key: "products", header: "منتجات", align: "right" },
            { key: "reads", header: "Reads", align: "right" },
            { key: "writes", header: "Writes", align: "right" },
            { key: "storageGB", header: "Storage GB", align: "right" },
            { key: "total", header: "USD/شهر", align: "right" },
            { key: "egp", header: "EGP/شهر", align: "right" },
          ]}
          rows={PRODUCT_TIERS.map((r) => ({
            ...r,
            total: r.total.toFixed(2),
            egp: egp(r.total),
          }))}
        />
      </CollapsibleSection>

      <CollapsibleSection title="المرحلة 9 — Sales Simulation" summary="طلبات/شهر لمتجر واحد">
        <Table
          columns={[
            { key: "orders", header: "طلبات", align: "right" },
            { key: "reads", header: "Reads", align: "right" },
            { key: "writes", header: "Writes", align: "right" },
            { key: "cf", header: "CF Invocations", align: "right" },
            { key: "total", header: "USD", align: "right" },
            { key: "egp", header: "EGP", align: "right" },
          ]}
          rows={ORDER_TIERS.map((r) => ({
            ...r,
            total: r.total.toFixed(2),
            egp: egp(r.total),
          }))}
        />
      </CollapsibleSection>

      <CollapsibleSection title="المرحلة 10 — Break Even" summary="هامش ربح 50% + بنية تحتية 35%">
        <Table
          columns={[
            { key: "price", header: "اشتراك (ج.م)", align: "right" },
            { key: "storesNeeded", header: "متاجر للتعادل", align: "right" },
            { key: "revenue", header: "إيراد شهري USD", align: "right" },
          ]}
          rows={BREAK_EVEN.map((r) => ({
            price: r.price,
            storesNeeded: r.storesNeeded,
            revenue: usd(r.revenue),
          }))}
        />
      </CollapsibleSection>

      <CollapsibleSection title="المرحلة 11 — نظام مستويات المتاجر" summary="5 tiers">
        <Table
          columns={[
            { key: "tier", header: "المستوى" },
            { key: "products", header: "حد المنتجات", align: "right" },
            { key: "orders", header: "طلبات متوقعة", align: "right" },
            { key: "price", header: "السعر المقترح (ج.م)", align: "right" },
            { key: "stores", header: "الفئة المستهدفة" },
          ]}
          rows={PRICING_TIERS}
        />
      </CollapsibleSection>

      <CollapsibleSection title="المرحلة 12 — أقصى Capacity" summary="300 طلب · 150 منتج · متجر">
        <Table
          columns={[
            { key: "stores", header: "متاجر", align: "right" },
            { key: "readsM", header: "Reads (M)", align: "right" },
            { key: "writesK", header: "Writes (K)", align: "right" },
            { key: "storageGB", header: "Storage GB", align: "right" },
            { key: "cfM", header: "CF (M)", align: "right" },
            { key: "rtdbGB", header: "RTDB GB", align: "right" },
            { key: "total", header: "USD", align: "right" },
            { key: "optimized", header: "بعد التحسين", align: "right" },
          ]}
          rows={CAPACITY.map((c) => ({
            ...c,
            total: usd(c.total),
            optimized: usd(c.optimized),
          }))}
        />
      </CollapsibleSection>

      <CollapsibleSection title="المرحلة 4 — Cloud Functions" summary="9 functions نشطة">
        <Table
          columns={[
            { key: "fn", header: "Function" },
            { key: "trigger", header: "Trigger" },
            { key: "monthly", header: "تشغيل/شهر (متجر 300 طلب)", align: "right" },
            { key: "cost", header: "USD", align: "right" },
          ]}
          rows={CF_FUNCTIONS.map((f) => ({ ...f, cost: f.cost.toFixed(5) }))}
        />
      </CollapsibleSection>

      <Card>
        <CardHeader title="المرحلة 16 — استراتيجية التسعير النهائية" />
        <CardBody>
          <Stack gap={8}>
            <H3>هيكل التكلفة الكاملة (لكل 1000 متجر)</H3>
            <Table
              columns={[
                { key: "item", header: "البند" },
                { key: "pct", header: "%", align: "right" },
                { key: "usd", header: "USD/شهر", align: "right" },
              ]}
              rows={[
                { item: "Firebase Infrastructure", pct: "40%", usd: usd(bill.total) },
                { item: "طوارئ + بنية تحتية", pct: "15%", usd: usd(bill.total * 0.15) },
                { item: "دعم فني (2 موظف)", pct: "20%", usd: usd(800) },
                { item: "تطوير مستمر", pct: "15%", usd: usd(600) },
                { item: "هامش توسع", pct: "10%", usd: usd(bill.total * 0.1) },
                { item: "إجمالي التكلفة", pct: "100%", usd: usd(bill.total * 1.65 + 1400) },
                { item: "الإيراد المستهدف (+50% ربح)", pct: "—", usd: usd((bill.total * 1.65 + 1400) * 1.5) },
                { item: "اشتراك Pro المقترح", pct: "—", usd: "200 ج.م ($4)" },
              ]}
            />
          </Stack>
        </CardBody>
      </Card>

      <Card>
        <CardHeader title="المرحلة 15 — توصيات تقليل التكلفة 70%+" />
        <CardBody>
          <Stack gap={6}>
            {[
              "إزالة present_order/past_order projection — توفير 35% writes",
              "Cursor Pagination للمنتجات (20/صفحة) — توفير 80% reads في المتجر",
              "Firestore Bundles للـ Categories + Home — توفير 60% reads عند الفتح",
              "إيقاف updateStoreOpenStatus لكل المتاجر — حساب isOpenNow محلياً — توفير 40% عند 1000+ متجر",
              "دمج StoreNewOrderListener + OrderService listener — توفير 25% merchant reads",
              "ضغط صور WebP 80KB بدل 400KB — توفير 80% Storage/Bandwidth",
              "Distributed Counters للإحصائيات — توفير 90% statistics writes",
              "Batch Writes في Checkout — توفير 30% write ops",
              "Cache 5min للـ settings/delivery_fee — توفير 95% reads",
              "FCM فقط للإشعارات (إزالة listeners مكررة) — توفير 20% merchant",
            ].map((t) => (
              <Text key={t}>• {t}</Text>
            ))}
          </Stack>
        </CardBody>
      </Card>
    </Stack>
  );
}
