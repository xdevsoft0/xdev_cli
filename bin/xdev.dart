import 'dart:io';

import 'package:path/path.dart' as p;

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: xdev <command> [arguments]');
    exit(0);
  }

  final command = args[0];
  switch (command) {
    case 'create':
      await _handleCreate(args.skip(1).toList());
      break;
    case 'fix': // New: Handle the fix command
      await _handleFix();
      break;
    default:
      print('Unknown command: $command');
  }
}

Future<void> _handleCreate(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: xdev create [project|view|service] <name>');
    return;
  }

  final type = args[0];
  final name = args.length > 1 ? args[1] : null;

  if (type == 'project' && name != null) {
    await _createFlutterProject(name);
  } else if (type == 'view' && name != null) {
    await _createView(name);
  } else if (type == 'service' && name != null) {
    await _createService(name);
  } else {
    print('❌ Invalid usage.');
  }
}

// New: Handle the fix command to scan views and update routing
Future<void> _handleFix() async {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('❌ Run inside a Flutter project root.');
    exit(1);
  }

  final viewsDir = Directory(p.join(libDir.path, 'views'));
  if (!viewsDir.existsSync()) {
    print('❌ No views directory found.');
    return;
  }

  // Scan for view folders (e.g., login_view)
  final viewEntities = await viewsDir.list().toList();
  final viewNames = <String>[];
  for (final entity in viewEntities) {
    if (entity is Directory && p.basename(entity.path).endsWith('_view')) {
      final folderName = p.basename(entity.path);
      final name = folderName.replaceAll('_view', '');
      viewNames.add(name);
    }
  }

  if (viewNames.isEmpty) {
    print('ℹ️ No views found to fix.');
    return;
  }

  bool changesMade = false;

  // Fix route_name.dart: Add missing route constants
  final routeNameFile = File(p.join(libDir.path, 'routes', 'route_name.dart'));
  if (routeNameFile.existsSync()) {
    String content = await routeNameFile.readAsString();
    for (final name in viewNames) {
      final newRoute = "  static const String $name = '/$name';\n";
      if (!content.contains(newRoute)) {
        content = content.replaceFirst(
          '// Add more routes here',
          '$newRoute    // Add more routes here',
        );
        changesMade = true;
      }
    }
    if (changesMade) {
      await routeNameFile.writeAsString(content);
    }
  } else {
    print('⚠️ route_name.dart not found. Skipping.');
  }

  // Reset changes flag for next file
  changesMade = false;

  // Fix routing.dart: Add missing imports and cases
  final routingFile = File(p.join(libDir.path, 'routes', 'routing.dart'));
  if (routingFile.existsSync()) {
    String content = await routingFile.readAsString();
    final missingImports = <String>[];
    final missingCases = <String>[];
    for (final name in viewNames) {
      final viewFolderName = '${name}_view';
      final importLine =
          "import '../views/$viewFolderName/${name}_screen.dart';\n";
      if (!content.contains(importLine)) {
        missingImports.add(importLine);
      }

      final className = _capitalize(name);
      final caseLine =
          "      case RouteName.$name:\n        return MaterialPageRoute(builder: (_) => const ${className}Screen());\n";
      if (!content.contains('case RouteName.$name:')) {
        missingCases.add(caseLine);
      }
    }

    if (missingImports.isNotEmpty) {
      final newImports = missingImports.join('');
      content = content.replaceFirst(
        "import 'route_name.dart';",
        "import 'route_name.dart';\n$newImports",
      );
      changesMade = true;
    }

    if (missingCases.isNotEmpty) {
      final newCases = missingCases.join('');
      content = content.replaceFirst('default:', '$newCases      default:');
      changesMade = true;
    }

    if (changesMade) {
      await routingFile.writeAsString(content);
    }
  } else {
    print('⚠️ routing.dart not found. Skipping.');
  }

  // Run pub get if any changes were made
  if (changesMade) {
    print('🛠 Applying fixes...');
    final result = await Process.run('flutter', [
      'pub',
      'get',
    ], runInShell: true);
    if (result.exitCode != 0) {
      print('⚠️ flutter pub get failed: ${result.stderr}');
    }
  }

  print('✅ Project fixed! Added/updated ${viewNames.length} views in routing.');
}

