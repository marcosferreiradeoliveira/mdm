import 'package:admin/pages/home.dart';
import 'package:admin/pages/sign_in.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'blocs/admin_bloc.dart';
import 'blocs/comment_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';

Future<void> initializeFirebase() async {
  try {
    // Load .env file only for non-web platforms
    if (!kIsWeb) {
      await dotenv.load(fileName: "assets/.env");
    }

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
    rethrow;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeFirebase();
    runApp(const MyApp());
  } catch (e) {
    print('Failed to initialize app: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Error initializing app: $e',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AdminBloc>(create: (context) => AdminBloc()),
        ChangeNotifierProvider<CommentBloc>(create: (context) => CommentBloc()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        scrollBehavior: TouchAndMouseScrollBehavior(),
        theme: ThemeData(
          useMaterial3: false,
          scaffoldBackgroundColor: Colors.white,
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: AppBarTheme(
            color: Colors.white,
            titleTextStyle: GoogleFonts.poppins(
              color: Colors.grey[900],
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
            elevation: 0,
            actionsIconTheme: IconThemeData(
              color: Colors.grey[900],
            ),
            iconTheme: IconThemeData(color: Colors.grey[900]),
          ),
        ),
        home: const MyApp1(),
      ),
    );
  }
}

class MyApp1 extends StatelessWidget {
  const MyApp1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ab = context.watch<AdminBloc>();
    return ab.isSignedIn == false ? SignInPage() : HomePage();
  }
}

class TouchAndMouseScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
