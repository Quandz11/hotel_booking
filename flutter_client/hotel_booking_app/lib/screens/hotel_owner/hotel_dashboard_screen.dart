import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hotel_owner_provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';
import '../../models/hotel.dart';
import '../../models/room.dart';
import '../../widgets/language_switch_button.dart';
import 'booking_management_screen.dart';
import 'room_management_screen.dart';
import 'hotel_management_screen.dart';
import 'reports_screen.dart';

class HotelDashboardScreen extends StatefulWidget {
  const HotelDashboardScreen({super.key});

  @override
  State<HotelDashboardScreen> createState() => _HotelDashboardScreenState();
}

class _HotelDashboardScreenState extends State<HotelDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final provider = Provider.of<HotelOwnerProvider>(context, listen: false);
    await provider.loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          const LanguageSwitchButton(
            iconColor: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: Consumer<HotelOwnerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.stats == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDashboardData,
                    child: Text(l10n.tryAgain),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  _buildWelcomeSection(user?.firstName ?? 'Owner'),
                  const SizedBox(height: 24),

                  // Statistics Cards
                  _buildStatisticsSection(provider),
                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActionsSection(),
                  const SizedBox(height: 24),

                  // Recent Bookings
                  _buildRecentBookingsSection(provider),
                  const SizedBox(height: 24),

                  // Hotels Overview
                  _buildHotelsOverviewSection(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(String ownerName) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.welcome}, $ownerName! 👋',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.manageYourHotelBusiness,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(HotelOwnerProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final stats = provider.stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.overview,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              title: l10n.totalBookings,
              value: stats?.totalBookings.toString() ?? '0',
              icon: Icons.book_online,
              color: Colors.blue,
            ),
            _buildStatCard(
              title: l10n.revenue,
              value: stats != null ? _formatCurrency(stats.totalRevenue) : '\$0',
              icon: Icons.monetization_on,
              color: Colors.green,
            ),
            _buildStatCard(
              title: l10n.occupancyRate,
              value: stats != null ? '${stats.occupancyRate.toStringAsFixed(1)}%' : '0%',
              icon: Icons.hotel,
              color: Colors.orange,
            ),
            _buildStatCard(
              title: l10n.totalRooms,
              value: stats?.totalRooms.toString() ?? '0',
              icon: Icons.bed,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onStatCardTap(title),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24),
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActions,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildActionCard(
              title: l10n.manageHotels,
              icon: Icons.business,
              color: Colors.blue,
              onTap: () => _navigateToHotelManagement(),
            ),
            _buildActionCard(
              title: l10n.manageRooms,
              icon: Icons.room_preferences,
              color: Colors.green,
              onTap: () => _navigateToRoomManagement(),
            ),
            _buildActionCard(
              title: l10n.manageBookings,
              icon: Icons.calendar_today,
              color: Colors.orange,
              onTap: () => _navigateToBookingManagement(),
            ),
            _buildActionCard(
              title: l10n.reports,
              icon: Icons.bar_chart,
              color: Colors.purple,
              onTap: () => _showReports(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBookingsSection(HotelOwnerProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final recentBookings = provider.recentBookings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.recentBookings,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (recentBookings.isNotEmpty)
              TextButton(
                onPressed: () => _navigateToBookingManagement(),
                child: Text(l10n.viewAll),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentBookings.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_note,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noRecentBookings,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentBookings.length.clamp(0, 5),
            itemBuilder: (context, index) {
              final booking = recentBookings[index];
              return _buildBookingCard(booking);
            },
          ),
      ],
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onBookingCardTap(booking),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${booking.customerName} - ${booking.roomName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: booking.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.statusDisplayText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: booking.statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(booking.checkIn)} - ${_formatDate(booking.checkOut)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatCurrency(booking.totalAmount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotelsOverviewSection(HotelOwnerProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final hotels = provider.ownedHotels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.myHotels,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hotels.isNotEmpty)
              TextButton(
                onPressed: () => _navigateToHotelManagement(),
                child: Text(l10n.viewAll),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (hotels.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.business,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noHotelsYet,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _navigateToHotelManagement(),
                  child: Text(l10n.addHotel),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: hotels.length.clamp(0, 3),
            itemBuilder: (context, index) {
              final hotel = hotels[index];
              final rooms = provider.getRoomsForHotel(hotel.id);
              final bookings = provider.getBookingsForHotel(hotel.id);
              return _buildHotelOverviewCard(hotel, rooms, bookings);
            },
          ),
      ],
    );
  }

  Widget _buildHotelOverviewCard(Hotel hotel, List<Room> rooms, List<Booking> bookings) {
    final activeBookings = bookings.where((b) => b.isActive).length;
    final totalRevenue = bookings
        .where((b) => b.isCompleted)
        .fold(0.0, (sum, b) => sum + b.totalAmount);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onHotelCardTap(hotel),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (hotel.images.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        hotel.images.first.url,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hotel.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${hotel.address.city}, ${hotel.address.country}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildHotelStat(
                      label: 'Rooms',
                      value: rooms.length.toString(),
                      icon: Icons.room_preferences,
                    ),
                  ),
                  Expanded(
                    child: _buildHotelStat(
                      label: 'Active',
                      value: activeBookings.toString(),
                      icon: Icons.hotel,
                    ),
                  ),
                  Expanded(
                    child: _buildHotelStat(
                      label: 'Revenue',
                      value: _formatCurrency(totalRevenue),
                      icon: Icons.attach_money,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotelStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _navigateToHotelManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HotelManagementScreen(),
      ),
    );
  }

  void _navigateToRoomManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RoomManagementScreen(),
      ),
    );
  }

  void _navigateToBookingManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BookingManagementScreen(),
      ),
    );
  }

  void _showReports() {
    final provider = Provider.of<HotelOwnerProvider>(context, listen: false);
    final selectedHotel = provider.ownedHotels.isNotEmpty ? provider.ownedHotels.first : null;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportsScreen(hotel: selectedHotel),
      ),
    );
  }

  void _onStatCardTap(String title) {
    final l10n = AppLocalizations.of(context)!;
    
    if (title == l10n.totalBookings) {
      _navigateToBookingManagement();
    } else if (title == l10n.revenue) {
      _showReports();
    } else if (title == l10n.occupancyRate) {
      _showReports();
    } else if (title == l10n.totalRooms) {
      _navigateToRoomManagement();
    }
  }

  void _onBookingCardTap(Booking booking) {
    _showBookingDetails(booking);
  }

  void _onHotelCardTap(Hotel hotel) {
    _showHotelOptions(hotel);
  }

  void _showBookingDetails(Booking booking) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.bookingDetails),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(l10n.customerName, booking.customerName),
              _buildDetailRow(l10n.roomName, booking.roomName),
              _buildDetailRow(l10n.checkIn, _formatDate(booking.checkIn)),
              _buildDetailRow(l10n.checkOut, _formatDate(booking.checkOut)),
              _buildDetailRow(l10n.totalAmount, _formatCurrency(booking.totalAmount)),
              _buildDetailRow(l10n.status, booking.statusDisplayText),
              if (booking.specialRequests != null && booking.specialRequests!.isNotEmpty)
                _buildDetailRow(l10n.specialRequests, booking.specialRequests!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToBookingManagement();
            },
            child: Text(l10n.manageBookings),
          ),
        ],
      ),
    );
  }

  void _showHotelOptions(Hotel hotel) {
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hotel.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildBottomSheetOption(
              icon: Icons.edit,
              title: l10n.editHotel,
              onTap: () {
                Navigator.pop(context);
                _editHotel(hotel);
              },
            ),
            _buildBottomSheetOption(
              icon: Icons.room_preferences,
              title: l10n.manageRooms,
              onTap: () {
                Navigator.pop(context);
                _navigateToRoomManagement();
              },
            ),
            _buildBottomSheetOption(
              icon: Icons.calendar_today,
              title: l10n.viewBookings,
              onTap: () {
                Navigator.pop(context);
                _navigateToBookingManagement();
              },
            ),
            _buildBottomSheetOption(
              icon: Icons.bar_chart,
              title: l10n.viewReports,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportsScreen(hotel: hotel),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  void _editHotel(Hotel hotel) {
    // Navigate to edit hotel screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HotelManagementScreen(),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} ₫';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
