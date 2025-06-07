BizzyBuddy - Business Management App
BizzyBuddy is a Flutter-based offline-first application designed for retail shopkeepers and medium-scale businesses. It provides essential tools for inventory management, expense tracking, and sales monitoring.

Features
🏪 Business Type Support
Convenience Store mode

Medium-scale Business mode

📦 Product & Inventory Management
Add, edit, and delete products

Track stock levels with visual indicators

Categorize products

Set expiry dates

Search and filter products

💰 Sales & Expense Tracking
Record daily sales and expenses

View trends with interactive charts

Filter by date range (7 days/30 days)

Categorize expenses

📊 Dashboard
Overview of key metrics

Stock level indicators

Category distribution charts

Recent sales list

⚙️ Settings
Theme customization (Light/Dark/System)

Data export functionality

Data backup and restore

Technical Details
Architecture
MVVM pattern with Provider/Riverpod

Offline-first using Hive for local storage

Material 3 design system

Modular and scalable codebase

Dependencies
State Management: provider, flutter_riverpod

Local Storage: hive, hive_flutter

Routing: go_router

Charts: fl_chart

UI Components: flutter_slidable, google_fonts

Utils: intl, share_plus

Getting Started
Clone the repository

bash
Copy
Edit
git clone https://github.com/yourusername/bizzybuddy.git
Install dependencies

bash
Copy
Edit
flutter pub get
Run the app

bash
Copy
Edit
flutter run
Project Structure
vbnet
Copy
Edit
lib/
├── app/
│   ├── routes/
│   └── theme/
├── models/
├── viewmodels/
├── views/
│   ├── dashboard/
│   ├── products/
│   ├── expenses/
│   └── settings/
├── widgets/
└── services/
📱 Activities Screenshots
🧮 Dashboard View
<img src="https://github.com/user-attachments/assets/fac04bdc-3cae-4a08-9507-29a3da919241" alt="Dashboard" width="300"/>
📦 Product Management
<img src="https://github.com/user-attachments/assets/32803b2e-cb2a-44db-82a2-d51de2282673" alt="Products" width="300"/>
📈 Monthly Trend & Alerts
<img src="https://github.com/user-attachments/assets/2440574c-dd65-42c4-9f97-a29fe27731a6" alt="Trends" width="300"/>
Contributing
Fork the repository

Create your feature branch (git checkout -b feature/amazing-feature)

Commit your changes (git commit -m 'Add some amazing feature')

Push to the branch (git push origin feature/amazing-feature)

Open a Pull Request

License
This project is licensed under the MIT License - see the LICENSE file for details.

Let me know if you want this in a downloadable .md file or want it styled for GitHub Pages too!
