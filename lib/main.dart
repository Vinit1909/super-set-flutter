import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/common/translator.dart';
import '../common/app_bar.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:myapp/login/login.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Translator.setCurrentLanguage(await Translator.getCurrentLanguage());
  final prefs = await SharedPreferences.getInstance();
  final userToken = prefs.getString('userToken');

  runApp(MyApp(userLoggedIn: userToken != null));
}

class MyApp extends StatelessWidget {
  final bool userLoggedIn;
  const MyApp({super.key, required this.userLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Set',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(Colors.white),
            backgroundColor: MaterialStateProperty.all(Colors.deepPurple),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(Colors.deepPurple),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(Colors.deepPurple),
            side: MaterialStateProperty.all(
                BorderSide(color: Colors.deepPurple, width: 2)),
          ),
        ),
      ),
      home: userLoggedIn ? const SuperSetHomePage() : const LoginPage(),
    );
  }
}

class SuperSetHomePage extends StatefulWidget {
  const SuperSetHomePage({super.key});

  @override
  State<SuperSetHomePage> createState() => _SuperSetHomePageState();
}

class _SuperSetHomePageState extends State<SuperSetHomePage> {
  String? username;
  bool _isUsernameFormSubmitted = false;
  final TextEditingController _usernameController = TextEditingController();
  int? _age;
  String? _selectedLearningLanguageCode;
  Map<String, String> _languageMap = {};

  final List<int> _ages =
      List<int>.generate(16, (i) => i + 3); // Generates ages from 3 to 18

  @override
  void initState() {
    super.initState();
    _loadUsername();
    loadLanguages();
  }

  void loadLanguages() async {
    final jsonString =
        await rootBundle.loadString('assets/language_options.json');
    final jsonResponse = jsonDecode(jsonString) as Map<String, dynamic>;
    List<dynamic> languages = jsonResponse['languages'];

    setState(() {
      _languageMap = {for (var lang in languages) lang['code']: lang['name']};
    });
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('user_name') ?? '';
    if (savedUsername != '') {
      setState(() {
        username = savedUsername;
      });
    }
  }

  Future<void> _setUsername(String newUsername) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newUsername);
    setState(() {
      username = newUsername;
    });
  }

  Future<void> completeProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final storedLanguage = prefs.getString('selectedLanguage');
    final userToken = prefs.getString('userToken');
    var url = Uri.parse('http://localhost:4000/api/set-user-profile');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': '$userToken'
    };
    var body = jsonEncode({
      'language_preference': storedLanguage,
      'learning_language': _selectedLearningLanguageCode,
      'user_name': username,
      'user_age': _age
    });
    try {
      var response = await http.post(url, headers: headers, body: body);
      print(response.statusCode);

      if (response.statusCode == 201) {
        String responseBody = response.body;
        var decodedResponse = json.decode(responseBody);
        print(decodedResponse['user_name']);
        _setUsername(decodedResponse['user_name']);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SuperSetHomePage()),
        );
      } else {
        print('Failed to login');
        // Handle error or display message
      }
    } catch (e) {
      print('Error connecting to the server: $e');
      // Handle exception by showing user-friendly error message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SuperSetAppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Super Set'),
          ],
        ),
      ),
      body: Center(
        child: username == null
            ? _buildUsernameForm()
            : (_isUsernameFormSubmitted ? _buildDetailsForm() : _buildHomePage()),
      ),
    );
  }

  Widget _buildUsernameForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 300,
            child: TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Enter your username',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                username = _usernameController.text;
                _isUsernameFormSubmitted = true;
              });
            },
            child: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsForm() {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
            child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Welcome, $username!', style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int>(
                    value: _age,
                    decoration: InputDecoration(
                      labelText: Translator.translate('select_age'),
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                    onChanged: (int? newValue) {
                      setState(() {
                        _age = newValue!;
                      });
                    },
                    items: _ages.map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedLearningLanguageCode,
                    decoration: InputDecoration(
                      labelText:
                          Translator.translate('select_learning_language'),
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                    onChanged: (String? newValue) async {
                      if (newValue != null) {
                        setState(() {
                          _selectedLearningLanguageCode = newValue;
                        });
                      }
                    },
                    items: _languageMap.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  completeProfile();
                },
                child: Text(Translator.translate('complete_profile')),
              ),
            ],
          ),
        )));
  }

  Widget _buildHomePage() {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
            child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Welcome, $username!', style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
            ],
          ),
        )));
  }
}
