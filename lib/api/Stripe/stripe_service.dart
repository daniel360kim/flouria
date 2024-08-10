import 'package:firebase_auth/firebase_auth.dart';
import 'package:flourish_web/log_printer.dart';

class StripeService {
  final logger = getLogger('Stripe Service');
  late final User? user;

  StripeService() {
    user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      logger.e('User is null while instantiating Stripe Service');
      throw Exception(); 
    }
  }
}