import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import '../hotel_owner/hotel_dashboard_screen.dart';
import '../hotel_owner/booking_management_screen.dart';
import '../booking/customer_bookings_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final user = authProvider.currentUser;

    // Danh sách trang cho khách hàng
    List<Widget> customerPages = [
      const HomeScreen(),
      const SearchScreen(),
      const CustomerBookingsScreen(),
      const ProfileScreen(),
    ];

    // Danh sách trang cho chủ khách sạn
    List<Widget> hotelOwnerPages = [
      const HotelDashboardScreen(),
      const BookingManagementScreen(),
      const ProfileScreen(),
    ];

    // Bottom navigation items cho khách hàng
    List<BottomNavigationBarItem> customerNavItems = [
      BottomNavigationBarItem(
        icon: const Icon(Icons.home),
        label: l10n.home,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.search),
        label: l10n.search,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.book_online),
        label: l10n.bookings,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person),
        label: l10n.profile,
      ),
    ];

    // Bottom navigation items cho chủ khách sạn
    List<BottomNavigationBarItem> hotelOwnerNavItems = [
      BottomNavigationBarItem(
        icon: const Icon(Icons.dashboard),
        label: l10n.dashboard,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.book_online),
        label: l10n.bookings,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person),
        label: l10n.profile,
      ),
    ];

    bool isHotelOwner = user?.role == 'hotel_owner';
    List<Widget> pages = isHotelOwner ? hotelOwnerPages : customerPages;
    List<BottomNavigationBarItem> navItems = isHotelOwner ? hotelOwnerNavItems : customerNavItems;

    // Điều chỉnh selectedIndex nếu cần thiết
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: navItems,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
