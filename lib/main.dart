import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superset/common/translator.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:superset/login/login.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Translator.setCurrentLanguage(await Translator.getCurrentLanguage());
  final prefs = await SharedPreferences.getInstance();
  final userToken = prefs.getString('userToken');

  runApp(SuperSet(userLoggedIn: userToken != null));
}

class SuperSet extends StatelessWidget {
  final bool userLoggedIn;
  const SuperSet({super.key, required this.userLoggedIn});

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
            foregroundColor: WidgetStateProperty.all(Colors.white),
            backgroundColor: WidgetStateProperty.all(Colors.deepPurple),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(Colors.deepPurple),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(Colors.deepPurple),
            side: WidgetStateProperty.all(
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
  List<dynamic> _catalog = [];

  final List<int> _ages =
      List<int>.generate(16, (i) => i + 3); // Generates ages from 3 to 18

  @override
  void initState() {
    super.initState();
    _loadUsername();
    loadLanguages();
    fetchCatalog();
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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> completeProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final storedLanguage = prefs.getString('selectedLanguage');
    final userToken = prefs.getString('userToken');
    var url = Uri.parse('http://10.0.0.46:4000/api/set-user-profile');
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

  Future<void> fetchCatalog() async {
    var url = Uri.parse('http://10.0.0.46:4000/api/all-game-profiles');
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _catalog = json.decode(response.body);
        });
      } else {
        print('Failed to fetch catalog');
      }
    } catch (e) {
      print('Error fetching catalog: $e');
    }
  }

Future<GameProfile> fetchGameProfile(String gameName) async {
  var url = Uri.parse('http://10.0.0.46:4000/api/game?game_name=$gameName');
  try {
    var response = await http.get(url);
    if (response.statusCode == 200) {
      return GameProfile.fromJson(jsonDecode(response.body));
    } else {
      print('Failed to load game profile: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to load game profile');
    }
  } catch (e) {
    print('Error fetching game profile: $e');
    throw Exception('Failed to load game profile');
  }
}

  void showGameProfileModal(BuildContext context, GameProfile gameProfile) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 0.6, // 60% of the screen height
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameProfile.displayName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(gameProfile.description),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: gameProfile.gameTags.map((tag) {
                    return Chip(label: Text(tag));
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Chip(label: Text('Age Rating: ${gameProfile.ageRating}')),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Set'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Text('Logout'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (username != null)
              Text('Welcome, $username!',
                  style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            Expanded(
              child: _buildCatalogGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
      ),
      itemCount: _catalog.length,
      itemBuilder: (BuildContext context, int index) {
        final item = _catalog[index];
        return GestureDetector(
          onTap: () async {
            GameProfile gameProfile =
                await fetchGameProfile(item['game_name']);
            showGameProfileModal(context, gameProfile);
          },
          child: Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  item['iconUrl'],
                  height: 50,
                  width: 50,
                  errorBuilder: (BuildContext context, Object exception,
                      StackTrace? stackTrace) {
                    return const Icon(Icons.error);
                  },
                ),
                const SizedBox(height: 10),
                Text(item['display_name'],
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
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
              Text('Welcome, $username!',
                  style: const TextStyle(fontSize: 24)),
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
}

class GameProfile {
  final String displayName;
  final String description;
  final List<String> gameTags;
  final int ageRating;

  GameProfile({
    required this.displayName,
    required this.description,
    required this.gameTags,
    required this.ageRating,
  });

  factory GameProfile.fromJson(Map<String, dynamic> json) {
    return GameProfile(
      displayName: json['display_name'],
      description: json['description'],
      gameTags: List<String>.from(json['game_tags']),
      ageRating: json['age_rating'],
    );
  }
}
