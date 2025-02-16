# Widgy - Flutter Widget Isolator

Widgy is a **powerful Flutter package** that allows developers to **build, test, and preview widgets in isolation**. It enhances **UI development, debugging, and collaboration** by enabling interactive widget registration and previewing.

---

## 🚀 Features

✅ **Isolate and Preview Widgets** – View widgets separately in a catalog.  
✅ **Automatic Widget Discovery** – Finds and registers widgets automatically.  
✅ **Interactive CLI Selection** – Choose which widgets to register using a CLI interface.  
✅ **Live Property Editing** – Modify widget properties dynamically.  
✅ **Supports `auto_route` and `dataflow`** – Ensures smooth navigation and state management.  
✅ **Non-intrusive Integration** – Works with or without `dataflow` dependency in your app.  
✅ **Automatic `widgy_registry.dart` Management** – Keeps track of registered widgets efficiently.  
✅ **Selective Widget Registration** – Allows you to manually choose which widgets to register.  
✅ **No Flutter SDK Scanning Issues** – Avoids scanning Flutter SDK and external packages.  
✅ **Widget Dependency Graph** – Generate an interactive dependency graph of widgets.

---

## 📂 Open in IDX

<a href="https://idx.google.com/import?url=https%3A%2F%2Fgithub.com%2Fiampawan%2FWidgy">
  <picture>
    <source
      media="(prefers-color-scheme: dark)"
      srcset="https://cdn.idx.dev/btn/open_dark_32.svg">
    <source
      media="(prefers-color-scheme: light)"
      srcset="https://cdn.idx.dev/btn/open_light_32.svg">
    <img
      height="32"
      alt="Open in IDX"
      src="https://cdn.idx.dev/btn/open_purple_32.svg">
  </picture>
</a>

---

## 📦 Installation

Add `widgy` to your Flutter project's dependencies:

```sh
flutter pub add widgy
```

For CLI usage, install globally:

```sh
dart pub global activate widgy
```

---

## 🎮 Usage

### **1️⃣ Initialize Widgy**

To start using Widgy, initialize it in your `main.dart`:

```dart
import 'package:widgy/widgy.dart';

void main() {
  Widgy.init();
  runApp(const MyApp());
}
```

---

### **2️⃣ Register a Widget Manually**

```dart
Widgy.registerWidget(
  name: "Custom Button",
  builder: (props) => ElevatedButton(
    onPressed: () {},
    child: Text("Click Me"),
  ),
);
```

---

### **3️⃣ Auto-Discover Widgets**

Run the CLI command to automatically discover widgets inside your project:

```sh
dart run widgy --discover
```

📌 **Widgy will scan your project’s `lib/` directory for Stateless and Stateful widgets and prompt you to select widgets for registration.**

---

### **4️⃣ Widget Selection via CLI**

After running `dart run widgy --discover`, you will see an interactive list:

```sh
Select widgets to register:
[ ] CustomButton
[ ] ProfileCard
[ ] ProductTile
[x] Select All
```

✔ Select widgets using **arrow keys and spacebar**.  
✔ Press **Enter** to confirm the selection.  
✔ Only selected widgets will be registered in `widgy_registry.dart`.

---

### **5️⃣ Generate Widget Dependency Graph**

Widgy allows you to generate an **interactive dependency graph** of your widgets, showing how they relate to each other.

Run:

```sh
dart run widgy --graph
```

This will:

- Analyze the **build methods** of all widgets in `lib/`
- Generate a **DOT file (`widget_dependency_graph.dot`)** that can be visualized using Graphviz
- Create an **interactive HTML file (`widget_dependency_graph.html`)** for easy visualization

📌 **You can optionally include Flutter widgets in the graph with:**

```sh
dart run widgy --graph --include-flutter
```

---

### 6️⃣ Running the Widget Isolator\*\*

To start the **Widgy UI Catalog**, run:

```sh
dart run widgy --ui
```

This will open a browser UI where you can **preview, modify properties, and test widgets interactively**.

---

## 📂 Widgy Script & Generated Files

Widgy automatically manages a file called `widgy_registry.dart`, which contains all registered widgets.

**Example:**

```dart
// GENERATED FILE: Do not modify manually.

import 'package:widgy/widgy.dart';
import 'package:my_app/widgets.dart';

void registerWidgets() {
  Widgy.registerMultipleWidgets([
    WidgetMetaData(name: "CustomButton", widgetBuilder: (context) => CustomButton()),
    WidgetMetaData(name: "ProfileCard", widgetBuilder: (context) => ProfileCard()),
  ]);
}
```

---

## 🛠 CLI Commands

| Command                             | Description                                  |
| ----------------------------------- | -------------------------------------------- |
| `dart run widgy --discover`         | Auto-detect widgets and register them        |
| `dart run widgy --graph`            | Generates a widget dependency graph          |
| `dart run widgy --ui`               | Start the widget preview UI (Under Dev)      |
| `dart run widgy --log=logfile.txt`  | Log discovered widgets to a file (Under Dev) |
| `dart run widgy --generate-preview` | Generate widget previews (Under Dev)         |

---

## 🔧 Advanced Configuration

Widgy allows optional parameters for `discover`:

```sh
dart run widgy --discover --exclude=generated,build
```

This will **exclude specific directories** from the widget scan.

---

## 🎯 Why Use Widgy?

✅ **Saves Time** – No need to manually navigate screens to test widgets.  
✅ **Reduces Errors** – Ensures widgets behave correctly in isolation.  
✅ **Enhances Team Collaboration** – Easily share reusable components.  
✅ **Improves Development Workflow** – Debug widgets with live updates.

---

## 🛠️ Contributing

We welcome contributions! If you have ideas or improvements, feel free to **open an issue or submit a PR**.

---

## 📄 License

Widgy is licensed under the **MIT License**.
