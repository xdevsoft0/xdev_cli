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

  /// --- Update pubspec ---
  final pubspecFile = File(p.join(name, 'pubspec.yaml'));
  var pubspecContent = pubspecFile.readAsStringSync();
  pubspecContent = pubspecContent.replaceFirst(
    'dependencies:\n',
    'dependencies:\n  provider: ^6.1.2\n  flutter_screenutil: ^5.9.0\n  google_fonts: ^6.1.0\n',
  );
  pubspecContent = pubspecContent.replaceFirst(
    'flutter:\n',
    'flutter:\n  assets:\n    - assets/images/\n    - assets/icons/\n\n',
  );
  pubspecFile.writeAsStringSync(pubspecContent);

  Directory(p.join(name, 'assets', 'images')).createSync(recursive: true);
  Directory(p.join(name, 'assets', 'icons')).createSync(recursive: true);

  /// --- Create main.dart and other files ---
  // (Your existing code for main.dart, routes, views, providers, etc.)

  print('');
  print('✅ Project "$name" created successfully!');

  /// --- RUN flutter clean ---
  print('⚡ Running flutter clean...');
  await Process.run(
    'flutter',
    ['clean'],
    workingDirectory: name,
    runInShell: true,
  );

  /// --- RUN flutter pub get ---
  print('📦 Running flutter pub get...');
  await Process.run(
    'flutter',
    ['pub', 'get'],
    workingDirectory: name,
    runInShell: true,
  );

  print('');
  print('🎉 Done! Your project is ready to run:');
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

  _write(viewDir, '${name}_provider.dart', '''
import 'package:flutter/foundation.dart';

class ${className}Provider extends ChangeNotifier {
  String message = '$className Screen Ready';
}
''');

  print('✅ View "$name" created successfully!');
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
