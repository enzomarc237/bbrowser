import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: 'WebKit Browser',
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      sidebar: Sidebar(
        minWidth: 200,
        builder: (context, scrollController) {
          return const Center(
            child: Text('Left Sidebar'),
          );
        },
      ),
      child: MacosScaffold(
        toolBar: ToolBar(
          title: const Text('Top Navigation Bar'),
        ),
        children: [
          ContentArea(
            builder: (context, scrollController) {
              return const Center(
                child: Text('Main Content Area'),
              );
            },
          ),
        ],
      ),
    );
  }
}