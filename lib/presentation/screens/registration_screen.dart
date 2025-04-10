import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tao_status_tracker/bloc/registration/bloc.dart';
import 'package:tao_status_tracker/bloc/registration/events.dart';
import 'package:tao_status_tracker/bloc/registration/state.dart';
import 'package:tao_status_tracker/core/utils/responsive.dart';
import 'package:tao_status_tracker/presentation/screens/otp_screen.dart';
import 'package:tao_status_tracker/presentation/widgets/text_field.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() =>
      setState(() => _isPasswordVisible = !_isPasswordVisible);
  void _toggleConfirmPasswordVisibility() =>
      setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);

  Future<void> _submitRegistration(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      try {
        // Register user using FirebaseAuth
        final FirebaseAuth auth = FirebaseAuth.instance;
        UserCredential userCredential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Send email verification
        await userCredential.user?.sendEmailVerification();

        // Navigate to OTP screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OTPScreen(email: _emailController.text.trim()),
          ),
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegistrationBloc(),
      child: BlocConsumer<RegistrationBloc, RegistrationState>(
        listener: (context, state) {
          if (state is RegistrationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Responsive(
              mobile: SingleChildScrollView(child: _buildMobileView(context)),
              tablet: _buildTabletView(),
              desktop: _buildDesktopView(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(21.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Icon(Icons.arrow_back, size: 28, color: Colors.black87),
            Center(
              child: Text(
                "Register",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDB501D),
                ),
              ),
            ),
            Center(
              child: Image.asset(
                "assets/images/Registration.png",
                height: 200,
                width: 200,
              ),
            ),
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _nameController,
                    label: "Name",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      if (value.length < 2) {
                        return 'Name must be at least 2 characters long';
                      }
                      if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
                        return 'Name can only contain letters and spaces';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 5),
                  CustomTextField(
                    controller: _emailController,
                    label: "Email",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 5),
                  CustomTextField(
                    controller: _passwordController,
                    label: "Password",
                    obscureText: !_isPasswordVisible,
                    toggleVisibility: _togglePasswordVisibility,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 5),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: "Re-enter Password",
                    obscureText: !_isConfirmPasswordVisible,
                    toggleVisibility: _toggleConfirmPasswordVisibility,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => _submitRegistration(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB501D),
                  foregroundColor: Colors.white,
                  fixedSize: const Size(160, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "Register",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildSocialLogin(context),
            const SizedBox(height: 5),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/login");
                },
                child: const Text.rich(
                  TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                    children: [
                      TextSpan(
                        text: "Log in",
                        style: TextStyle(color: Color(0xFFDB501D)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletView() => Container();
  Widget _buildDesktopView() => Container();
}

Widget _buildSocialLogin(BuildContext context) {
  return Center(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildDivider(),
        const Text(
          "Or register with",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        IconButton(
          icon: Image.asset('assets/icons/Google.png', width: 30, height: 25),
          onPressed: () {
            context.read<RegistrationBloc>().add(RegisterWithGoogle());
          },
        ),
        IconButton(
          icon: Image.asset('assets/icons/Facebook.png', width: 30, height: 25),
          onPressed: () {},
        ),
        IconButton(
          icon: Image.asset('assets/icons/Apple.png', width: 30, height: 25),
          onPressed: () {},
        ),
        _buildDivider(),
      ],
    ),
  );
}

Widget _buildDivider() => Expanded(
  child: Container(
    height: 1,
    color: Colors.black54,
    margin: const EdgeInsets.symmetric(horizontal: 10),
  ),
);
