import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user_profile.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserProfile userProfile;

  const ProfileEditScreen({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _fullNameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.userProfile.username);
    _fullNameController =
        TextEditingController(text: widget.userProfile.fullName ?? '');
    _bioController = TextEditingController(text: widget.userProfile.bio ?? '');
    _phoneController =
        TextEditingController(text: widget.userProfile.phoneNumber ?? '');
    _locationController =
        TextEditingController(text: widget.userProfile.location ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update profile fields
      widget.userProfile.username = _usernameController.text;
      widget.userProfile.fullName =
          _fullNameController.text.isEmpty ? null : _fullNameController.text;
      widget.userProfile.bio =
          _bioController.text.isEmpty ? null : _bioController.text;
      widget.userProfile.phoneNumber =
          _phoneController.text.isEmpty ? null : _phoneController.text;
      widget.userProfile.location =
          _locationController.text.isEmpty ? null : _locationController.text;

      // First upload the avatar if selected
      if (_selectedImage != null) {
        await widget.userProfile.updateAvatar(_selectedImage!);
      }

      // Then update the profile
      await widget.userProfile.updateProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(
            context, true); // Return true to indicate successful update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile picture
            Center(
              child: GestureDetector(
                onTap: _selectImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!) as ImageProvider
                          : widget.userProfile.avatarUrl != null
                              ? NetworkImage(widget.userProfile.avatarUrl!)
                              : null,
                      child: widget.userProfile.avatarUrl == null &&
                              _selectedImage == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form fields
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter your username',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell us about yourself',
                prefixIcon: Icon(Icons.edit),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Enter your location',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            // Account type section
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Service Provider Account'),
                      subtitle: const Text(
                        'Enable this to offer services and create quests',
                      ),
                      value: widget.userProfile.isPartnerAccount,
                      onChanged: (value) {
                        setState(() {
                          widget.userProfile.isPartnerAccount = value;
                        });
                      },
                      activeColor: Colors.deepPurple,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Coins info
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.monetization_on,
                        color: Colors.amber[700], size: 30),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Coin Balance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.userProfile.coins} coins',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.amber[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Show coin purchase dialog
                        _showCoinPurchaseDialog();
                      },
                      child: const Text('Get More'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showCoinPurchaseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Purchase Coins'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.monetization_on, color: Colors.amber[700]),
                title: const Text('100 Coins'),
                subtitle: const Text('\$1.99'),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _simulateCoinPurchase(100);
                  },
                  child: const Text('Buy'),
                ),
              ),
              ListTile(
                leading: Icon(Icons.monetization_on, color: Colors.amber[700]),
                title: const Text('500 Coins'),
                subtitle: const Text('\$8.99'),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _simulateCoinPurchase(500);
                  },
                  child: const Text('Buy'),
                ),
              ),
              ListTile(
                leading: Icon(Icons.monetization_on, color: Colors.amber[700]),
                title: const Text('1000 Coins'),
                subtitle: const Text('\$15.99'),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _simulateCoinPurchase(1000);
                  },
                  child: const Text('Buy'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // For demo purposes - simulate coin purchase
  Future<void> _simulateCoinPurchase(int amount) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, this would go through a payment processor
      await widget.userProfile.updateCoins(amount);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully purchased $amount coins!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error purchasing coins: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
