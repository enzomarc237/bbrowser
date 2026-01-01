import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'blocs/tab/tab_bloc.dart';
import 'blocs/tab/tab_event.dart';
import 'widgets/navigation_bar.dart';
import 'widgets/sidebar.dart';
import 'widgets/content_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: 'BBrowser',
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TabBloc()..add(const TabCreated()),
      child: const BrowserWindow(),
    );
  }
}

class BrowserWindow extends StatelessWidget {
  const BrowserWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      sidebar: Sidebar(
        minWidth: 200,
        maxWidth: 300,
        shownByDefault: true,
        builder: (context, scrollController) {
          return const TabSidebar();
        },
      ),
      child: const MacosScaffold(
        toolBar: ToolBar(
          title: BrowserNavigationBar(),
        ),
        children: [
          ContentView(),
        ],
      ),
    );
  }
}