/// --- PROJECT CREATION ---
Future<void> _createFlutterProject(String name) async {
  final org = 'com.xdev';
  print('🚀 Creating Flutter project "$name"...');

  // Create the Flutter project
  final result = await Process.run('flutter', [
    'create',
    name,
    '--org',
    org,
  ], runInShell: true);

  if (result.exitCode != 0) {
    print(result.stderr);
    return;
  }

  final lib = p.join(name, 'lib');

  // Create folder structure
  final folders = [
    'views',
    'models',
    'providers',
    'routes',
    'core/services',
    'core/constants',
    'core/extensions',
    'core/utils',
    'core/widgets',
  ];

  for (final folder in folders) {
    Directory(p.join(lib, folder)).createSync(recursive: true);
  }

  // Create assets folders
  Directory(p.join(name, 'assets/images')).createSync(recursive: true);
  Directory(p.join(name, 'assets/icons')).createSync(recursive: true);

  // --- Correct pubspec.yaml ---
  final pubspecFile = File(p.join(name, 'pubspec.yaml'));
  pubspecFile.writeAsStringSync('''
name: $name
description: "A new Flutter project."
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.9.2

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.5+1
  flutter_screenutil: ^5.9.3
  google_fonts: ^6.3.2
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/icons/
''');

  // --- main.dart ---
  _write(lib, 'main.dart', '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'routes/route_name.dart';
import 'routes/routing.dart';
import 'package:$name/views/splash_view/splash_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => SplashProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp(
        title: '$name',
        debugShowCheckedModeBanner: false,
        initialRoute: RouteName.splash,
        onGenerateRoute: Routing.generateRoute,
      ),
    );
  }
}
''');

  // --- ROUTES ---
  _write(lib, 'routes/route_name.dart', '''
class RouteName {
  static const String splash = '/';
  // Add more routes here
}
''');

  _write(lib, 'routes/routing.dart', '''
import 'package:flutter/material.dart';
import 'package:$name/views/splash_view/splash_screen.dart';
import 'route_name.dart';

class Routing {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteName.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route found for \${settings.name}')),
          ),
        );
    }
  }
}
''');

  // Custom TextField
  _write(lib, 'core/widgets/custom_textfield.dart', '''
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final Color? fillColor;
  final Color? textColor;
  final Color? hintColor;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final Function(String)? onChanged;

  const CustomTextField({
    super.key,
    required this.controller,
    this.hint = '',
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.fillColor,
    this.textColor,
    this.hintColor,
    this.borderRadius = 12,
    this.contentPadding,
    this.textStyle,
    this.hintStyle,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      style: textStyle ?? TextStyle(color: textColor ?? Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: hintStyle ?? TextStyle(color: hintColor ?? Colors.grey),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null
            ? GestureDetector(
                onTap: onSuffixTap,
                child: Icon(suffixIcon),
              )
            : null,
        filled: true,
        fillColor: fillColor ?? Colors.grey[200],
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}

''');

  // Custom button
  _write(lib, 'core/widgets/custom_button.dart', '''
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final double height;
  final double? width;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final bool enableShadow;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final double iconSpacing;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 8,
    this.height = 50,
    this.width,
    this.borderColor,
    this.borderWidth = 1,
    this.padding,
    this.textStyle,
    this.enableShadow = true,
    this.prefixIcon,
    this.suffixIcon,
    this.iconSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      height: height,
      minWidth: width ?? double.infinity,
      color: backgroundColor ?? Theme.of(context).primaryColor,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(
          color: borderColor ?? Colors.transparent,
          width: borderWidth,
        ),
      ),
      elevation: enableShadow ? 2 : 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (prefixIcon != null) ...[
            Icon(prefixIcon, color: textColor ?? Colors.white),
            SizedBox(width: iconSpacing),
          ],
          Text(
            text,
            style: textStyle ??
                TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (suffixIcon != null) ...[
            SizedBox(width: iconSpacing),
            Icon(suffixIcon, color: textColor ?? Colors.white),
          ],
        ],
      ),
    );
  }
}


''');
  // Custom Text
  _write(
    lib,
    'core/widgets/custom_text.dart',
    '''import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String text;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;
  final bool softWrap;
  final TextDecoration? decoration;
  final Color? decorationColor;
  final double? decorationThickness;
  final List<Shadow>? shadows;

  const CustomText(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.style,
    this.softWrap = true,
    this.decoration,
    this.decorationColor,
    this.decorationThickness,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      style: style ??
          TextStyle(
            color: color ?? Colors.black,
            fontSize: fontSize ?? 16,
            fontWeight: fontWeight ?? FontWeight.normal,
            letterSpacing: letterSpacing,
            wordSpacing: wordSpacing,
            height: height,
            decoration: decoration,
            decorationColor: decorationColor,
            decorationThickness: decorationThickness,
            shadows: shadows,
          ),
    );
  }
}

''',
  );

  _write(lib, 'core/utils/snackbar_utils.dart', '''
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SnackbarUtils {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.success, content: Text(message)));
  }
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.error, content: Text(message)));
  }
}
''');

  _write(lib, 'core/constants/app_images.dart', '''
class AppImages {
  static const logo = 'assets/images/logo.png';
  static const iconSuccess = 'assets/icons/success.png';
  // Add all images/icons here centrally
}
''');

  _write(lib, 'core/constants/app_colors.dart', '''
