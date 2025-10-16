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

/// --- PROJECT CREATION ---
///
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
import 'providers/splash_provider.dart';

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
import '../views/splash_view/splash_screen.dart';
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

  // --- SPLASH VIEW ---
  Directory(p.join(lib, 'views', 'splash_view')).createSync(recursive: true);
  _write(lib, 'views/splash_view/splash_screen.dart', '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/splash_provider.dart';

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
  _write(lib, 'providers/splash_provider.dart', '''
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
  Process.runSync('code', ['--version'], runInShell: true);
}

// ---- open project  ----
Future<void> openProject(String projectPath) async {
  if (isVSCodeInstalled()) {
    await Process.run(
      'code',
      ['.'],
      workingDirectory: projectPath,
      runInShell: true,
    );
  } else if (isAndroidStudioInstalled()) {
    await Process.run('open', [
      '-a',
      'Android Studio',
      projectPath,
    ], runInShell: true);
  } else {
    print('⚠️ No supported IDE found. Open the project manually.');
  }
}

// ----- check if VSCode is installed ----
bool isVSCodeInstalled() {
  try {
    final result = Process.runSync('code', ['--version'], runInShell: true);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

// ----- check if Android Studio is installed ----
bool isAndroidStudioInstalled() {
  try {
    final result = Process.runSync('open', [
      '-Ra',
      'Android Studio',
    ], runInShell: true);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
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
import '../../providers/${name}_provider.dart';

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

  print('✅ Service "$name" created!');
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

void _write(String lib, String path, String content) {
  final file = File(p.join(lib, path));
  file.createSync(recursive: true);
  file.writeAsStringSync('${content.trim()}\n');
}
