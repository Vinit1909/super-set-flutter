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
import 'user_profile_page.dart';

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
  // bool _isUsernameFormSubmitted = false;
  final TextEditingController _usernameController = TextEditingController();
  int? _age;
  String? _selectedLearningLanguageCode;
  Map<String, String> _languageMap = {};
  List<dynamic> _catalog = [];
  String _currentForm = 'usernameForm';
  RangeValues _ageFilter = RangeValues(3, 18);
  bool _isFilterActive = false;

  final List<int> _ages =
      List<int>.generate(16, (i) => i + 3); // Generates ages from 3 to 18

  @override
  void initState() {
    super.initState();
    _checkProfileCompletion(); // New function to check profile completion status
    loadLanguages();
    fetchCatalog();
    fetchUserProfile(); // Call the profile fetch function after login
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

  Future<void> _checkProfileCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    bool? profileComplete = prefs.getBool('profileComplete');

    // If profileComplete is null, this means it's a new user (first-time signup)
    if (profileComplete == null || profileComplete == false) {
      setState(() {
        _currentForm =
            'usernameForm'; // Show username form for first-time users
      });
    } else {
      // Profile is complete, proceed to the catalog
      setState(() {
        _currentForm = 'catalogGrid';
      });
    }
  }

  Future<void> fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userToken = prefs.getString('userToken');

    if (userToken == null || userToken.isEmpty) {
      print('No user token found');
      await _loadUsername(); // Fall back to local data if no token
      return;
    }

    var url = Uri.parse('http://localhost:4000/api/get-user-profile');
    var headers = {'Authorization': 'Bearer $userToken'};

    try {
      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        var userProfile = json.decode(response.body);

        // Save all profile data to SharedPreferences
        await prefs.setString('user_name', userProfile['user_name'] ?? '');
        await prefs.setString(
            'learning_language', userProfile['learning_language'] ?? '');
        await prefs.setInt('user_age', userProfile['user_age'] ?? 0);
        await prefs.setString(
            'language_preference', userProfile['language_preference'] ?? '');

        // Mark profile as complete
        await prefs.setBool('profileComplete', true);

        setState(() {
          username = userProfile['user_name'];
          _selectedLearningLanguageCode = userProfile['learning_language'];
          _age = userProfile['user_age'];
          _currentForm =
              'catalogGrid'; // Show the catalog grid once the profile is loaded
        });
      } else if (response.statusCode == 404) {
        // Profile not found, so it's a new user signing up
        print('User profile not found, assuming first-time signup.');
        setState(() {
          _currentForm = 'usernameForm'; // Start the signup flow
        });
      } else {
        print('Failed to retrieve user profile: ${response.statusCode}');
        await _loadUsername(); // Fall back to local data if fetch fails
      }
    } catch (e) {
      print('Error retrieving user profile: $e');
      await _loadUsername(); // Fall back to local data if there's an error
    }
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('user_name') ?? '';
    final savedLearningLanguage = prefs.getString('learning_language');
    final savedAge = prefs.getInt('user_age');
    final isProfileComplete = prefs.getBool('profileComplete') ?? false;

    print(
        'Saved username: $savedUsername, Profile complete: $isProfileComplete');

    setState(() {
      username = savedUsername;
      _selectedLearningLanguageCode = savedLearningLanguage;
      _age = savedAge;

      if (isProfileComplete) {
        _currentForm = 'catalogGrid';
      } else if (savedUsername.isNotEmpty) {
        _currentForm = 'detailsForm';
      } else {
        _currentForm = 'usernameForm';
      }
    });
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
    await prefs.remove(
        'profileCompleted'); // Clear the profileCompleted flag on logout
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // Add this method to update the profile completion status
  Future<void> updateProfileCompletionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool isProfileComplete = username != null &&
        username!.isNotEmpty &&
        _selectedLearningLanguageCode != null &&
        _age != null;
    await prefs.setBool('profileComplete', isProfileComplete);
  }

  Future<void> completeProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final storedLanguage = prefs.getString('selectedLanguage');
    final userToken = prefs.getString('userToken');

    print('User Token: $userToken');

    if (userToken == null || userToken.isEmpty) {
      print('No user token found');
      return;
    }

    var url = Uri.parse('http://localhost:4000/api/set-user-profile');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $userToken'
    };
    var body = jsonEncode({
      'language_preference': storedLanguage,
      'learning_language': _selectedLearningLanguageCode,
      'user_name': username,
      'user_age': _age
    });

    try {
      var response = await http.post(url, headers: headers, body: body);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        var decodedResponse = json.decode(response.body);

        // Safely extract values with null-checks
        String newUsername = decodedResponse['user_name'] ?? '';
        String? learningLanguage = decodedResponse['learning_language'] ?? null;
        int? userAge = decodedResponse['user_age'] != null
            ? decodedResponse['user_age'] as int
            : null;

        if (newUsername.isNotEmpty) {
          // Update local storage and state with the response data
          await _setUsername(newUsername);
        }

        if (learningLanguage != null) {
          await prefs.setString('learning_language', learningLanguage);
        }

        if (userAge != null) {
          await prefs.setInt('user_age', userAge);
        }

        // Update profile completion status
        await updateProfileCompletionStatus();

        setState(() {
          _currentForm = 'catalogGrid';
        });
      } else {
        print(
            'Failed to update profile: ${response.statusCode} ${response.body}');
        // You might want to show an error message to the user here
      }
    } catch (e) {
      print('Error connecting to the server: $e');
      // You might want to show an error message to the user here
    }
  }

  Future<void> fetchCatalog() async {
    var url = Uri.parse('http://localhost:4000/api/all-game-profiles');
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
    var url = Uri.parse('http://localhost:4000/api/game?game_name=$gameName');
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
                return SingleChildScrollView(
                  child: Padding(
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
                        Chip(
                            label:
                                Text('Age Rating: ${gameProfile.ageRating}')),
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

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('Super Set'),
  //       actions: [
  //         PopupMenuButton<String>(
  //           onSelected: (value) {
  //             if (value == 'logout') {
  //               _logout();
  //             }
  //           },
  //           itemBuilder: (BuildContext context) {
  //             return [
  //               const PopupMenuItem<String>(
  //                 value: 'logout',
  //                 child: Text('Logout'),
  //               ),
  //             ];
  //           },
  //         ),
  //       ],
  //     ),
  //     body: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Center(
  //         child: _buildCurrentForm(),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Set'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserProfilePage()),
              );
            },
          ),
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