import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0066FF);
  static const success = Color(0xFF00C853);
  static const error = Color(0xFFD32F2F);
  static const background = Color(0xFFF5F5F5);
}
''');

  // --- SPLASH VIEW ---
  Directory(p.join(lib, 'views', 'splash_view')).createSync(recursive: true);
  _write(lib, 'views/splash_view/splash_screen.dart', '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:$name/views/splash_view/splash_provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplashProvider>();

    return Scaffold(
      body: Center(
        child: Text(
          '🚀 Welcome to $name',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
''');

  // --- PROVIDER ---
  _write(lib, 'views/splash_view/splash_provider.dart', '''
import 'package:flutter/foundation.dart';

class SplashProvider extends ChangeNotifier {
  String message = 'Hello from SplashProvider';
}
''');

  // --- CONSTANTS ---
  _write(lib, 'core/constants/app_colors.dart', '''
import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0066FF);
  static const success = Color(0xFF00C853);
  static const error = Color(0xFFD32F2F);
  static const background = Color(0xFFF5F5F5);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF757575);
}
''');

  // --- EXTENSIONS ---
  _write(lib, 'core/extensions/size_extensions.dart', '''
import 'package:flutter/widgets.dart';

extension SizedBoxExt on num {
  SizedBox get h => SizedBox(height: toDouble());
  SizedBox get w => SizedBox(width: toDouble());
}
''');

  _write(lib, 'core/extensions/size_extensions.dart', '''
import 'package:flutter/widgets.dart';

extension SizedBoxExt on num {
  SizedBox get h => SizedBox(height: toDouble());
  SizedBox get w => SizedBox(width: toDouble());
}
''');

  print('');
  print('✅ Project "$name" created successfully!');
  print('📦 Installing dependencies...');

  // Clean & get
  await Process.run(
    'flutter',
    ['clean'],
    workingDirectory: name,
    runInShell: true,
  );
  await Process.run(
    'flutter',
    ['pub', 'get'],
    workingDirectory: name,
    runInShell: true,
  );

  // Force upgrade all dependencies to latest versions
  await Process.run(
    'flutter',
    ['pub', 'upgrade', '--major-versions'],
    workingDirectory: name,
    runInShell: true,
  );

  print('');
  print('🎉 Done! Run:');
  print('   cd $name');
  print('   flutter run');
}

/// --- CREATE VIEW ---
Future<void> _createView(String name) async {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('❌ Run inside a Flutter project root.');
    exit(1);
  }

  final className = _capitalize(name);
  final viewFolderName = '${name}_view';
  final viewDir = p.join(libDir.path, 'views', viewFolderName);
  Directory(viewDir).createSync(recursive: true);

  // Create view file
  _write(viewDir, '${name}_screen.dart', '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/views/${name}_view/${name}_provider.dart';

class ${className}Screen extends StatelessWidget {
  const ${className}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<${className}Provider>();
    return Scaffold(
      appBar: AppBar(title: const Text('$className')),
      body: Center(child: Text(provider.message)),
    );
  }
}
''');

  // Create provider
  _write(viewDir, '${name}_provider.dart', '''
import 'package:flutter/foundation.dart';

class ${className}Provider extends ChangeNotifier {
  String message = '$className Screen Ready';
}
''');

  // --- Automatically add to route_name.dart ---
  final routeNameFile = File(p.join(libDir.path, 'routes', 'route_name.dart'));
  if (routeNameFile.existsSync()) {
    final content = routeNameFile.readAsStringSync();
    final newRoute = "  static const String $name = '/$name';\n";
    if (!content.contains(newRoute)) {
      final updatedContent = content.replaceFirst(
        '// Add more routes here',
        '// Add more routes here\n$newRoute',
      );
      routeNameFile.writeAsStringSync(updatedContent);
    }
  }

  // --- Automatically add to routing.dart ---
  final routingFile = File(p.join(libDir.path, 'routes', 'routing.dart'));
  if (routingFile.existsSync()) {
    var content = routingFile.readAsStringSync();

    // 1. Import the new screen
    final importLine = "import '../views/$viewFolderName/${name}_screen.dart';";
    if (!content.contains(importLine)) {
      content = content.replaceFirst(
        "import 'route_name.dart';",
        "import 'route_name.dart';\n$importLine",
      );
    }

    // 2. Add case to generateRoute
    final caseLine =
        '''
      case RouteName.$name:
        return MaterialPageRoute(builder: (_) => ${className}Screen());
''';
    if (!content.contains("RouteName.$name")) {
      content = content.replaceFirst('default:', '$caseLine\n    default:');
      routingFile.writeAsStringSync(content);
    }
  }

  await Process.run(
    'flutter',
    ['pub', 'get'],
    workingDirectory: name,
    runInShell: true,
  );
  print('✅ View "$name" created and added to routing!');
}

/// --- CREATE SERVICE ---
Future<void> _createService(String name) async {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('❌ Run inside a Flutter project root.');
    exit(1);
  }

  final className = _capitalize(name);
  final serviceFile = File(
    p.join(libDir.path, 'core', 'services', '${name}_service.dart'),
  );

  _write(serviceFile.parent.path, '${name}_service.dart', '''
class ${className}Service {
  void init() {
    print('${className}Service initialized');
  }
}
''');

  await Process.run(
    'flutter',
    ['pub', 'get'],
    workingDirectory: name,
    runInShell: true,
  );
  print('✅ Service "$name" created!');
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

void _write(String lib, String path, String content) {
  final file = File(p.join(lib, path));
  file.createSync(recursive: true);
  file.writeAsStringSync('${content.trim()}\n');
}
