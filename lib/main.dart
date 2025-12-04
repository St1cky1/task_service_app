import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'screens/login_screen.dart';
import 'screens/task_list_screen.dart';
import 'services/api_service.dart';
import 'services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ApiService _apiService;
  late SecureStorageService _storageService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _storageService = SecureStorageService();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => _apiService),
        Provider<SecureStorageService>(create: (_) => _storageService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            apiService: _apiService,
            storageService: _storageService,
          )..initializeAuth(),
        ),
        ChangeNotifierProvider(
          create: (_) => TaskProvider(apiService: _apiService),
        ),
      ],
      child: MaterialApp(
        title: 'Task Service',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isAuthenticated) {
              return const TaskListScreen();
            }
            return const LoginScreen();
          },
        ),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/tasks': (_) => const TaskListScreen(),
        },
      ),
    );
  }
}
