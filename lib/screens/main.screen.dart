import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/screens/accounts/accounts.screen.dart';
import 'package:fintracker/screens/categories/categories.screen.dart';
import 'package:fintracker/screens/home/home.screen.dart';
import 'package:fintracker/screens/onboard/onboard_screen.dart';
import 'package:fintracker/screens/recurring/recurring.screen.dart';
import 'package:fintracker/screens/settings/settings.screen.dart';
import 'package:fintracker/services/haptic_service.dart';
import 'package:fintracker/ui/prism.dart';
import 'package:flutter/material.dart';
import 'package:fintracker/config/strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class MainScreen extends StatefulWidget{
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen>{
  final PageController _controller = PageController();
  int _selected = 0;

  final List<PrismBottomNavItem> _navItems = const [
    PrismBottomNavItem(icon: Symbols.home, label: 'Home'),
    PrismBottomNavItem(icon: Symbols.wallet, label: 'Accounts'),
    PrismBottomNavItem(icon: Symbols.category, label: 'Categories'),
    PrismBottomNavItem(icon: Symbols.repeat, label: 'Recurring'),
    PrismBottomNavItem(icon: Symbols.settings, label: 'Settings'),
  ];

  final List<NavigationRailDestination> _railDestinations = const [
    NavigationRailDestination(icon: Icon(Symbols.home, fill: 1,), label: Text(Strings.home)),
    NavigationRailDestination(icon: Icon(Symbols.wallet, fill: 1,), label: Text(Strings.accounts)),
    NavigationRailDestination(icon: Icon(Symbols.category, fill: 1,), label: Text(Strings.categories)),
    NavigationRailDestination(icon: Icon(Symbols.repeat, fill: 1,), label: Text(Strings.recurring)),
    NavigationRailDestination(icon: Icon(Symbols.settings, fill: 1,), label: Text(Strings.settings)),
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
    if (!mounted || selected < 0 || selected >= _navItems.length) return;
    HapticService.selection();
    _controller.animateToPage(
      selected,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    _onPageChanged(selected);
  }

  void navigateTo(int index) {
    if (!mounted || index < 0 || index >= _navItems.length) return;
    _onDestinationSelected(index);
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
        final AppCubit cubit = context.read<AppCubit>();
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
          bottomNavigationBar: PrismBottomNav(
            selectedIndex: _selected,
            items: _navItems,
            onTap: _onDestinationSelected,
          ),
        );
      },
    );

  }
}