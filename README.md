
Project Summary
This is a product management app. It uses Flutter for the app and Node.js for the server.

App Features (Flutter)
Add, Edit, Delete Products: You can create, read, update, and delete products.

No Unnecessary Updates: The app checks if you actually changed anything before saving an edit. If not, it tells you "Nothing changed".

Product List: Shows products in a list. You can pull to refresh and scroll to the bottom to load more.

Search and Sort: You can search for products. You can also sort the list by price or stock.

Filter: You can filter products by a price range or stock range. You can use a slider or type the min/max numbers.

Export: You can save the product list as a CSV or PDF file.

Other App Features:

Shows loading cards while products are loading.

Shows a notification at the top when you create, edit, or delete a product.

A 'Scroll to Top' button appears when you scroll down.

State Management: Uses the provider package.

Server Features (Node.js)
API: An Express.js server that handles requests from the app.

Database: Uses MongoDB and Mongoose to store product data.

API Filtering: The API can handle requests for searching, sorting, and filtering by price/stock.

Error Handling: Has a central place to manage server errors.

Tools Used
App: Flutter, Dart, provider, http, syncfusion_flutter_pdf, csv

Server: Node.js, Express.js, MongoDB, Mongoose, dotenv

How to Run
Server (backend_v2):

Run npm install.

Create a .env file and add your DATABASE_URL for MongoDB.

Run npm start.

App (flutter_product):

Run flutter pub get.

Open lib/services/api_service.dart and change the baseUrl to point to your server (example: http://10.0.2.2:3000/api for Android).

Run flutter run.