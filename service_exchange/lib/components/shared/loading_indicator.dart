import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool overlay;
  final Color? color;

  const LoadingIndicator({
    Key? key,
    this.message,
    this.overlay = false,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final indicator = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(
              color: color ?? Theme.of(context).colorScheme.primary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (overlay) {
      return Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(child: indicator),
      );
    }

    return Center(child: indicator);
  }
}
