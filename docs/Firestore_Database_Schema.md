# Libro Espresso Decision Support System - Firestore Database Architecture (Finalized)

This document defines the complete, scalable Firestore NoSQL schema to support Libro Espresso’s CRUD operations, business logic, forecasting, inventory, COGS calculation, AI Insights, and reporting. 

---

## 1. Collection Hierarchy & Definitions

All collections are positioned at the root level to minimize deep nesting limitations and ensure highly efficient, independent queries.

### 1. `users`
**Purpose:** Stores user authentication metadata and role assignments.
**Relationships:** 1 Owner manages N Branches. 1 Manager manages 1 Branch.
```json
{
  "id": "String (Document ID)",
  "email": "String (Required)",
  "displayName": "String (Required)",
  "role": "String (Required) ['owner', 'manager']",
  "assignedBranchId": "String (Optional) // Required if role == 'manager'",
  "createdAt": "Timestamp (Required)",
  "updatedAt": "Timestamp (Required)",
  "createdBy": "String (Required)"
}
```

### 2. `branches`
**Purpose:** Represents physical coffee shop locations.
**Relationships:** 1:N with Sales, Inventory, Forecasts.
```json
{
  "id": "String (Document ID)",
  "name": "String (Required)",
  "location": "String (Required)",
  "status": "String (Required) ['active', 'inactive']",
  "createdBy": "String (Required)",
  "createdAt": "Timestamp (Required)",
  "updatedAt": "Timestamp (Required)"
}
```

### 3. `products`
**Purpose:** Final sellable items on the menu.
**Relationships:** 1:1 with `recipes`.
```json
{
  "id": "String (Document ID)",
  "name": "String (Required)",
  "description": "String (Optional)",
  "category": "String (Required) ['hot_coffee', 'iced_coffee', 'pastry', etc.]",
  "sellingPrice": "Number (Required)",
  "isAvailable": "Boolean (Required)",
  "status": "String (Required) ['active', 'inactive']",
  "imageUrl": "String (Optional)",
  "createdBy": "String (Required)",
  "createdAt": "Timestamp (Required)",
  "updatedAt": "Timestamp (Required)"
}
```

### 4. `ingredients`
**Purpose:** Base inventory units (raw materials) used to compute COGS and track stock levels.
**Relationships:** 1:N with Recipes and Inventory Movements.
```json
{
  "id": "String (Document ID)",
  "branchId": "String (Required) // Allows branch-specific ingredient costs/stock",
  "name": "String (Required) // e.g., 'Whole Milk', 'Espresso Beans'",
  "unitOfMeasurement": "String (Required) // e.g., 'ml', 'g', 'pcs'",
  "unitCost": "Number (Required) // Cost per 1 unitOfMeasurement",
  "currentStock": "Number (Required) // Cached sum of inventory_movements for fast UI reads",
  "createdBy": "String (Required)",
  "createdAt": "Timestamp (Required)",
  "updatedAt": "Timestamp (Required)"
}
```

### 5. `recipes`
**Purpose:** Maps products to the exact quantities of ingredients required for one serving.
**Relationships:** Belongs to 1 `Product`. Contains references to N `Ingredients`.
```json
{
  "id": "String (Document ID)",
  "productId": "String (Required)",
  "version": "Number (Required) // Increments on recipe updates to preserve historical calculations",
  "servingSize": "String (Optional) // e.g., '16oz', '1 slice'",
  "ingredients": [
    {
      "ingredientId": "String (Required)",
      "quantityPerServing": "Number (Required)"
    }
  ],
  "createdBy": "String (Required)",
  "createdAt": "Timestamp (Required)",
  "updatedAt": "Timestamp (Required)"
}
```

### 6. `sales`
**Purpose:** Stores historical Point-of-Sale transaction lines uploaded from Excel.
**Relationships:** Belongs to 1 Branch and 1 Product.
```json
{
  "id": "String (Document ID)",
  "branchId": "String (Required)",
  "branchName": "String (Required) // Denormalized for fast reporting",
  "productId": "String (Required)",
  "productName": "String (Required) // Denormalized for query efficiency",
  "category": "String (Required) // Denormalized from product for quick dashboard filtering",
  "salesDate": "Timestamp (Required)",
  "quantitySold": "Number (Required)",
  "sellingPrice": "Number (Required)",
  "totalAmount": "Number (Required)",
  "importedFromFileUrl": "String (Optional)",
  "createdBy": "String (Required)",
  "createdAt": "Timestamp (Required)",
  "updatedAt": "Timestamp (Required)"
}
```

### 7. `inventory_movements`
**Purpose:** Immutable ledger of every single stock change to compute real-time "Expected Stock".
**Relationships:** Belongs to 1 Branch and 1 Ingredient.
```json
{
  "id": "String (Document ID)",
  "branchId": "String (Required)",
  "ingredientId": "String (Required)",
  "movementType": "String (Required) ['stock_in', 'usage', 'spoilage', 'wastage', 'pilferage', 'adjustment']",
  "quantity": "Number (Required) // Positive for IN, Negative for OUT",
  "referenceId": "String (Optional) // Ties back to a saleId or inventoryCountId",
  "remarks": "String (Optional)",
  "createdBy": "String (Required)",
  "createdAt": "Timestamp (Required)",
  "updatedAt": "Timestamp (Required)"
}
```

