# Order Status Lifecycle (Merchant / Courier / Customer)

Unified Firestore collection: `orders`

## Independent courier flow (`dispatchType: independent_courier`)

| Status | Active? | Who sets it | Meaning |
|--------|---------|-------------|---------|
| `searching` | yes | Merchant dispatch | Waiting for courier acceptance |
| `accepted` | yes | Courier accept | Courier assigned, not picked up yet |
| `picked_up` | yes | Courier | Goods collected from store |
| `delivered` / `completed` | no | Courier | Successfully delivered |
| `returned_to_merchant` | **yes** | Courier release | Courier gave up / returned — merchant must redispatch or cancel |
| `cancelled_by_merchant` | no | Merchant | Final cancellation by store |
| `cancelled_by_customer` | no | Customer | Final cancellation by buyer |
| `rejected` | no | Merchant | Order rejected at acceptance |

### Courier release fields (`returned_to_merchant`)

- `returnedBy`: `'courier'`
- `goodsPickedUp`: `false` (before pickup) | `true` (after pickup, physical return)
- `returnReason`, `returnedAt`, `previousCourierId`
- `assignedCourierId`: cleared
- `isActive`: stays `true`

### Merchant actions after courier return

1. **Auto redispatch** — nearest available couriers (excludes `released` / `rejected`)
2. **Manual redispatch** — picker sheet
3. **Final cancel** — `cancelled_by_merchant` + `isActive: false`

## Rules

- **Couriers cannot terminate orders.** They only release back to merchant.
- **Only merchant/customer** can set terminal cancelled states.
- Merchant active list: `isActive == true` (returned orders remain visible).
