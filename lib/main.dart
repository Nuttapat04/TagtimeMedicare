import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:tagtime_medicare/screens/Caregiver_screen.dart';
import 'package:tagtime_medicare/screens/admin_page.dart';
import 'package:tagtime_medicare/screens/assign_page.dart';
import 'package:tagtime_medicare/screens/customer_support_page.dart';
import 'package:tagtime_medicare/screens/edit_information_page.dart';
import 'package:tagtime_medicare/screens/forgetpassword_screen.dart';
import 'package:tagtime_medicare/screens/login_page.dart';
import 'package:tagtime_medicare/screens/notification_service.dart';
import 'package:tagtime_medicare/screens/profile_page.dart';
import 'package:tagtime_medicare/screens/register_page.dart';
import 'package:tagtime_medicare/screens/splash_screen.dart';
import 'package:tagtime_medicare/screens/term_con.dart';
import 'package:tagtime_medicare/screens/welcome.dart';
import 'package:timezone/data/latest.dart' as tz;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(() async {
    try {
      // Initialize Firebase with retry mechanism
      var retryCount = 0;
      bool firebaseInitialized = false;

      while (!firebaseInitialized && retryCount < 3) {
        try {
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp();
            // เพิ่มส่วนนี้
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED
        );
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
      await NotificationService().initialize();

      FlutterError.onError = (FlutterErrorDetails details) {
        print('Flutter Error: ${details.exception}');
        print('Stack trace: ${details.stack}');
      };

      runApp(const MyApp());
    } catch (e, stack) {
      print('❌ Initialization Error: $e');
      print('Stack trace: $stack');

      runApp(MaterialApp(
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
                    'Application initialization error. Please try again.\n\nError: $e',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    main();
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ));
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
        return GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Tagtime Medicare',

            // Add localization support
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              MonthYearPickerLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('th', 'TH'), // เพิ่มภาษาไทย
            ],
            locale: const Locale('th', 'TH'), // ตั้งค่าภาษาเริ่มต้นเป็นไทย

            builder: (context, child) {
              return StreamBuilder<ConnectivityResult>(
                stream: Connectivity().onConnectivityChanged,
                builder: (context, snapshot) {
                  return Stack(
                    children: [
                      MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(textScaleFactor: 1.0),
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
                                  vertical: 8.h, horizontal: 8.w),
                              child: Text(
                                'Offline Mode - Please check your connection',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14.sp),
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
              fontFamily: 'SukhumvitSet',
              textTheme: Theme.of(context).textTheme.apply(
                    fontFamily: 'SukhumvitSet',
                  ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  textStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SukhumvitSet', // เพิ่มตรงนี้
                  ),
                ),
              ),
              tabBarTheme: TabBarTheme(
                labelStyle: TextStyle(
                  fontFamily: 'SukhumvitSet', // เพิ่มตรงนี้
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontFamily: 'SukhumvitSet', // เพิ่มตรงนี้
                  fontSize: 14.sp,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),

            home: const AuthWrapper(),
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
              '/term': (context) => TermsAndConditionsPage(),
            },
          ),
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
                        'Error loading user data',
                        style: TextStyle(color: Colors.red),
                      ),
                      if (connectivitySnapshot.data == ConnectivityResult.none)
                        const Text(
                          'Please check your internet connection',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AuthWrapper()),
                          );
                        },
                        child: const Text('Try Again'),
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
