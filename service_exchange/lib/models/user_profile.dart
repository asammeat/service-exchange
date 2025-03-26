import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class UserProfile {
  final String id;
  final String? email;
  String username;
  String? fullName;
  String? bio;
  String? avatarUrl;
  String? phoneNumber;
  String? location;
  int coins;
  bool isPartnerAccount;
  DateTime? createdAt;
  DateTime? updatedAt;

  UserProfile({
    required this.id,
    this.email,
    required this.username,
    this.fullName,
    this.bio,
    this.avatarUrl,
    this.phoneNumber,
    this.location,
    this.coins = 0,
    this.isPartnerAccount = false,
    this.createdAt,
    this.updatedAt,
  });

  // Create UserProfile from Supabase data
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      username: json['username'] ?? 'user_${json['id'].substring(0, 8)}',
      fullName: json['full_name'],
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
      phoneNumber: json['phone_number'],
      location: json['location'],
      coins: json['coins'] ?? 0,
      isPartnerAccount: json['is_partner_account'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // Convert UserProfile to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'phone_number': phoneNumber,
      'location': location,
      'coins': coins,
      'is_partner_account': isPartnerAccount,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Fetch user profile from Supabase
  static Future<UserProfile?> fetchProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        return null;
      }

      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (response != null) {
        return UserProfile.fromJson(response);
      }

      // If no profile exists, create a default one
      return await createDefaultProfile(user);
    } catch (e) {
      print('Error fetching profile: $e');

      // If error is a PostgreSQL not found error, create a default profile
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        return await createDefaultProfile(user);
      }

      return null;
    }
  }

  // Create a default profile for a new user
  static Future<UserProfile> createDefaultProfile(User user) async {
    final newProfile = UserProfile(
      id: user.id,
      email: user.email,
      username: 'user_${user.id.substring(0, 8)}',
      coins: 100, // Start with 100 coins
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await Supabase.instance.client.from('profiles').upsert(newProfile.toJson());

    return newProfile;
  }

  // Update user profile in Supabase
  Future<void> updateProfile() async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update(toJson())
          .eq('id', id);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Update avatar URL in Supabase
  Future<void> updateAvatar(File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '$id.$fileExt';

      final storageResponse = await Supabase.instance.client.storage
          .from('avatars')
          .upload(fileName, imageFile,
              fileOptions:
                  const FileOptions(cacheControl: '3600', upsert: true));

      final String publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      avatarUrl = publicUrl;
      await updateProfile();
    } catch (e) {
      print('Error uploading avatar: $e');
      rethrow;
    }
  }

  // Helper method to update coins
  Future<void> updateCoins(int amount) async {
    coins += amount;
    await updateProfile();
  }
}
