import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';
import '../../injection_container.dart' as di;

class AppInitializer {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await di.init();
  }
}
