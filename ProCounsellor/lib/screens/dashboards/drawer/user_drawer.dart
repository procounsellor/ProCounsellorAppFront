import 'dart:typed_data';
import 'package:ProCounsellor/screens/dashboards/userDashboard/Friends/friends_page.dart';
import 'package:ProCounsellor/screens/dashboards/userDashboard/subscribed_counsellors_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/api_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import '../../../optimizations/api_cache.dart';

class UserDrawer extends StatefulWidget {
  final String fullName;
  final String? photoUrl;
  final bool isLoadingPhoto;
  final VoidCallback onLogout;
  final void Function(int index) navigateToPage;
  final String username;
  final Future<void> Function() onSignOut;
  final void Function(String fullName, String? photoUrl) onProfileUpdated;

  const UserDrawer({
    Key? key,
    required this.fullName,
    required this.photoUrl,
    required this.isLoadingPhoto,
    required this.onLogout,
    required this.navigateToPage,
    required this.username,
    required this.onSignOut,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<UserDrawer> createState() => _UserDrawerState();
}

class _UserDrawerState extends State<UserDrawer> {
  String? _photoUrl;
  String _fullName = "";
  @override
  void initState() {
    super.initState();
    _fullName = widget.fullName;
    _photoUrl = widget.photoUrl;
  }

  Future<void> _updateProfile(Map<String, dynamic> updatedData) async {
    final url = '${ApiUtils.baseUrl}/api/user/${widget.username}';

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedData),
      );

      if (response.statusCode == 200) {
        final fetchResponse = await http.get(Uri.parse(url));

        if (fetchResponse.statusCode == 200) {
          final newData = json.decode(fetchResponse.body);

          if (mounted) {
            widget.onProfileUpdated(
                '${newData['firstName'] ?? ''} ${newData['lastName'] ?? ''}'
                    .trim(),
                newData['photo']);
          }

          await ApiCache.set("user_${widget.username}", newData, persist: true);

          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully!')),
          );

          print(
              "✅ Profile updated from API, cache refreshed, and UI updated instantly.");
        } else {
          throw Exception('Failed to fetch updated profile data.');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  void _showEditProfileModal() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    Uint8List? imageBytes;
    String? fileName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Complete Your Profile",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          final bytes = await picked.readAsBytes();
                          setModalState(() {
                            imageBytes = bytes;
                            fileName = picked.name;
                          });
                        }
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: imageBytes != null
                            ? MemoryImage(imageBytes!)
                            : null,
                        child: imageBytes == null
                            ? Icon(Icons.camera_alt, size: 30)
                            : null,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: firstNameController,
                      decoration: InputDecoration(
                        labelText: "First Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: lastNameController,
                      decoration: InputDecoration(
                        labelText: "Last Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[400],
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () async {
                        final updatedData = {
                          'firstName': firstNameController.text.trim(),
                          'lastName': lastNameController.text.trim(),
                        };

                        await _updateProfile(updatedData);

                        if (imageBytes != null && fileName != null) {
                          await _uploadPhoto(
                              imageBytes!, fileName!, widget.username);
                        }
                      },
                      child: Text("Update",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
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

  Future<void> _uploadPhoto(
      Uint8List imageBytes, String fileName, String username) async {
    final url = '${ApiUtils.baseUrl}/api/user/$username/photo';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          imageBytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo uploaded successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading photo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.55,
      child: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            _buildHeader(),
            if (_fullName.trim().isEmpty || _photoUrl == null)
              _buildCompleteProfileButton(),
            Expanded(child: _buildNavigationList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFFF0BB78),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      width: double.infinity,
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            backgroundImage:
                _photoUrl != null ? NetworkImage(_photoUrl!) : null,
            child: widget.isLoadingPhoto || _photoUrl == null
                ? Text(
                    _fullName.isNotEmpty
                        ? _fullName.substring(0, 1).toUpperCase()
                        : "U",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF0BB78),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _fullName,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteProfileButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ElevatedButton(
        onPressed: _showEditProfileModal,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Complete Your Profile'),
      ),
    );
  }

  Widget _buildNavigationList() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildListTile(Icons.home, 'Home', () => widget.navigateToPage(0)),
        // _buildListTileWithImage('assets/images/icons/home_icon.png', 'Home',
        //     () => widget.navigateToPage(0)),

        _divider(),
        _buildListTile(
            Icons.lightbulb, 'Learn with Us', () => widget.navigateToPage(1)),
        _divider(),
        _buildListTile(
            Icons.groups, 'Community', () => widget.navigateToPage(2)),
        _divider(),
        _buildListTile(Icons.group_outlined, 'My Counsellors', () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubscribedCounsellorsPage(
                username: widget.username,
                onSignOut: widget.onSignOut,
              ),
            ),
          );
        }),
        _divider(),
        _buildListTile(Icons.group_outlined, 'My Friends', () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FriendsPage(
                username: widget.username,
                onSignOut: widget.onSignOut,
              ),
            ),
          );
        }),
        _divider(),
        _buildListTile(Icons.account_balance_wallet_outlined, 'Wallet', () {}),
        _divider(),
        _buildListTile(Icons.person, 'Profile', () => widget.navigateToPage(4)),
        _divider(),
        _buildListTile(Icons.info_outline, 'About Us', () {}),
        _divider(),
        _buildListTile(Icons.logout, 'Logout', widget.onLogout,
            iconColor: Colors.red),
      ],
    );
  }

  Widget _buildListTileWithImage(
      String imagePath, String title, VoidCallback onTap) {
    return ListTile(
      leading: Image.asset(
        imagePath,
        width: 24,
        height: 24,
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
      horizontalTitleGap: 10,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap,
      {Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey[700]),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
      horizontalTitleGap: 10,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      thickness: 0.5,
      indent: 16,
      endIndent: 16,
    );
  }
}
