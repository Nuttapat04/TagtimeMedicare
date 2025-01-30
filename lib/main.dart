import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tagtime_medicare/screens/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:tagtime_medicare/screens/Caregiver_screen.dart';
import 'package:tagtime_medicare/screens/admin_page.dart';
import 'package:tagtime_medicare/screens/assign_page.dart';
import 'package:tagtime_medicare/screens/customer_support_page.dart';
import 'package:tagtime_medicare/screens/edit_information_page.dart';
import 'package:tagtime_medicare/screens/medicine_detail_page.dart';
import 'package:tagtime_medicare/screens/profile_page.dart';
import 'package:tagtime_medicare/screens/welcome.dart';
import 'package:tagtime_medicare/screens/splash_screen.dart';
import 'package:tagtime_medicare/screens/login_page.dart';
import 'package:tagtime_medicare/screens/register_page.dart';
import 'package:tagtime_medicare/screens/forgetpassword_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
 WidgetsFlutterBinding.ensureInitialized();
 
 // Configure zone for error handling
 runZonedGuarded(() async {
   try {
     // Initialize Firebase with retry mechanism  
     var retryCount = 0;
     bool firebaseInitialized = false;
     
     while (!firebaseInitialized && retryCount < 3) {
       try {
         if (Firebase.apps.isEmpty) {
           await Firebase.initializeApp();
           firebaseInitialized = true;
           print('✅ Firebase initialized successfully');
         }
       } catch (e) {
         retryCount++;
         print('❌ Firebase initialization failed (attempt $retryCount): $e');
         await Future.delayed(const Duration(seconds: 1));
       }
     }

     if (!firebaseInitialized) {
       throw Exception('Failed to initialize Firebase after 3 attempts');
     }

     // Initialize other services
     tz.initializeTimeZones();
     
     // Setup Firestore persistence
     FirebaseFirestore.instance.settings = const Settings(
       persistenceEnabled: true,
       cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
     );
     
     // Initialize notification service
     await NotificationService().initialize();
     
     // Set up error handlers
     FlutterError.onError = (FlutterErrorDetails details) {
       print('Flutter Error: ${details.exception}');
       print('Stack trace: ${details.stack}');
     };

     // Run app
     runApp(const MyApp());
     
   } catch (e, stack) {
     print('❌ Initialization Error: $e');
     print('Stack trace: $stack');
     
     // Show error screen
     runApp(
       MaterialApp(
         home: Scaffold(
           backgroundColor: const Color(0xFFFFF4E0),
           body: Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 const Icon(Icons.error_outline, size: 48, color: Colors.red),  
                 const SizedBox(height: 16),
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 32),
                   child: Text(
                     'เกิดข้อผิดพลาดในการเริ่มต้นแอปพลิเคชัน กรุณาลองใหม่อีกครั้ง\n\nError: $e',
                     textAlign: TextAlign.center,
                   ),
                 ),
                 const SizedBox(height: 16),
                 ElevatedButton(
                   onPressed: () {
                     // Restart app
                     main();
                   },
                   child: const Text('ลองใหม่'),
                 ),
               ],
             ),
           ),
         ),
       ),
     );
   }
 }, (error, stack) {
   print('❌ Uncaught error: $error'); 
   print('Stack trace: $stack');
 });
}

class MyApp extends StatelessWidget {
 const MyApp();

