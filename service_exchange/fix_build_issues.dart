// Run this script with: dart fix_build_issues.dart

import 'dart:io';

void main() async {
  // Fix home_screen.dart issues
  print('Fixing home_screen.dart issues...');
  var homeScreenFile = File('lib/screens/home_screen.dart');
  var content = await homeScreenFile.readAsString();

  // Add _buildServicesMapScreen method if not exists
  if (!content.contains('_buildServicesMapScreen() {')) {
    content = content.replaceFirst('}  // End of _HomeScreenState', '''
  Widget _buildServicesMapScreen() {
    return Center(
      child: Text('Map Screen Coming Soon'),
    );
  }
}  // End of _HomeScreenState''');
  }

  // Fix ElevatedButton.icon issue by replacing the button with proper parameters
  var buttonRegex = RegExp(r'child: Text\(isQuest \? .+\),');
  if (buttonRegex.hasMatch(content)) {
    content = content.replaceAll(buttonRegex,
        'icon: const Icon(Icons.visibility),\n          label: Text(isQuest ? \'Join Quest\' : \'View Details\'),');
  }

  await homeScreenFile.writeAsString(content);
  print('Fixed home_screen.dart issues.');

  // Fix build.gradle.kts
  print('Fixing build.gradle.kts issues...');
  var buildGradleFile = File('android/app/build.gradle.kts');
  var gradleContent = await buildGradleFile.readAsString();

  // Set NDK version
  gradleContent = gradleContent.replaceAll(
      'ndkVersion = "27.0.12077973"', 'ndkVersion = flutter.ndkVersion');

  await buildGradleFile.writeAsString(gradleContent);
  print('Fixed build.gradle.kts issues.');

  print('All fixes applied. Run "flutter clean && flutter run" to test.');
}