### 8. `inventory_counts`
**Purpose:** Stores physical audit logs where real stock is manually counted, generating variances.
**Relationships:** Belongs to 1 Branch.
```json
{
  "id": "String (Document ID)",
  "branchId": "String (Required)",
  "countDate": "Timestamp (Required)",
  "status": "String (Required) ['draft', 'completed']",
  "remarks": "String (Optional)",
  "approvedBy": "String (Optional)",
  "approvedAt": "Timestamp (Optional)",
  "items": [
    {
      "ingredientId": "String (Required)",
      "expectedQuantity": "Number (Required) // Derived dynamically at count time",
      "actualQuantity": "Number (Required)",
      "varianceQuantity": "Number (Required) // (actual - expected)",
      "varianceReason": "String (Optional) // 'spoilage', 'wastage', 'pilferage', 'adjustment'"
    }
  ],
  "createdBy": "String (Required)",
  "createdAt": "Timestamp (Required)",
  "updatedAt": "Timestamp (Required)"
}
```

### 9. `forecasts`
**Purpose:** Stores AI/Statistical sales projections and the resulting raw material requirements.
**Relationships:** Belongs to 1 Branch.
```json
{
  "id": "String (Document ID)",
  "branchId": "String (Required)",
  "forecastPeriodStart": "Timestamp (Required)",
  "forecastPeriodEnd": "Timestamp (Required)",
  "algorithm": "String (Required) // e.g. 'ARIMA', 'Prophet', 'MovingAverage'",
  "status": "String (Required) ['processing', 'completed', 'failed']",
  "generatedBy": "String (Required) // System or User ID",
  "productPredictions": [
    {
      "productId": "String (Required)",
      "predictedQuantity": "Number (Required)",
      "confidenceLevel": "Number (Required)"
    }
  ],
  "estimatedIngredientConsumption": [
    {
      "ingredientId": "String (Required)",
      "requiredQuantity": "Number (Required)"
    }
  ],
  "createdAt": "Timestamp (Required)",
  "updatedAt": "Timestamp (Required)"
}
```

### 10. `ai_insights`
**Purpose:** Stores proactive business recommendations generated by the decision support engine.
**Relationships:** Belongs to 1 Branch.
```json
{
  "id": "String (Document ID)",
  "branchId": "String (Required)",
  "title": "String (Required)",
  "description": "String (Required)",
  "severity": "String (Required) ['low', 'medium', 'high']",
  "category": "String (Required) ['sales', 'inventory', 'forecast']",
  "isDismissed": "Boolean (Required)",
  "actionTaken": "String (Optional)",
  "generatedAt": "Timestamp (Required)",
  "createdBy": "String (Required)",
  "createdAt": "Timestamp (Required)",
  "updatedAt": "Timestamp (Required)"
}
```

### 11. `notifications`
**Purpose:** System and operational alerts (e.g., low stock warnings).
**Relationships:** Belongs to 1 Branch (or global if null).
```json
{
  "id": "String (Document ID)",
  "branchId": "String (Optional)",
  "type": "String (Required) ['low_stock', 'forecast_alert', 'variance_alert', 'system']",
  "title": "String (Required)",
  "message": "String (Required)",
  "readBy": "Array of Strings (Required) // User IDs who have read this",
  "readAt": "Timestamp (Optional)",
  "createdBy": "String (Required)",
  "createdAt": "Timestamp (Required)",
  "updatedAt": "Timestamp (Required)"
}
```

### 12. `reports`
**Purpose:** Metadata tracking for system-generated reports (Dashboards, COGS, Inventory Summaries). Do not store files in DB.
**Relationships:** Belongs to 1 Branch.
```json
{
  "id": "String (Document ID)",
  "branchId": "String (Optional)",
  "reportType": "String (Required) ['sales_summary', 'cogs_analysis', 'variance_report']",
  "status": "String (Required) ['generating', 'ready', 'failed']",
  "filtersUsed": "Map (Optional) // e.g. { startDate: '...', endDate: '...' }",
  "generatedFileName": "String (Required)",
  "generatedDuration": "Number (Optional) // In milliseconds",
  "generatedBy": "String (Required)",
  "generatedAt": "Timestamp (Required)",
  "createdBy": "String (Required)",
  "createdAt": "Timestamp (Required)",
  "updatedAt": "Timestamp (Required)"
}
```

