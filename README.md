# Libro Espresso – Decision Support System

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white) ![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white) ![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)

## Project Overview

**Libro Espresso** is a Decision Support System (DSS) developed for a multi-branch library café. It assists owners and branch managers in monitoring operations, inventory, sales, costs, forecasting, and business performance through data-driven insights.

---

## Technologies Used

### Frontend
- **Flutter & Dart**: Cross-platform framework and language used for a natively compiled, responsive application.

### Backend
- **Firebase Cloud Firestore**: NoSQL document database used as the primary backend. It handles all real-time data persistence and synchronization.

*Note: This project relies solely on Cloud Firestore. Authentication is handled natively through custom Firestore user records. It does not use Firebase Authentication, Firebase Storage, Firebase Hosting, or Firebase Cloud Messaging.*

---

## Features

### Authentication & Access Control
- **Role-Based Access**: Specialized views for Owners (all branches) and Branch Managers (localized data).
- **Account Management**: Activate, deactivate, and manage system users.

### Dashboard & Analytics
- **KPIs & Trends**: High-level metrics for sales, costs, and daily goal tracking.
- **AI Insights**: Automated, data-driven observations on sales patterns and branch performance.

### Inventory & Shrinkage Management
- **Automated Deduction**: Expected stock dynamically depletes based on imported sales and product recipes.
- **Stock Monitoring**: Threshold alerts for "Low Stock" and "Out of Stock" ingredients.
- **Variance & Shrinkage**: Record stock discrepancies (spoilage, wastage) with an owner-approval workflow.
- **History Tracking**: Comprehensive audit logs for all stock movements.

### Sales & COGS 
- **Excel Import**: Batch import daily sales via `.xlsx` or `.csv`.
- **Automated Computations**: Instantly calculates total revenue, Cost of Goods Sold (COGS), and Gross Profit.
- **Cost Analysis**: Granular breakdown of daily cost trends and expenses per product/category.

### Forecasting & Reports
- **Predictive Analytics**: Forecasts upcoming revenue, top-selling products, and inventory demand based on historical data.
- **Custom Reports**: Generate and export date-filtered operational summaries to PDF.

### Product Management
- **Recipe Management**: Link products to specific ingredients for accurate inventory tracking.
- **Product CRUD**: Create, update, and toggle active statuses for cafe offerings.

---

## Firestore Collections

| Collection | Description |
|---|---|
| **`users`** | Account credentials, roles, and branch assignments. |
| **`branches`** | Details of all café branches. |
| **`inventory`** | Current stock levels, thresholds, and statuses for ingredients. |
| **`inventory_history`** | Audit logs recording all stock adjustments. |
| **`products`** | Product details, pricing, categories, and linked recipes. |
| **`sales`** | Imported daily sales records, total revenue, and COGS. |
| **`shrinkage`** | Recorded inventory discrepancies pending review and approval. |
| **`forecast`** | Historical forecast snapshots and predictive data. |
| **`reports`** | Cached report metrics and historical summaries. |
| **`notifications`** | System alerts for low stock, imports, and approvals. |

---

## Project Structure

```text
libro_espresso/
├── assets/          # Static assets (images, fonts, Excel templates)
├── lib/
│   ├── models/      # Data models for Firestore documents
│   ├── providers/   # State management (ChangeNotifiers)
│   ├── screens/     # UI Views (Dashboard, Inventory, Reports, etc.)
│   ├── services/    # Business logic and Firestore interactions
│   └── widgets/     # Reusable UI components
└── pubspec.yaml     # Flutter dependencies
```

---

## Installation & Build

### Requirements
- **Flutter SDK**: `^3.19.0`
- **Dart SDK**: `^3.3.0`

### Setup
1. Clone the repository to your local machine.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

### Building the APK
To generate a production-ready Android package (APK), run:
```bash
flutter build apk --release
```
**Output Location:** `build/app/outputs/flutter-apk/app-release.apk`

---

## Authors

**Developed by:**  
**Jannine Isidro**  
**Anne Camille Delmo** 
**Jhon Mark Reyes** 
*Bachelor of Science in Computer Science*  
*Batangas State University*

---

## License

This project was developed for academic purposes as a Capstone Project.
