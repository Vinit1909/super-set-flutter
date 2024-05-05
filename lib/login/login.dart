import 'package:flutter/material.dart';
import 'package:myapp/main.dart'; // Assuming your MyHomePage is accessible from here.
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  bool _showLoginForm = false;
  String? _selectedLanguage;
  List<String> _languages = [];

  @override
  void initState() {
    super.initState();
    loadLanguages();
  }

  void loadLanguages() async {
    final jsonString = await rootBundle.loadString('languages.json');
    final jsonResponse = jsonDecode(jsonString) as List;
    final languageMap = jsonResponse[0] as Map<String, dynamic>;

    setState(() {
      // Explicitly cast each value to a string
      _languages =
          languageMap.entries.map((entry) => entry.value as String).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: 600), // Ideal for both mobile and desktop views.
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (!_showLoginForm) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedLanguage,
                      decoration: const InputDecoration(
                        labelText: 'Select Language',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedLanguage = newValue;
                        });
                      },
                      items: _languages
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showLoginForm = true;
                        });
                      },
                      child: const Text('Continue to Login'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                  if (_showLoginForm) ...[
                    // Email Field
                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Password Field with visibility toggle
                    TextField(
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        filled: true,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Login and Sign Up Buttons
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ElevatedButton(
                              onPressed: () {},
                              child: const Text('Login'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            child: const Text('Sign Up'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Forgot Password Button
                    TextButton(
                      onPressed: () {},
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
