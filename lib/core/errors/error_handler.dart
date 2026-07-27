import 'failures.dart';

class ErrorHandler {
  static Failure handle(dynamic error) {
    final message = error.toString();

    if (message.contains('permission-denied')) {
      return const FirebaseFailure(
        'You do not have permission to perform this action.',
      );
    }

    if (message.contains('network')) {
      return const NetworkFailure(
        'No internet connection. Please try again.',
      );
    }

    if (message.contains('object-not-found')) {
      return const FirebaseFailure(
        'Image was not found. Please select another image.',
      );
    }

    return FirebaseFailure(
      'Something went wrong. Please try again.',
    );
  }
}
