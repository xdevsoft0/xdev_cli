
# Xdev CLI 🚀

**XDev CLI** is a developer-friendly command-line tool to streamline Flutter project development. Quickly scaffold projects, views, and services with built-in support for **Provider** state management and routing.

## Features
- Scaffold a new Flutter project with **Provider**, **routing**, and **assets** setup.
- Automatically generate new **views** with Provider and routing integration.
- Generate reusable **service classes** inside `core/services`.

---

## Installation

1. Make sure you have **Dart SDK** installed. You can check by running:

```bash
dart --version
````

2. Install XDev CLI globally:

```bash
dart pub global activate xdev_cli
```

3. Make sure Dart’s global executables are in your PATH:

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

---

## Usage

### 1. Create a New Flutter Project

Create a new Flutter project with Provider, routing, and assets set up:

```bash
xdev create project my_app
```

### 2. Navigate to Your Project

```bash
cd my_app
```

### 3. Create a New View

Generate a new view with its corresponding Provider/ViewModel and routing entry:

```bash
xdev create view dashboard
```

This will create:

```
lib/views/dashboard/
├── dashboard_view.dart
├── dashboard_view_model.dart
```

And automatically register the route in `lib/routes.dart`.

### 4. Create a New Service

Generate a reusable service class inside `core/services`:

```bash
xdev create service api
```

This will create:

```
lib/core/services/api_service.dart
```

---

## Example Project Structure

After generating a project and a few views/services, your structure may look like this:

```
my_app/
├── lib/
│   ├── core/
│   │   └── services/
│   │       └── api_service.dart
│   ├── views/
│   │   └── dashboard/
│   │       ├── dashboard_view.dart
│   │       └── dashboard_view_model.dart
│   ├── main.dart
│   └── routes.dart
├── pubspec.yaml
└── README.md
```

---

## Full CLI Command Reference

| Command                      | Description                                                           |
| ---------------------------- | --------------------------------------------------------------------- |
| `xdev create project <name>` | Create a new Flutter project with Provider, routing, and assets setup |
| `xdev create view <name>`    | Generate a new view and ViewModel with routing entry                  |
| `xdev create service <name>` | Generate a new reusable service class in `core/services`              |

---

## Example Workflow

```bash
# Install XDev CLI
dart pub global activate xdev_cli

# Create a new project
xdev create project my_app

# Go to project directory
cd my_app

# Create a view
xdev create view dashboard

# Create a service
xdev create service api

# Run the app
flutter run
```

---

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to improve XDev CLI.

---

## License

MIT License © 2025

```

This is a **full, beginner-friendly guide** that includes installation, usage, project structure, commands, and workflow—all in one file.  

If you want, I can also **add screenshots or ASCII diagrams** to make it visually appealing for GitHub. Do you want me to do that?
```
