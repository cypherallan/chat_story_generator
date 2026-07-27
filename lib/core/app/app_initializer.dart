import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';
import '../../injection_container.dart' as di;
import '../auth/auth_service.dart';
import '../auth/auth_debug.dart';

class AppInitializer {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await di.init();

    final auth = di.sl<AuthService>();

    if (!auth.isSignedIn) {
      await auth.signInAnonymously();
      AuthDebug.printCurrentUser(auth);
    }
  }
}