### 13. `settings`
**Purpose:** Global and user-specific configurations.
**Relationships:** Belongs to 1 User or Global.
```json
{
  "id": "String (Document ID) // Often equals userId, or 'global_business_settings'",
  "themePreference": "String (Required) ['light', 'dark', 'system']",
  "notificationSettings": "Map (Required) // e.g. { pushEnabled: true, lowStockAlerts: true }",
  "businessSettings": "Map (Optional) // e.g. { defaultCurrency: 'PHP', taxRate: 0.12 }",
  "createdBy": "String (Required)",
  "createdAt": "Timestamp (Required)",
  "updatedAt": "Timestamp (Required)"
}
```

### 14. `audit_logs` (NEW)
**Purpose:** Immutable ledger of system events and actions for security and tracking.
**Relationships:** 1:N with Branches and Users.
```json
{
  "id": "String (Document ID)",
  "userId": "String (Required)",
  "userRole": "String (Required)",
  "branchId": "String (Optional)",
  "module": "String (Required) // e.g. 'inventory', 'sales', 'users'",
  "action": "String (Required) // e.g. 'Stock Adjustment', 'Delete User'",
  "description": "String (Required)",
  "timestamp": "Timestamp (Required)",
  "createdAt": "Timestamp (Required)",
  "updatedAt": "Timestamp (Required)",
  "createdBy": "String (Required)"
}
```

---

## 2. Security Considerations (Owner vs Manager)

Firestore Rules will be built around these constraints and fully support the newly added fields:
* **Owner Profile:** Can `read`, `write`, `update`, and `delete` across ALL collections.
* **Manager Profile:** 
  * Can `read` global Products, Recipes.
  * Can `read/write` Ingredients, Sales, Inventory Movements, Inventory Counts, Forecasts, and Audit Logs **ONLY IF** `resource.data.branchId == request.auth.token.assignedBranchId`.
  * Can update `notifications.readBy` using `arrayUnion(request.auth.uid)`.
  * Cannot `write/delete` Branches, Users, or Global Settings.
  * **Audit Log Security:** Audit logs are write-only for standard operations (managers cannot delete or alter historical audit logs).

---

## 3. Recommended Composite Indexes

To ensure fast query performance on the dashboards with the new fields, the following composite indexes must be created in the Firebase Console:
1. **`sales`**: `branchId` (ASC) + `category` (ASC) + `salesDate` (DESC) - *For filtered branch revenue dashboards by category.*
2. **`inventory_movements`**: `branchId` (ASC) + `ingredientId` (ASC) + `createdAt` (DESC) - *For auditing specific ingredient ledgers.*
3. **`ingredients`**: `branchId` (ASC) + `currentStock` (ASC) - *For querying low-stock ingredients specifically for a branch.*
4. **`forecasts`**: `branchId` (ASC) + `status` (ASC) + `forecastPeriodStart` (DESC) - *To load completed predictions for a branch.*
5. **`notifications`**: `branchId` (ASC) + `createdAt` (DESC) - *To load alerts efficiently.*
6. **`audit_logs`**: `branchId` (ASC) + `module` (ASC) + `timestamp` (DESC) - *For filtering security events within a branch.*

---

## 4. System Data Flow Integrations

### Data Flow A: Sales to Inventory Usage (The Consumption Engine)
1. **Trigger:** Excel file is uploaded and parsed into `sales` documents.
2. **Processing:** For every new sale, the backend fetches the `Product`'s attached `Recipe`.
3. **Ledger Update:** The backend multiplies `sale.quantitySold` by each `recipe.ingredient.quantityPerServing`.
4. **Result:** Creates negative `inventory_movements` (type: "usage") for those ingredients. The `currentStock` field directly on the `Ingredient` document is transactionally decremented for immediate UI feedback.

### Data Flow B: COGS & Profit Margin Calculation
1. **Trigger:** Dashboard requests financial overview.
2. **Processing:** Fetches a `Product` and its `Recipe` (matching the current version).
3. **Calculation:** Iterates over the recipe's ingredients, fetching the current `unitCost` from the branch-specific `ingredients` collection. `Total Recipe Cost = Sum(Ingredient quantityPerServing * unitCost)`.
4. **Result:** Calculates `Profit = sellingPrice - Total Recipe Cost` dynamically. No duplicate COGS data is permanently stored, ensuring prices are always accurate to current ingredient costs.

### Data Flow C: Physical Count & Variance
1. **Trigger:** Manager submits an `inventory_counts` document.
2. **Processing:** Backend verifies `actualQuantity` against `expectedQuantity` derived from the `currentStock` cache. 
3. **Result:** If `expected != actual`, a new `inventory_movements` record is created with the variance amount, categorized by `varianceReason` (spoilage, wastage, pilferage). Expected stock aligns with actual stock. Document is stamped with `approvedBy`.

### Data Flow D: Forecast to Ingredient Procurement
1. **Trigger:** Selected AI Algorithm completes processing of historical `sales`.
2. **Processing:** Updates the `forecasts` document `status` to `completed`.
3. **Mapping:** Cross-references the predicted products against their `recipes`.
4. **Result:** Generates the `estimatedIngredientConsumption` array inside the forecast, advising managers exactly how many units of raw ingredients they need to purchase for the coming week.
