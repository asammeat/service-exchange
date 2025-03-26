import 'package:flutter/material.dart';
import '../../screens/user_profile_screen.dart';

class UserAvatar extends StatelessWidget {
  final String imageUrl;
  final String username;
  final double size;
  final bool showBorder;
  final VoidCallback? onTap;

  const UserAvatar({
    Key? key,
    required this.imageUrl,
    required this.username,
    this.size = 40,
    this.showBorder = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(
                  username: username,
                ),
              ),
            );
          },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: showBorder
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: ClipOval(
          child: Image.network(
            imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  size: size * 0.6,
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
