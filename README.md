# Libro Espresso – Decision Support System

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white) ![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white) ![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)

## Project Overview

**Libro Espresso** is a Decision Support System (DSS) specifically developed for a multi-branch library café. The system acts as a comprehensive command center that assists cafe owners and branch managers in monitoring day-to-day operations, tracking inventory, analyzing sales and costs, generating business forecasts, and uncovering data-driven insights to evaluate overall business performance.

---

## Technologies Used

### Frontend
- **Flutter**: Cross-platform UI toolkit for natively compiled applications.
- **Dart**: Programming language optimized for fast apps on multiple platforms.

### Backend
- **Firebase Cloud Firestore**: NoSQL document database used as the primary backend data store. It handles all data persistence for the application in real-time, providing immediate synchronization across all connected clients.

**Note on Firebase Services:**
This project specifically relies *only* on Cloud Firestore for its backend functionality. Authentication is handled natively through custom Firestore user records and session management. Consequently, the project **does not use**:
- Firebase Authentication
- Firebase Storage
- Firebase Hosting
- Firebase Cloud Messaging

---

## Features

### Authentication & Authorization
* **Owner Login**: Full administrative access across all branches.
* **Branch Manager Login**: Localized access restricted to their assigned branch data.
* **Role-Based Access**: Specialized views and capabilities strictly enforced based on the user's role.

### Dashboard & Analytics
* **KPI Cards**: High-level overview of essential business metrics.
* **Sales & Cost Trends**: Visual representations of revenue vs. expenses over time.
* **Today's Goal**: Progress tracking against daily targets.
* **AI Insights**: Automated, data-driven observations on sales patterns and branch performance.
* **Low Stock Alerts**: Immediate notifications for critical inventory items.

### Inventory Management
* **Real-time Monitoring**: Track stock levels dynamically.
* **Automatic Deduction**: Expected stock is automatically depleted upon importing daily sales.
* **Stock Counting**: Interface for manual stock auditing and physical counts.
* **Variance Computation**: Automatic calculation of discrepancies between expected and actual stock.
* **Threshold Detection**: Alerts for "Low Stock" and "Out of Stock" statuses.
* **Inventory History**: Comprehensive audit log of all stock movements and updates.

### Product Management
* **Product CRUD**: Create, Read, Update, and Delete cafe products.
* **Recipe Management**: Link products to specific ingredients to ensure accurate inventory deduction upon sale.
* **Product Status**: Easily activate or deactivate products based on availability.

### Sales Import
* **Excel Import**: Batch import daily sales via `.xlsx` or `.csv` files.
* **Automatic Computation**: Instantly calculates total sales revenue.
* **Automated COGS & Profit**: Calculates the Cost of Goods Sold (COGS) and Gross Profit immediately upon import.
* **Smart Inventory Deduction**: Automatically deducts raw ingredients from inventory based on product recipes linked to the imported sales.

### Cost of Goods Sold (COGS)
* **Daily Cost Trend**: Visualize the daily expenses tied directly to production.
* **Cost by Category**: Break down costs into distinct categories (e.g., Coffee, Pastries, Dairy).
* **Product Breakdown**: Detailed cost analysis per individual product.
* **Gross Profit**: Tracks the margin between revenue and COGS.

### Forecasting
* **Revenue Forecast**: Predictive models estimating upcoming revenue based on historical data.
* **Category Forecast**: Breakdowns of predicted performance by product category.
* **Predicted Top Sellers**: Identification of items expected to have high demand.
* **Inventory Demand Forecast**: Predicts future ingredient requirements to prevent stockouts.
* **Forecast Insights**: Textual, actionable summaries based on prediction data.

### Reports
* **Sales & Inventory Reports**: Comprehensive summaries of business operations.
* **PDF Export**: Generate formatted, downloadable PDF reports for stakeholders.
* **Date Filtering**: Custom date ranges for localized reporting.

