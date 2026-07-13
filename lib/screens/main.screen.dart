import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/screens/accounts/accounts.screen.dart';
import 'package:fintracker/screens/categories/categories.screen.dart';
import 'package:fintracker/screens/home/home.screen.dart';
import 'package:fintracker/screens/onboard/onboard_screen.dart';
import 'package:fintracker/screens/recurring/recurring.screen.dart';
import 'package:fintracker/screens/settings/settings.screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class MainScreen extends StatefulWidget{
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen>{
  final PageController _controller = PageController(keepPage: true);
  int _selected = 0;

  final List<NavigationDestination> _navDestinations = const [
    NavigationDestination(icon: Icon(Symbols.home, fill: 1,), label: "Home"),
    NavigationDestination(icon: Icon(Symbols.wallet, fill: 1,), label: "Accounts"),
    NavigationDestination(icon: Icon(Symbols.category, fill: 1,), label: "Categories"),
    NavigationDestination(icon: Icon(Symbols.repeat, fill: 1,), label: "Recurring"),
    NavigationDestination(icon: Icon(Symbols.settings, fill: 1,), label: "Settings"),
  ];

  final List<NavigationRailDestination> _railDestinations = const [
    NavigationRailDestination(icon: Icon(Symbols.home, fill: 1,), label: Text("Home")),
    NavigationRailDestination(icon: Icon(Symbols.wallet, fill: 1,), label: Text("Accounts")),
    NavigationRailDestination(icon: Icon(Symbols.category, fill: 1,), label: Text("Categories")),
    NavigationRailDestination(icon: Icon(Symbols.repeat, fill: 1,), label: Text("Recurring")),
    NavigationRailDestination(icon: Icon(Symbols.settings, fill: 1,), label: Text("Settings")),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (!mounted) return;
    setState(() {
      _selected = index;
    });
  }

  void _onDestinationSelected(int selected) {
    if (!mounted || selected < 0 || selected >= _navDestinations.length) return;
    _controller.jumpToPage(selected);
  }

  void navigateTo(int index) {
    if (!mounted || index < 0 || index >= _navDestinations.length) return;
    _controller.jumpToPage(index);
    _onPageChanged(index);
  }

  Widget _buildPageView() {
    return PageView(
      controller: _controller,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: _onPageChanged,
      children: const [
        HomeScreen(),
        AccountsScreen(),
        CategoriesScreen(),
        RecurringScreen(),
        SettingsScreen()
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state){
        AppCubit cubit = context.read<AppCubit>();
        if(cubit.state.currency == null || cubit.state.username == null){
          return const OnboardScreen();
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final useRail = screenWidth >= 600;

        if (useRail) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selected,
                  destinations: _railDestinations,
                  onDestinationSelected: _onDestinationSelected,
                  extended: screenWidth >= 900,
                  minExtendedWidth: 180,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _buildPageView()),
              ],
            ),
          );
        }

        return  Scaffold(
          body: _buildPageView(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selected,
            destinations: _navDestinations,
            onDestinationSelected: _onDestinationSelected,
          ),
        );
      },
    );

  }
}