import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:provider/provider.dart';

import 'providers/product_provider.dart';
import 'screens/product_list_screen.dart';
import 'config/theme.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

String _getBaseUrl() {
  if (kIsWeb) return 'http://localhost:3000/api';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://10.0.2.2:3000/api';
    case TargetPlatform.iOS:
      return 'http://localhost:3000/api';
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    default:
      return 'http://localhost:3000/api';
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) =>
              ProductProvider(apiService: ApiService(baseUrl: _getBaseUrl())),
      child: MaterialApp(
        title: 'Product Manager Pro',
        theme: AppTheme.lightTheme,
        home: ProductListScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