### Shrinkage Management
* **Variance Recording**: Log discrepancies resulting from spoilage, wastage, or pilferage.
* **Approval Workflow**: Submissions by managers undergo an official review phase.
* **Owner Review**: Final sign-off mechanism for owners to validate and record shrinkage.

### Account Management
* **User CRUD**: Complete control over system users.
* **Account Status**: Ability to activate or deactivate accounts as employees onboard or offboard.

---

## Firestore Collections

The application's data is structured into the following Cloud Firestore collections:

| Collection | Description |
|---|---|
| **`users`** | Stores account credentials, roles (Owner/Manager), and branch assignments. |
| **`branches`** | Contains details of all café branches (Main, Lipa, Tagaytay, etc.). |
| **`inventory`** | Tracks current stock levels, thresholds, and statuses for raw ingredients. |
| **`inventory_history`** | An audit log recording stock adjustments, additions, and deductions. |
| **`products`** | Stores product details, pricing, categories, and linked ingredient recipes. |
| **`sales`** | Stores imported daily sales records, total revenue, and computed COGS. |
| **`shrinkage`** | Records inventory discrepancies pending review and approval. |
| **`forecast`** | Stores historical forecast snapshots and predictive analytics data. |
| **`reports`** | Caches generated report metrics and historical operational summaries. |
| **`notifications`** | Handles system alerts for low stock, new imports, and pending approvals. |

---

## Project Structure

```text
libro_espresso/
├── assets/          # Static assets (images, fonts, placeholder icons, Excel templates)
├── lib/
│   ├── models/      # Data models handling parsing to and from Firestore documents
│   ├── providers/   # State management classes (ChangeNotifiers) for global app state
│   ├── screens/     # UI Views (Login, Dashboard, Inventory, Products, Reports, etc.)
│   ├── services/    # Core business logic and direct interactions with Cloud Firestore
│   └── widgets/     # Reusable UI components (Cards, Headers, Charts, Modals)
└── pubspec.yaml     # Flutter dependencies and configurations
```

---

## Installation

### Requirements
- **Flutter SDK**: `^3.19.0` or higher (compatible with latest stable).
- **Dart SDK**: `^3.3.0` or higher.
- An IDE (VS Code, Android Studio) with the Flutter extension installed.

### Setup Instructions

1. **Clone the repository:**
   *(Ensure you have the source code available locally)*
   
2. **Install Dependencies:**
   Navigate to the project root in your terminal and run:
   ```bash
   flutter pub get
   ```

3. **Run the Application:**
   Start the application on your connected device or emulator:
   ```bash
   flutter run
   ```

---

## Building APK

To generate a production-ready Android application package (APK), run the following command in the terminal:

```bash
flutter build apk --release
```

**Output Location:**  
Once the build process completes, the APK file can be found at:  
`build/app/outputs/flutter-apk/app-release.apk`

---

## Screenshots

| Login | Dashboard |
| :---: | :---: |
| ![Login Placeholder](https://via.placeholder.com/300x600.png?text=Login+Screen) | ![Dashboard Placeholder](https://via.placeholder.com/300x600.png?text=Dashboard+Screen) |

| Inventory | Products |
| :---: | :---: |
| ![Inventory Placeholder](https://via.placeholder.com/300x600.png?text=Inventory+Screen) | ![Products Placeholder](https://via.placeholder.com/300x600.png?text=Products+Screen) |

| COGS | Forecast |
| :---: | :---: |
| ![COGS Placeholder](https://via.placeholder.com/300x600.png?text=COGS+Screen) | ![Forecast Placeholder](https://via.placeholder.com/300x600.png?text=Forecast+Screen) |

| Reports | Account Management |
| :---: | :---: |
| ![Reports Placeholder](https://via.placeholder.com/300x600.png?text=Reports+Screen) | ![Accounts Placeholder](https://via.placeholder.com/300x600.png?text=Account+Management) |

---

## Authors

**Developed by:**  
**Jannine Isidro**  
*Bachelor of Science in Computer Science*  
*Batangas State University*

---

## License

This project was developed for academic purposes as a Capstone Project. All rights reserved by the author and associated academic institution.
