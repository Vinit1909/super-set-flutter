// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class UserProfilePage extends StatefulWidget {
//   const UserProfilePage({Key? key}) : super(key: key);

//   @override
//   _UserProfilePageState createState() => _UserProfilePageState();
// }

// class _UserProfilePageState extends State<UserProfilePage> {
//   String username = '';
//   String learningLanguage = '';
//   int age = 0;
//   String profileImageUrl = '';
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserProfile();
//   }

//   Future<void> _loadUserProfile() async {
//     final prefs = await SharedPreferences.getInstance();
//     final userToken = prefs.getString('userToken');

//     if (userToken == null) {
//       // Handle the case where the user is not logged in
//       setState(() {
//         isLoading = false;
//       });
//       return;
//     }

//     var url = Uri.parse('http://localhost:4000/api/get-user-profile');
//     var headers = {'Authorization': 'Bearer $userToken'};

//     try {
//       var response = await http.get(url, headers: headers);

//       if (response.statusCode == 200) {
//         var userProfile = json.decode(response.body);
//         setState(() {
//           username = userProfile['user_name'] ?? '';
//           learningLanguage = userProfile['learning_language'] ?? '';
//           age = userProfile['user_age'] ?? 0;
//           profileImageUrl = userProfile['profile_image_url'] ?? '';
//           isLoading = false;
//         });
//       } else {
//         print('Failed to load user profile: ${response.statusCode}');
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error loading user profile: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('User Profile'),
//       ),
//       body: Center(
//         child: isLoading
//             ? CircularProgressIndicator()
//             : SingleChildScrollView(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Card(
//                     elevation: 5,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           CircleAvatar(
//                             radius: 60,
//                             backgroundColor: Colors.grey[200],
//                             backgroundImage: profileImageUrl.isNotEmpty
//                                 ? NetworkImage(profileImageUrl)
//                                 : AssetImage('assets/default_profile.png')
//                                     as ImageProvider,
//                           ),
//                           SizedBox(height: 20),
//                           Text(
//                             username,
//                             style: TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           SizedBox(height: 10),
//                           _buildInfoRow(Icons.cake, 'Age', '$age'),
//                           SizedBox(height: 10),
//                           _buildInfoRow(
//                               Icons.language, 'Learning', learningLanguage),
//                           SizedBox(height: 20),
//                           ElevatedButton(
//                             onPressed: () {
//                               // Add functionality to edit profile
//                             },
//                             child: Text('Edit Profile'),
//                             style: ElevatedButton.styleFrom(
//                               minimumSize: Size(200, 40),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(IconData icon, String label, String value) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(icon, size: 20, color: Colors.grey[600]),
//         SizedBox(width: 8),
//         Text(
//           '$label: ',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.grey[600],
//           ),
//         ),
//         Text(
//           value,
//           style: TextStyle(fontSize: 16),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String username = '';
  String learningLanguage = '';
  int age = 0;
  String profileImageUrl = '';
  int gamesPlayed = 0;
  Map<String, int> gameScores = {};
  List<Map<String, dynamic>> leaderboard = [];
  bool isLoading = true;

  late TextEditingController _usernameController;
  late TextEditingController _ageController;
  late TextEditingController _learningLanguageController;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _usernameController = TextEditingController();
    _ageController = TextEditingController();
    _learningLanguageController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    _learningLanguageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userToken = prefs.getString('userToken');

    if (userToken == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    var url = Uri.parse('http://localhost:4000/api/get-user-profile');
    var headers = {'Authorization': 'Bearer $userToken'};

    try {
      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        var userProfile = json.decode(response.body);
        setState(() {
          username = userProfile['user_name'] ?? '';
          learningLanguage = userProfile['learning_language'] ?? '';
          age = userProfile['user_age'] ?? 0;
          profileImageUrl = userProfile['profile_image_url'] ?? '';
          gamesPlayed = userProfile['games_played'] ?? 0;
          gameScores = Map<String, int>.from(userProfile['game_scores'] ?? {});
          leaderboard =
              List<Map<String, dynamic>>.from(userProfile['leaderboard'] ?? []);
          isLoading = false;
        });
      } else {
        print('Failed to load user profile: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userToken = prefs.getString('userToken');

    if (userToken == null) {
      return;
    }

    var url = Uri.parse('http://localhost:4000/api/update-user-profile');
    var headers = {
      'Authorization': 'Bearer $userToken',
      'Content-Type': 'application/json',
    };
    var body = json.encode({
      'user_name': _usernameController.text,
      'user_age': int.parse(_ageController.text),
      'learning_language': _learningLanguageController.text,
    });

    try {
      var response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        _loadUserProfile();
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile')),
      );
    }
  }

  void _showEditProfileModal() {
    _usernameController.text = username;
    _ageController.text = age.toString();
    _learningLanguageController.text = learningLanguage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: _ageController,
                  decoration: InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _learningLanguageController,
                  decoration: InputDecoration(labelText: 'Learning Language'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateProfile,
                  child: Text('Save Changes'),
                ),
              ],
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
        title: Text('User Profile'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    SizedBox(height: 20),
                    _buildBentoGrid(),
                    SizedBox(height: 20),
                    _buildLeaderboard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey[200],
          backgroundImage: profileImageUrl.isNotEmpty
              ? NetworkImage(profileImageUrl)
              : AssetImage('assets/default_profile.png') as ImageProvider,
        ),
        SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text('Age: $age'),
              Text('Learning: $learningLanguage'),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.edit),
          onPressed: _showEditProfileModal,
        ),
      ],
    );
  }

  Widget _buildBentoGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildBentoItem('Games Played', gamesPlayed.toString(), Icons.games),
        _buildBentoItem(
            'Total Score', _calculateTotalScore().toString(), Icons.score),
        _buildGameScoresCard(),
        // ... you can add more items here if needed
      ],
    );
  }

  Widget _buildGameScoresCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Game Scores',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: gameScores.length,
                itemBuilder: (context, index) {
                  String gameName = gameScores.keys.elementAt(index);
                  int score = gameScores[gameName]!;
                  int level = _calculateLevel(
                      score); // You need to implement this method
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            gameName,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text('Score: $score'),
                        Text('Level: $level'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateLevel(int score) {
    // Implement your level calculation logic here
    // This is a simple example, adjust according to your game's rules
    return (score / 100).floor() + 1;
  }

  Widget _buildBentoItem(String title, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Theme.of(context).primaryColor),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leaderboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ...leaderboard.take(5).map((user) => _buildLeaderboardItem(user)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '${user['rank']}.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 16),
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(user['profile_image_url']),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              user['username'],
              style: TextStyle(fontSize: 16),
            ),
          ),
          Text(
            user['score'].toString(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  int _calculateTotalScore() {
    return gameScores.values.fold(0, (sum, score) => sum + score);
  }
}
