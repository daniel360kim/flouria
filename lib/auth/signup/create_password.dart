import 'package:flourish_web/animations.dart';
import 'package:flourish_web/api/auth_service.dart';
import 'package:flourish_web/auth/login_page.dart';
import 'package:flourish_web/auth/signup/signup_page.dart';
import 'package:flourish_web/auth/widgets/error_message.dart';
import 'package:flourish_web/auth/widgets/textfield.dart';
import 'package:flourish_web/colors.dart';
import 'package:flourish_web/studyroom/study_page.dart';
import 'package:flutter/material.dart';

class CreatePasswordPage extends StatefulWidget {
  const CreatePasswordPage({required this.username, super.key});

  final String username;

  @override
  State<CreatePasswordPage> createState() => _CreatePasswordPageState();
}

class _CreatePasswordPageState extends State<CreatePasswordPage> {
  final TextEditingController _passwordController = TextEditingController();

  bool _leastCharactersRequirement = false;
  bool _containsLetterRequirement = false;
  bool _passwordVisible = false;

  final bool _error = false;
  final String _errorMessage = '';

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: kFlourishBlackish,
        body: Center(
          child: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: 350,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildHeading(),
                    const SizedBox(height: 30),
                    buildTextFields(),
                    const SizedBox(height: 20),
                    passwordRequirements(),
                    const SizedBox(height: 20),
                    _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: kFlourishAdobe,
                            ),
                          )
                        : ElevatedButton(
                            onPressed: next,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kFlourishAdobe,
                              minimumSize: const Size(350, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Next',
                              style: TextStyle(
                                color: kFlourishBlackish,
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    const SizedBox(height: 40),
                    Container(
                      height: 0.5,
                      width: 550,
                      color: kFlourishAliceBlue.withOpacity(0.7),
                    ),
                    const SizedBox(height: 40),
                    buildBackToLoginWidgets(),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Widget buildHeading() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () {
            Navigator.of(context).push(noTransition(const SignupPage()));
          },
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: kFlourishAliceBlue),
        ),
        const SizedBox(width: 50),
        Center(
          child: Container(
            height: 60,
            width: 60,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/brand/logo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Flourish',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kFlourishAliceBlue,
            fontSize: 24,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildTextFields() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              const Text(
                'Create a password',
                style: TextStyle(
                  color: kFlourishAliceBlue,
                  fontSize: 17,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: kFlourishAliceBlue,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 13),
        LoginTextField(
          controller: _passwordController,
          onChanged: (_) {
            updateRequirements();
          },
          hintText: '',
          keyboardType: TextInputType.visiblePassword,
          valid: !_error,
          obscureText: !_passwordVisible,
        ),
        _error
            ? ErrorMessage(
                message: _errorMessage,
              )
            : const SizedBox(height: 20),
      ],
    );
  }

  Widget buildBackToLoginWidgets() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account?',
          style: TextStyle(
            color: kFlourishAliceBlue,
            fontSize: 15,
            fontFamily: 'Inter',
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(noTransition(const LoginPage()));
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.all(0),
          ),
          child: const Text(
            'Log in',
            style: TextStyle(
              color: kFlourishAliceBlue,
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: kFlourishAliceBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget passwordRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password must contain:',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: kFlourishAliceBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        PasswordChecklistItem(
          text: '8 characters',
          isChecked: _leastCharactersRequirement,
          error: _error,
        ),
        const SizedBox(height: 5),
        PasswordChecklistItem(
          text: '1 letter',
          isChecked: _containsLetterRequirement,
          error: _error,
        ),
      ],
    );
  }

  void updateRequirements() {
    final passwordValidator = PasswordValidator(_passwordController.text);
    setState(() {
      _leastCharactersRequirement = passwordValidator.isLengthRequirementMet();
      _containsLetterRequirement = passwordValidator.isLetterRequirementMet();
    });
  }

  void next() async {
    setState(() {
      _loading = true;
    });
    AuthService().signUp(
      widget.username,
      _passwordController.text,
    );
    setState(() {
      _loading = false;
    });
    Navigator.of(context).push(noTransition(const StudyRoom()));
  }
}

class PasswordChecklistItem extends StatefulWidget {
  const PasswordChecklistItem({
    required this.text,
    required this.isChecked,
    required this.error,
    super.key,
  });

  final String text;
  final bool isChecked;
  final bool error;

  @override
  State<PasswordChecklistItem> createState() => _PasswordChecklistItemState();
}

class _PasswordChecklistItemState extends State<PasswordChecklistItem> {
  @override
  Widget build(BuildContext context) {
    late final Color color;
    if (widget.isChecked) {
      color = const Color.fromRGBO(102, 255, 0, 1.0);
    } else {
      if (widget.error) {
        color = Colors.red;
      } else {
        color = kFlourishAliceBlue;
      }
    }
    return Row(
      children: [
        Icon(
          widget.isChecked ? Icons.check_circle : Icons.circle_outlined,
          color: color,
          size: 15,
        ),
        const SizedBox(width: 5),
        Text(
          widget.text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}