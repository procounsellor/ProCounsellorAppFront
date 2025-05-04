import 'package:ProCounsellor/main.dart';
import 'package:ProCounsellor/screens/dashboards/userDashboard/components/deadlines/AllDeadlinesPage.dart';
import 'package:ProCounsellor/screens/dashboards/userDashboard/details_page.dart';
import 'package:ProCounsellor/screens/paymentScreens/withdraw_funds.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:ProCounsellor/screens/paymentScreens/add_funds.dart';
import '../../../optimizations/api_cache.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/api_utils.dart';
import 'package:shimmer/shimmer.dart';
import '../../paymentScreens/add_bank_details.dart';
import '../../paymentScreens/transaction_history.dart';
import '../userDashboard/my_reviews.dart';
import 'package:ProCounsellor/screens/signInScreens/user_signin_page.dart';
import 'TargetedCollegePage.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final Future<void> Function() onSignOut;

  ProfilePage({required this.username, required this.onSignOut});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  Uint8List? _profileImageBytes;
  List<dynamic> subscribedCounsellors = [];

  final ImagePicker _picker = ImagePicker();

  final List<String> allowedStates = [
    "KARNATAKA",
    "MAHARASHTRA",
    "TAMILNADU",
    "OTHERS"
  ];

  final List<String> courses = [
    "HSC",
    "ENGINEERING",
    "MEDICAL",
    "MBA",
    "OTHERS"
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    _fetchSubscribedCounsellors();
  }
  // wallet

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Add a post-frame callback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWalletBalanceOnly();
    });
  }

  Future<void> _fetchWalletBalanceOnly() async {
    final url = '${ApiUtils.baseUrl}/api/user/${widget.username}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            profileData?['walletAmount'] = data['walletAmount'];
          });
        }
      } else {
        print('❌ Failed to fetch wallet balance');
      }
    } catch (e) {
      print('❌ Error fetching wallet balance: $e');
    }
  }

  //logout function
  Widget _buildLogoutTile() {
    return InkWell(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Confirm Logout", style: GoogleFonts.outfit()),
            content: Text("Are you sure you want to log out?",
                style: GoogleFonts.outfit()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel", style: GoogleFonts.outfit()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Logout",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (confirm == true) {
          //await widget.onSignOut(); // Call the passed sign-out function
          await restartApp();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "LOGOUT",
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black, // Black instead of grey
              ),
            ),
            Icon(Icons.logout, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchSubscribedCounsellors() async {
    final url =
        '${ApiUtils.baseUrl}/api/user/${widget.username}/subscribed-counsellors';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is List) {
          // ✅ Assign only if it's a valid list
          setState(() {
            subscribedCounsellors = decoded;
          });
        } else {
          // ⚠️ Fallback to empty list if the structure is unexpected
          setState(() {
            subscribedCounsellors = [];
          });
          print("⚠️ Unexpected data format, using empty list.");
        }

        print("✅ Subscribed counsellors fetched successfully.");
      } else {
        print(
            "❌ Failed to load subscribed counsellors: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        subscribedCounsellors = []; // ✅ prevent crashes on error
      });
      print("❌ Error fetching subscribed counsellors: $e");
    }
  }

  Future<void> _fetchProfileData() async {
    final cacheKey = "user_${widget.username}";
    final url = '${ApiUtils.baseUrl}/api/user/${widget.username}';

    // Step 1: Check if data is available in cache
    var cachedData = ApiCache.get(cacheKey);
    if (cachedData != null) {
      setState(() {
        profileData = cachedData;
        isLoading = false;
      });
      print("✅ Loaded profile data from cache");
      return;
    }

    try {
      // Step 2: Fetch from API if cache is empty
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Step 3: Store response in cache for future use
        ApiCache.set(cacheKey, data, persist: true);

        setState(() {
          profileData = data;
          isLoading = false;
        });

        print("✅ Fetched profile data from API and stored in cache");
      } else {
        throw Exception('Failed to load profile data');
      }
    } catch (error) {
      print('❌ Error fetching profile data: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        Uint8List imageBytes = await image.readAsBytes();
        setState(() {
          _profileImageBytes = imageBytes;
        });
        _uploadPhoto(imageBytes, image.name); // Upload after picking the image
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _uploadPhoto(Uint8List imageBytes, String fileName) async {
    final url =
        '${ApiUtils.baseUrl}/api/user/${widget.username}/photo'; // Ensure correct endpoint

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo', // Key for the file; ensure backend expects this key
          imageBytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'), // Adjust based on image type
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo uploaded successfully!')),
        );
        _fetchProfileData(); // Refresh profile data after successful upload
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to upload photo. Status: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading photo: $e')),
      );
    }
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
        // ✅ Step 1: Fetch fresh profile data from API instead of using cached response
        final fetchResponse = await http.get(Uri.parse(url));

        if (fetchResponse.statusCode == 200) {
          final newData = json.decode(fetchResponse.body);

          // ✅ Step 2: Update the UI with new data first
          if (mounted) {
            setState(() {
              profileData = newData;
            });
          }

          // ✅ Step 3: Update cache after UI is updated
          await ApiCache.set("user_${widget.username}", newData, persist: true);

          // ✅ Step 4: Close modal only if it's still open
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          // ✅ Step 5: Show success message
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

  Future<void> restartApp() async {
    print("🚪 Logging out...");

    try {
      // Step 1: Delete secure storage
      await storage.deleteAll();
      final remaining = await storage.readAll();
      print("🧼 Remaining after deleteAll(): $remaining");

      // Step 2: Delete FCM Token
      await FirebaseMessaging.instance.deleteToken();
      print("🔥 FCM token deleted");
    } catch (e) {
      print("⚠️ Error during logout cleanup: $e");
    }

    // Step 4: Navigate to login screen and clear backstack
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => UserSignInPage(onSignOut: restartApp),
      ),
      (route) => false,
    );
  }

  void _showUpdateModal() async {
    // ✅ Step 1: Fetch fresh data before opening the modal
    var freshData = await ApiCache.get("user_${widget.username}");
    if (freshData != null) {
      setState(() {
        profileData = freshData;
      });
    }

    // ✅ Step 2: Initialize controllers with latest data
    TextEditingController firstNameController =
        TextEditingController(text: profileData?['firstName'] ?? '');
    TextEditingController lastNameController =
        TextEditingController(text: profileData?['lastName'] ?? '');

    String? interestedCourse = profileData?['interestedCourse'];
    List<String> userInterestedStates = List<String>.from(
        profileData?['userInterestedStateOfCounsellors'] ?? []);

    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: Padding(
            padding: EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Update Information',
                        style: GoogleFonts.outfit(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),

                      // First Name Field
                      TextField(
                        controller: firstNameController,
                        decoration: InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Last Name Field
                      TextField(
                        controller: lastNameController,
                        decoration: InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Degree Selection Dropdown
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        value: interestedCourse,
                        items: courses.map((course) {
                          return DropdownMenuItem(
                              value: course, child: Text(course));
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: 'Degree I am looking for',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            interestedCourse = value;
                          });
                        },
                      ),
                      SizedBox(height: 16),

                      // Location Selection Title
                      Text(
                        'Location I am looking for',
                        style: GoogleFonts.outfit(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),

                      // Location Checkboxes
                      Column(
                        children: allowedStates.map((state) {
                          return CheckboxListTile(
                            title: Text(state),
                            value: userInterestedStates.contains(state),
                            onChanged: (value) {
                              setModalState(() {
                                if (value == true) {
                                  userInterestedStates.add(state);
                                } else {
                                  userInterestedStates.remove(state);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),

                      // Update Button
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            // ✅ Prepare updated data
                            Map<String, dynamic> updatedData = {
                              'firstName': firstNameController.text.trim(),
                              'lastName': lastNameController.text.trim(),
                              'interestedCourse': interestedCourse,
                              'userInterestedStateOfCounsellors':
                                  userInterestedStates,
                            };

                            // ✅ Step 1: Update profile
                            _updateProfile(updatedData);
                          },
                          child: Text(
                            'Update',
                            style: GoogleFonts.outfit(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildListItem(String title, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      value = "Not provided";
    }

    if (value is List) {
      value = value.isNotEmpty ? value.join(", ") : "None";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style:
                GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTile({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : profileData == null
              ? Center(child: Text("Failed to load profile data"))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // User Info Section
                      Center(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  Container(
                                    width: MediaQuery.of(context).size.width *
                                        0.35,
                                    height: MediaQuery.of(context).size.width *
                                        0.35,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: _profileImageBytes != null
                                        ? Image.memory(_profileImageBytes!,
                                            fit: BoxFit.cover)
                                        : (profileData != null &&
                                                profileData!['photo'] != null
                                            ? Image.network(
                                                profileData!['photo'],
                                                fit: BoxFit.cover)
                                            : Icon(Icons.person,
                                                size: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.2,
                                                color: Colors.white)),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black,
                                      radius: 12,
                                      child: Icon(Icons.edit,
                                          size: 12, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name
                                  if (profileData != null &&
                                      (profileData!['firstName'] != null ||
                                          profileData!['lastName'] != null))
                                    Row(
                                      children: [
                                        if (profileData!['firstName'] != null)
                                          Text(
                                            profileData!['firstName'],
                                            style: GoogleFonts.outfit(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        if (profileData!['lastName'] != null)
                                          SizedBox(width: 6),
                                        if (profileData!['lastName'] != null)
                                          Text(
                                            profileData!['lastName'],
                                            style: GoogleFonts.outfit(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold),
                                          ),
                                      ],
                                    ),
                                  SizedBox(height: 12),

                                  // Wallet Balance
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "WALLET BALANCE",
                                        style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[600]),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.currency_rupee,
                                              color: Colors.green, size: 16),
                                          SizedBox(width: 2),
                                          Text(
                                            profileData != null &&
                                                    profileData![
                                                            'walletAmount'] !=
                                                        null
                                                ? profileData!['walletAmount']
                                                    .toString()
                                                : "Not provided",
                                            style: GoogleFonts.outfit(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddFundsPage(
                                              userName: widget.username),
                                        ),
                                      );

                                      if (result == true) {
                                        _fetchWalletBalanceOnly(); // 👈 Refresh just the wallet balance
                                      }
                                    },
                                    child: Text(
                                      "Add Funds",
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "INTERESTED COUNSELLORS",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          subscribedCounsellors.isEmpty && isLoading
                              ? SizedBox(
                                  height: 90,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    itemCount:
                                        5, // Number of shimmer placeholders
                                    separatorBuilder: (_, __) =>
                                        SizedBox(width: 16),
                                    itemBuilder: (context, index) {
                                      return Shimmer.fromColors(
                                        baseColor: Colors.grey.shade300,
                                        highlightColor: Colors.grey.shade100,
                                        child: SizedBox(
                                          width: 70,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundColor:
                                                    Colors.grey.shade400,
                                              ),
                                              SizedBox(height: 6),
                                              Container(
                                                height: 10,
                                                width: 50,
                                                color: Colors.grey.shade400,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : subscribedCounsellors.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Text(
                                        "No counsellors subscribed yet.",
                                        style: GoogleFonts.outfit(
                                            color: Colors.grey),
                                      ),
                                    )
                                  : SizedBox(
                                      height: 90,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: SizedBox(
                                          height: 90,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            child: ListView.separated(
                                              scrollDirection: Axis.horizontal,
                                              itemCount:
                                                  subscribedCounsellors.length,
                                              separatorBuilder: (_, __) =>
                                                  SizedBox(width: 16),
                                              itemBuilder: (context, index) {
                                                final counsellor =
                                                    subscribedCounsellors[
                                                        index];
                                                final counsellorId =
                                                    counsellor['userName'] ??
                                                        '';
                                                final firstName =
                                                    counsellor['firstName'] ??
                                                        '';
                                                final lastName =
                                                    counsellor['lastName'] ??
                                                        '';
                                                final counsellorName =
                                                    (firstName + " " + lastName)
                                                            .trim()
                                                            .isEmpty
                                                        ? 'Counsellor'
                                                        : '$firstName $lastName';

                                                return GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            DetailsPage(
                                                          itemName:
                                                              counsellorName,
                                                          userId:
                                                              widget.username,
                                                          counsellorId:
                                                              counsellorId,
                                                          onSignOut:
                                                              () async {}, // replace with real callback if needed
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: SizedBox(
                                                    width: 70,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        CircleAvatar(
                                                          backgroundImage: (counsellor[
                                                                          'photoUrl'] !=
                                                                      null &&
                                                                  counsellor[
                                                                          'photoUrl']
                                                                      .toString()
                                                                      .isNotEmpty)
                                                              ? NetworkImage(
                                                                  counsellor[
                                                                      'photoUrl'])
                                                              : null,
                                                          radius: 24,
                                                        ),
                                                        SizedBox(height: 6),
                                                        Text(
                                                          counsellorName,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: GoogleFonts
                                                              .outfit(
                                                                  fontSize: 12),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "COURSE I AM LOOKING FOR",
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              profileData != null &&
                                      profileData!['interestedCourse'] != null
                                  ? profileData!['interestedCourse']
                                  : "Not provided",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "LOCATION I AM LOOKING FOR",
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              profileData != null &&
                                      profileData![
                                              'userInterestedStateOfCounsellors'] !=
                                          null &&
                                      profileData![
                                              'userInterestedStateOfCounsellors']
                                          .isNotEmpty
                                  ? profileData![
                                          'userInterestedStateOfCounsellors']
                                      .join(", ")
                                  : "Not provided",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      _buildSectionTile(
                        title: "MY BANK DETAILS",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddBankDetailsPage(username: widget.username),
                            ),
                          );
                        },
                      ),

                      Divider(height: 1),

                      _buildSectionTile(
                        title: "WITHDRAW FUNDS",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  WithdrawFundsPage(userName: widget.username),
                            ),
                          );
                        },
                      ),

                      Divider(height: 1),

                      _buildSectionTile(
                        title: "MY TRANSACTIONS",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransactionHistoryPage(
                                  username: widget.username),
                            ),
                          );
                        },
                      ),

                      Divider(height: 1),

                      _buildSectionTile(
                        title: "MY REVIEWS",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MyReviewPage(username: widget.username),
                            ),
                          );
                        },
                      ),

                      Divider(height: 1),

                      _buildSectionTile(
                        title: "TARGETED COLLEGES",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TargetedCollegePage(userId: widget.username),
                            ),
                          );
                        },
                      ),

                      Divider(height: 1),

                      _buildSectionTile(
                        title: "DEADLINES",
                        onTap: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (_) =>
                          //         AllDeadlinesPage(username: widget.username),
                          //   ),
                          // );
                        },
                      ),
                      // Divider(height: 1),
                      // _buildLogoutTile(),

                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors
                                .orange[300], // Green background for the button
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8), // Rounded edges
                            ),
                          ),
                          onPressed: _showUpdateModal, // Edit functionality
                          child: Text(
                            "Edit Profile",
                            style: GoogleFonts.outfit(
                              color: Colors.white, // White text color
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),

                      // Logout Button
                      Center(
                        child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: Icon(Icons.logout, color: Colors.white),
                            label: Text(
                              "Logout",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            // onPressed: () async {
                            //   final confirm = await showDialog<bool>(
                            //     context: context,
                            //     builder: (context) => AlertDialog(
                            //       title: Text("Confirm Logout",
                            //           style: GoogleFonts.outfit()),
                            //       content: Text(
                            //           "Are you sure you want to log out?",
                            //           style: GoogleFonts.outfit()),
                            //       actions: [
                            //         TextButton(
                            //           onPressed: () =>
                            //               Navigator.pop(context, false),
                            //           child: Text("Cancel",
                            //               style: GoogleFonts.outfit()),
                            //         ),
                            //         TextButton(
                            //           onPressed: () =>
                            //               Navigator.pop(context, true),
                            //           child: Text("Logout",
                            //               style: GoogleFonts.outfit(
                            //                   fontWeight: FontWeight.bold)),
                            //         ),
                            //       ],
                            //     ),
                            //   );

                            //   if (confirm == true) {
                            //     await restartApp(); // Your logout logic
                            //   }
                            // },
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  titlePadding: EdgeInsets.only(top: 24),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  actionsPadding:
                                      EdgeInsets.only(right: 16, bottom: 12),
                                  title: Column(
                                    children: [
                                      Icon(Icons.logout,
                                          color: Colors.redAccent, size: 36),
                                      SizedBox(height: 12),
                                      Text(
                                        "Confirm Logout",
                                        style: GoogleFonts.outfit(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    "Are you sure you want to log out?",
                                    style: GoogleFonts.outfit(fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  actionsAlignment: MainAxisAlignment.end,
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(
                                        "Cancel",
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                      ),
                                      child: Text(
                                        "Logout",
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await restartApp(); // Your logout logic
                              }
                            }),
                      ),
                    ],
                  ),
                ),
    );
  }
}
