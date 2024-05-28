import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superset/common/translator.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:superset/login/login.dart';
import 'package:http/http.dart' as http;
import 'package:device_apps/device_apps.dart';
import 'package:url_launcher/url_launcher.dart';

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
  List<dynamic> _catalog = [];
  String _currentForm = 'usernameForm';

  final List<int> _ages = List<int>.generate(16, (i) => i + 3); // Generates ages from 3 to 18

  @override
  void initState() {
    super.initState();
    _loadUsername();
    loadLanguages();
    fetchCatalog();
  }

  void loadLanguages() async {
    final jsonString = await rootBundle.loadString('assets/language_options.json');
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
        _currentForm = 'catalogGrid';  // Load catalog grid if username is already set
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
    await prefs.remove('user_name');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> completeProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final storedLanguage = prefs.getString('selectedLanguage');
    final userToken = prefs.getString('userToken');
    var url = Uri.parse('http://137.184.225.229:4000/api/set-user-profile');
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
        await _setUsername(decodedResponse['user_name']);
        setState(() {
          _currentForm = 'catalogGrid';
        });
      } else {
        print('Failed to update profile');
        // Handle error or display message
      }
    } catch (e) {
      print('Error connecting to the server: $e');
      // Handle exception by showing user-friendly error message
    }
  }

  Future<void> fetchCatalog() async {
    var url = Uri.parse('http://137.184.225.229:4000/api/all-game-profiles');
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
    var url = Uri.parse('http://137.184.225.229:4000/api/game?game_name=$gameName');
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

  Uint8List _decodeBase64(String base64String) {
    // Remove the data URL prefix if it exists
    final prefix = "data:image/png;base64,";
    if (base64String.startsWith(prefix)) {
      base64String = base64String.substring(prefix.length);
    }
    return base64Decode(base64String);
  }

  Image _loadImageFromBase64(String base64String) {
    Uint8List imageBytes = _decodeBase64(base64String);
    return Image.memory(imageBytes, fit: BoxFit.cover);
  }

  void showGameProfileModal(BuildContext context, GameProfile gameProfile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.6, // 60% of the screen height
          child: FutureBuilder<bool>(
            future: DeviceApps.isAppInstalled(gameProfile.packageId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                bool isInstalled = snapshot.data ?? false;
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gameProfile.displayName,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
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
                      const SizedBox(height: 20),
                      if (isInstalled)
                        ElevatedButton(
                          onPressed: () {
                            DeviceApps.openApp(gameProfile.packageId);
                          },
                          child: Text('Play Now'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: () async {
                            final url =
                                'https://play.google.com/store/apps/details?id=${gameProfile.packageId}';
                            if (await canLaunch(url)) {
                              await launch(url);
                            } else {
                              throw 'Could not launch $url';
                            }
                          },
                          child: Text('Download Now'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                          ),
                        ),
                    ],
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
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
        child: Center(
          child: _buildCurrentForm(),
        ),
      ),
    );
  }

  Widget _buildCurrentForm() {
    switch (_currentForm) {
      case 'usernameForm':
        return _buildUsernameForm();
      case 'detailsForm':
        return _buildDetailsForm();
      case 'catalogGrid':
        return _buildCatalogGrid();
      default:
        return _buildCatalogGrid();
    }
  }

  Widget _buildCatalogGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight =
            constraints.maxHeight * 0.25; // 25% of the screen height
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: constraints.maxWidth / (3 * cardHeight),
          ),
          itemCount: _catalog.length,
          itemBuilder: (BuildContext context, int index) {
            final item = _catalog[index];
            return GestureDetector(
              onTap: () async {
                showLoadingDialog(context);
                GameProfile gameProfile =
                    await fetchGameProfile(item['game_name']);
                hideLoadingDialog(context);
                showGameProfileModal(context, gameProfile);
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _loadImageFromBase64(item['iconUrl']),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item['display_name'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUsernameForm() {
    return Column(
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
              _currentForm = 'detailsForm';
            });
          },
          child: const Icon(Icons.arrow_forward),
        ),
      ],
    );
  }

  Widget _buildDetailsForm() {
    return SingleChildScrollView(
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
                    labelText: Translator.translate('select_learning_language'),
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
      ),
    );
  }
}

class GameProfile {
  final String displayName;
  final String description;
  final List<String> gameTags;
  final int ageRating;
  final String packageId;

  GameProfile(
      {required this.displayName,
      required this.description,
      required this.gameTags,
      required this.ageRating,
      required this.packageId});

  factory GameProfile.fromJson(Map<String, dynamic> json) {
    return GameProfile(
      displayName: json['display_name'],
      description: json['description'],
      gameTags: List<String>.from(json['game_tags']),
      ageRating: json['age_rating'],
      packageId: json['package_id'],
    );
  }
}