 @override
 Widget build(BuildContext context) {
   return ScreenUtilInit(
     designSize: const Size(360, 690),
     minTextAdapt: true,
     splitScreenMode: true,
     builder: (_, child) {
       return MaterialApp(
         navigatorKey: navigatorKey,
         debugShowCheckedModeBanner: false,
         title: 'Tagtime Medicare',
         builder: (context, child) {
           return StreamBuilder<ConnectivityResult>(
             stream: Connectivity().onConnectivityChanged,
             builder: (context, snapshot) {
               return Stack(
                 children: [
                   MediaQuery(
                     data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                     child: child!,
                   ),
                   if (snapshot.data == ConnectivityResult.none)
                     Positioned(
                       top: 0,
                       left: 0,
                       right: 0,
                       child: Material(
                         child: Container(
                           color: Colors.red,
                           padding: EdgeInsets.symmetric(
                             vertical: 8.h,
                             horizontal: 8.w,
                           ),
                           child: Text(
                             'Offline Mode - กรุณาตรวจสอบการเชื่อมต่อ',
                             textAlign: TextAlign.center,
                             style: TextStyle(
                               color: Colors.white,
                               fontSize: 14.sp,
                             ),
                           ),
                         ),
                       ),
                     ),
                 ],
               );
             },
           );
         },
         theme: ThemeData(
           fontFamily: 'Poly',
           primaryColor: const Color(0xFF763355),
           appBarTheme: AppBarTheme(
             backgroundColor: const Color(0xFFFFF4E0),
             titleTextStyle: TextStyle(
               fontSize: 20.sp,
               fontWeight: FontWeight.bold,
               color: Colors.white,
             ),
           ),
           elevatedButtonTheme: ElevatedButtonThemeData(
             style: ElevatedButton.styleFrom(
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(10.r),
               ),
             ),
           ),
         ),
         home: const AuthWrapper(),
         onGenerateRoute: (settings) {
           if (settings.name == '/medicine_detail') {
             final args = settings.arguments as Map<String, dynamic>?;

             if (args != null && args.containsKey('rfidUID')) {
               return MaterialPageRoute(
                 builder: (context) => MedicineDetailPage(
                   medicineData: args['medicineData'] ?? {},
                   rfidUID: args['rfidUID'],
                 ),
               );
             } else {
               print('❌ Missing arguments for /medicine_detail');
             }
           }

           return MaterialPageRoute(
             builder: (context) => WelcomePage(),
           );
         },
         routes: {
           '/login': (context) => LoginPage(),
           '/register': (context) => RegisterPage(),
           '/forget-password': (context) => ForgetPasswordScreen(),
           '/splash': (context) => SplashScreen(),
           '/welcome': (context) => WelcomePage(),
           '/edit-information': (context) => EditInformationPage(),
           '/customer-support': (context) => CustomerSupportPage(),
           '/caregiver': (context) => CaregiverPage(),
           '/profile': (context) => ProfilePage(),
           '/adminpage': (context) => AdminPage(),
           '/assignpage': (context) => AssignPage(),
         },
       );
     },
   );
 }
}

class AuthWrapper extends StatelessWidget {
 const AuthWrapper();

 @override
 Widget build(BuildContext context) {
   return StreamBuilder<ConnectivityResult>(
     stream: Connectivity().onConnectivityChanged,
     builder: (context, connectivitySnapshot) {
       return StreamBuilder<User?>(
         stream: FirebaseAuth.instance.authStateChanges(),
         builder: (context, snapshot) {
           if (snapshot.connectionState == ConnectionState.waiting) {
             return const Scaffold(
               backgroundColor: Color(0xFFFFF4E0),
               body: Center(child: CircularProgressIndicator()),
             );
           }

           if (snapshot.hasError) {
             print('Firebase Auth Error: ${snapshot.error}');
             return Scaffold(
               backgroundColor: const Color(0xFFFFF4E0),
               body: Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Text(
                       'เกิดข้อผิดพลาดในการโหลดข้อมูลผู้ใช้',
                       style: TextStyle(color: Colors.red),
                     ),
                     if (connectivitySnapshot.data == ConnectivityResult.none)
                       const Text(
                         'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
                         style: TextStyle(color: Colors.orange),
                       ),
                     ElevatedButton(
                       onPressed: () {
                         Navigator.pushReplacement(
                           context,
                           MaterialPageRoute(
                             builder: (context) => const AuthWrapper()
                           ),
                         );
                       },
                       child: const Text('ลองใหม่'),
                     ),
                   ],
                 ),
               ),
             );
           }

           if (snapshot.hasData) {
             try {
               final userId = snapshot.data!.uid;
               NotificationService().listenToMedicationChanges(userId);
               return SplashScreen();
             } catch (e) {
               print('Error in AuthWrapper: $e');
               return WelcomePage();
             }
           }
           
           return WelcomePage();
         },
       );
     },
   );
 }
}