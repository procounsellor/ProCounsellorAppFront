import 'package:http/http.dart' as http;
import 'api_cache.dart'; // Import the cache manager
import 'dart:convert';

Future<void> fetchUserDetails(String userId) async {
  // First, check if the data is cached
  var cachedData = ApiCache.get("user_$userId");
  if (cachedData != null) {
    print("Using cached data: $cachedData");
    return;
  }

  // If not cached, fetch from API
  final response = await http.get(Uri.parse(
      "https://procounsellor-backend-1000407154647.asia-south1.run.app/api/user/$userId"));
  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    // Store response in cache for future use
    ApiCache.set("user_$userId", data);
    print("Fetched from API: $data");
  }
}
