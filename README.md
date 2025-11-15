                                                        Project Summary
  This is a product management app. It uses Flutter for the app , Express.js for the server and Database uses MSSQL.

- App Features (Flutter)

* Add, Edit, Delete Products: You can create, read, update, and delete products.

* Product List: Shows products in a list. You can pull to refresh and scroll to the bottom to load more.

* Search and Sort: You can search for products. You can also sort the list by price or stock.

* Filter: You can filter products by a price range or stock range. You can use a slider or type the min/max numbers.

* Export: You can save the product list as a CSV or PDF file.

- Server Features (Express.js)

* API: An Express.js server that handles requests from the app.

* Database: Uses MSSQL to store product data.

- How to Run

* Server (backend_v2):

  Run : npm install

  Run : npm run dev

- App (flutter_product):

  Run : flutter pub get

* Open lib/services/api_service.dart and change the baseUrl to point to your server (example: http://10.0.2.2:3000/api for Android).

  Run : flutter run
