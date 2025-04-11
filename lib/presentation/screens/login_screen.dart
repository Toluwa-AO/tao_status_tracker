import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tao_status_tracker/bloc/login/login_bloc.dart';
import 'package:tao_status_tracker/bloc/login/login_events.dart';
import 'package:tao_status_tracker/bloc/login/login_state.dart';
import 'package:tao_status_tracker/core/utils/responsive.dart';
import 'package:tao_status_tracker/presentation/screens/home_screen.dart';
import 'package:tao_status_tracker/presentation/widgets/text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _submitLogin(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<LoginBloc>().add(
        LoginSubmitted(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );
    }
  }

  Widget _buildMobileView(BuildContext context, LoginState state) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(21.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back,
                  size: 28,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDB501D),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Image.asset("assets/images/login.png", height: 250),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                label: "Password",
                obscureText: !_isPasswordVisible,
                toggleVisibility: _togglePasswordVisibility,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: () => _submitLogin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDB501D),
                    foregroundColor: Colors.white,
                    fixedSize: const Size(160, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 5,
                  ),
                  child: state is LoginLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              _buildSocialLogin(),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, "/register"),
                  child: const Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                      children: [
                        TextSpan(
                          text: "Register",
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
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDivider(),
          const Text(
            "Or login with",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          IconButton(
            icon: Image.asset('assets/icons/Google.png', width: 30, height: 25),
            onPressed: () {
              context.read<LoginBloc>().add(LoginWithGoogle());
            },
          ),
          IconButton(
            icon: Image.asset(
              'assets/icons/Facebook.png',
              width: 30,
              height: 25,
            ),
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(),
      child: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          } else if (state is LoginSuccess) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => HomeScreen(user: state.user), // Pass user
              ),
              (route) => false, // Remove all previous routes
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login successful!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Responsive(
              mobile: _buildMobileView(context, state),
              tablet: Container(),
              desktop: Container(),
            ),
          );
        },
      ),
    );
  }
}