import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:tagtime_medicare/screens/Caregiver_screen.dart';
import 'package:tagtime_medicare/screens/admin_page.dart';
import 'package:tagtime_medicare/screens/assign_page.dart';
import 'package:tagtime_medicare/screens/customer_support_page.dart';
import 'package:tagtime_medicare/screens/edit_information_page.dart';
import 'package:tagtime_medicare/screens/home_page.dart';
import 'package:tagtime_medicare/screens/local_storage.dart';
import 'package:tagtime_medicare/screens/medicine_detail_page.dart';
import 'package:tagtime_medicare/screens/notification_service.dart';
import 'package:tagtime_medicare/screens/profile_page.dart';
import 'package:tagtime_medicare/screens/welcome.dart';
import 'package:tagtime_medicare/screens/splash_screen.dart';
import 'package:tagtime_medicare/screens/login_page.dart';
import 'package:tagtime_medicare/screens/register_page.dart';
import 'package:tagtime_medicare/screens/forgetpassword_screen.dart';
import 'package:timezone/data/latest.dart' as tz;

// ✅ ใช้ navigatorKey เพื่อควบคุม Navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    
    // ย้ายการตั้งค่า timezone ไปรวมกัน
    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    print("🌍 Device Timezone: $currentTimeZone");
    
    await NotificationService().initialize();
    runApp(const MyApp());
  } catch (e, stack) {
    print('❌ Initialization Error: $e');
    print('Stack trace: $stack');
  }
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Tagtime Medicare',
      theme: ThemeData(
        fontFamily: 'Poly',
        primaryColor: const Color(0xFF763355),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF4E0),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const InitialScreen(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/forget-password': (context) => ForgetPasswordScreen(),
        '/welcome': (context) => WelcomePage(),
        '/edit-information': (context) => EditInformationPage(),
        '/customer-support': (context) => CustomerSupportPage(),
        '/caregiver': (context) => CaregiverPage(),
        '/profile': (context) => ProfilePage(),
        '/adminpage': (context) => AdminPage(),
        '/assignpage': (context) => AssignPage(),
        '/medicine_detail': (context) {
    print('🛣️ Medicine detail route called');
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args == null) {
      print('⚠️ No arguments passed to medicine detail route');
      return const Scaffold(
        body: Center(child: Text('No medicine data available')),
      );
    }
    
    print('📋 Medicine detail arguments: $args');
    return MedicineDetailPage(
      medicineData: args['medicineData'],
      rfidUID: args['rfidUID'],
    );
  },
}
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({Key? key}) : super(key: key);

  @override 
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  late StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkStoredUser();
  }

  Future<void> _checkStoredUser() async {
    try {
      final storedUserId = await LocalStorage.getData('user_id');
      
      if (storedUserId != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print('✅ Found stored user: ${user.uid}');
          _handleAuth();
        } else {
          print('❌ No Firebase user found');
          _navigateToWelcome();
        }
      } else {
        print('❌ No stored user found');
        _navigateToWelcome();
      }
    } catch (e) {
      print('❌ Error checking stored user: $e');
      _navigateToWelcome();
    }
  }

  void _handleAuth() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (User? user) async {
        if (user != null) {
          print('✅ User logged in: ${user.uid}');
          await LocalStorage.saveData('user_id', user.uid);
          NotificationService.instance.listenToMedicationChanges(user.uid);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          }
        } else {
          print('👤 No user logged in');
          await LocalStorage.clearAll();
          if (mounted) {
            _navigateToWelcome();
          }
        }
      },
      onError: (error) {
        print('❌ Auth error: $error');
        _navigateToWelcome();
      },
    );
  }

  void _navigateToWelcome() {
    if (mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => WelcomePage()),
      );
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF4E0),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC76355)),
        ),
      ),
    );
  }
}