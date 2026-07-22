import 'package:flutter/material.dart';
import 'screens/search_screen.dart';
import 'screens/category_screen.dart';
import 'screens/seeds_screen.dart';

void main() {
  runApp(const BoiWikiApp());
}

class BoiWikiApp extends StatelessWidget {
  const BoiWikiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isaac Codex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFFFF3B3B),
          onPrimary: Color(0xFF1A0000),
          primaryContainer: Color(0xFF5A0F0F),
          onPrimaryContainer: Color(0xFFFFD8D6),
          secondary: Color(0xFFCE93D8),
          onSecondary: Color(0xFF1A0033),
          secondaryContainer: Color(0xFF3D1A4D),
          onSecondaryContainer: Color(0xFFE9C9F2),
          tertiary: Color(0xFFFFC107),
          onTertiary: Color(0xFF2A1F00),
          tertiaryContainer: Color(0xFF4A3700),
          onTertiaryContainer: Color(0xFFFFE38A),
          error: Color(0xFFFF6B6B),
          onError: Color(0xFF410002),
          errorContainer: Color(0xFF690005),
          onErrorContainer: Color(0xFFFFDAD6),
          surface: Color(0xFF161214),
          onSurface: Color(0xFFEDE6E8),
          surfaceContainerLowest: Color(0xFF0B090A),
          surfaceContainerLow: Color(0xFF141011),
          surfaceContainer: Color(0xFF1B1719),
          surfaceContainerHigh: Color(0xFF231E20),
          surfaceContainerHighest: Color(0xFF2C2628),
          onSurfaceVariant: Color(0xFFCFC4C7),
          outline: Color(0xFF7A6C70),
          outlineVariant: Color(0xFF3F3537),
          inverseSurface: Color(0xFFEDE6E8),
          onInverseSurface: Color(0xFF1B1719),
          inversePrimary: Color(0xFF8A1A1A),
          shadow: Color(0xFF000000),
          scrim: Color(0xFF000000),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B090A),
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    SearchScreen(),
    CategoryScreen(),
    SeedsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Seeds',
          ),
        ],
      ),
    );
  }
}
