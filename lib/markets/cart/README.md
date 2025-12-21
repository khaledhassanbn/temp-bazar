# Cart System Documentation

This cart system implements a complete MVVM pattern with Hive local storage for persistent cart functionality.

## Features

✅ **MVVM Architecture**: Clean separation of concerns with CartViewModel handling business logic
✅ **Hive Local Storage**: Cart data persists across app restarts
✅ **Market Validation**: Prevents mixing products from different markets
✅ **Edit Functionality**: Pre-fills product details when editing cart items
✅ **Navigation Integration**: Seamless navigation between cart and product pages

## Files Structure

```
lib/markets/cart/
├── models/
│   └── cart_item_model.dart          # Hive model for cart items
├── viewmodels/
│   └── cart_view_model.dart          # MVVM ViewModel for cart operations
├── pages/
│   └── cart_page.dart                # Cart UI page
├── widgets/
│   ├── cart_item_card.dart           # Individual cart item widget
│   ├── cart_bottom_buttons.dart      # Checkout and add more buttons
│   ├── cart_summary_section.dart     # Price summary section
│   ├── cart_notes_section.dart       # Notes input section
│   └── cart_coupon_section.dart      # Coupon input section
└── README.md                         # This documentation
```

## Cart Item Model

The `CartItemModel` stores:
- `productId`: Unique product identifier
- `productName`: Display name of the product
- `productImage`: Product image URL
- `productPrice`: Base price of the product
- `selectedOptions`: Map of selected product options
- `quantity`: Number of items
- `marketId`: ID of the market/store
- `categoryId`: Product category ID
- `additionalPrice`: Price from selected options
- `addedAt`: Timestamp when added to cart

## Cart ViewModel Methods

### Core Operations
- `addItem(CartItemModel item)`: Add item to cart with market validation
- `addItemWithMarketReplacement(CartItemModel item)`: Replace cart with new market items
- `removeItem(int index)`: Remove item by index
- `updateItemQuantity(int index, int quantity)`: Update item quantity
- `clearCart()`: Remove all items from cart

### Getters
- `cartItems`: Observable list of cart items
- `isEmpty`: Check if cart is empty
- `subtotal`: Calculate subtotal
- `totalAmount`: Calculate total with fees
- `currentMarketId`: Get current market ID

## Usage Examples

### Adding Item to Cart
```dart
final cartViewModel = context.read<CartViewModel>();
final cartItem = CartItemModel(
  productId: 'product123',
  productName: 'Product Name',
  productPrice: 25.0,
  selectedOptions: {'size': 'large', 'color': 'red'},
  quantity: 2,
  marketId: 'market1',
  categoryId: 'category1',
);

final success = await cartViewModel.addItem(cartItem);
if (!success) {
  // Different market detected - show confirmation dialog
  await _showMarketReplacementDialog();
}
```

### Editing Cart Item
```dart
// Navigate to ProductDetailsPage with edit data
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ProductDetailsPage(
      marketId: cartItem.marketId,
      categoryId: cartItem.categoryId,
      itemId: cartItem.productId,
      editItem: cartItem, // Pre-fill form data
    ),
  ),
);
```

### Market Validation
The system automatically detects when adding items from different markets and shows a confirmation dialog:
- "Your current cart contains products from another market. Do you want to replace them?"
- User can choose to replace or cancel the operation

## Integration Points

### Main App Setup
```dart
// In main.dart
await HiveAdaptersSetup.initializeHive();

// Provider setup
ChangeNotifierProvider(
  create: (_) {
    final cartViewModel = CartViewModel();
    cartViewModel.initialize();
    return cartViewModel;
  },
),
```

### Product Details Page
- Integrates with CartViewModel for adding items
- Handles market validation and confirmation dialogs
- Pre-fills form data when editing existing items

### Cart Page
- Displays all cart items from Hive storage
- Handles quantity updates and item removal
- Provides edit and navigation functionality
- Shows empty state when cart is empty

## Error Handling

The system includes comprehensive error handling:
- Network errors when loading products
- Validation errors for required options
- Storage errors with Hive operations
- User-friendly error messages in Arabic

## Performance Considerations

- Uses Hive for fast local storage
- Implements efficient list operations
- Minimizes unnecessary UI rebuilds
- Handles large cart datasets efficiently

## Future Enhancements

- [ ] Add cart synchronization with backend
- [ ] Implement cart sharing functionality
- [ ] Add cart item favorites
- [ ] Implement cart item recommendations
- [ ] Add bulk operations (select multiple items)
