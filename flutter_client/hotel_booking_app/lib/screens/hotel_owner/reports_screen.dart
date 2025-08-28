import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/hotel_owner_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/hotel.dart';
import '../../models/booking.dart';

class ReportsScreen extends StatefulWidget {
  final Hotel? hotel;

  const ReportsScreen({super.key, this.hotel});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'month';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReportData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReportData() {
    final provider = Provider.of<HotelOwnerProvider>(context, listen: false);
    // Load bookings for reports
    if (widget.hotel != null) {
      provider.loadHotelBookings(widget.hotel!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: l10n.overview),
            Tab(text: l10n.revenue),
            Tab(text: l10n.bookings),
            Tab(text: l10n.rooms),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildRevenueTab(),
                _buildBookingsTab(),
                _buildRoomsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // Period selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 16),
                _buildPeriodChip('week', l10n.week),
                const SizedBox(width: 8),
                _buildPeriodChip('month', l10n.month),
                const SizedBox(width: 8),
                _buildPeriodChip('year', l10n.year),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Custom date button
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                onPressed: _selectCustomDateRange,
                icon: const Icon(Icons.date_range, size: 16),
                label: Text(l10n.customDate),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String period, String label) {
    final isSelected = _selectedPeriod == period;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
          _updateDateRange();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<HotelOwnerProvider>(
      builder: (context, provider, child) {
        final bookings = provider.hotelBookings;
        final stats = _calculateOverviewStats(bookings);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(stats),
              const SizedBox(height: 24),
              _buildRevenueChart(bookings),
              const SizedBox(height: 24),
              _buildTopRoomsCard(bookings),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRevenueTab() {
    return Consumer<HotelOwnerProvider>(
      builder: (context, provider, child) {
        final bookings = provider.hotelBookings;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildRevenueChart(bookings),
              const SizedBox(height: 24),
              _buildRevenueBreakdown(bookings),
              const SizedBox(height: 24),
              _buildMonthlyComparison(bookings),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingsTab() {
    return Consumer<HotelOwnerProvider>(
      builder: (context, provider, child) {
        final bookings = provider.hotelBookings
            .where((b) => _isInDateRange(b.createdAt))
            .toList();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildBookingStatusChart(bookings),
              const SizedBox(height: 24),
              _buildRecentBookingsList(bookings),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoomsTab() {
    return Consumer<HotelOwnerProvider>(
      builder: (context, provider, child) {
        final rooms = provider.allRooms.where((r) => 
          widget.hotel == null || r.hotelId == widget.hotel!.id
        ).toList();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildRoomOccupancyChart(rooms),
              const SizedBox(height: 24),
              _buildRoomPerformanceList(rooms),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    final l10n = AppLocalizations.of(context)!;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        final childAspectRatio = constraints.maxWidth > 600 ? 1.4 : 1.6;
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildStatCard(
              l10n.totalRevenue,
              _formatCurrency(stats['totalRevenue'] ?? 0),
              Icons.attach_money,
              Colors.green,
            ),
            _buildStatCard(
              l10n.totalBookings,
              (stats['totalBookings'] ?? 0).toString(),
              Icons.book_online,
              Colors.blue,
            ),
            _buildStatCard(
              l10n.averageRating,
              (stats['averageRating'] ?? 0.0).toStringAsFixed(1),
              Icons.star,
              Colors.orange,
            ),
            _buildStatCard(
              l10n.occupancyRate,
              '${(stats['occupancyRate'] ?? 0).toStringAsFixed(1)}%',
              Icons.hotel,
              Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(List<Booking> bookings) {
    final l10n = AppLocalizations.of(context)!;
    final revenueData = _getRevenueData(bookings);
    
    return Container(
      constraints: const BoxConstraints(
        minHeight: 250,
        maxHeight: 350,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.revenueOverTime,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: revenueData.isEmpty
                ? Center(child: Text(l10n.noDataAvailable))
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _formatCurrency(value),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < revenueData.length) {
                                return Text(
                                  revenueData[index]['date'],
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: revenueData.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value['revenue'].toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingStatusChart(List<Booking> bookings) {
    final l10n = AppLocalizations.of(context)!;
    final statusData = _getBookingStatusData(bookings);
    
    return Container(
      constraints: const BoxConstraints(
        minHeight: 250,
        maxHeight: 350,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.bookingsByStatus,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: statusData.isEmpty
                ? Center(child: Text(l10n.noDataAvailable))
                : PieChart(
                    PieChartData(
                      sections: statusData.map((data) {
                        return PieChartSectionData(
                          value: data['value'].toDouble(),
                          title: '${data['percentage'].toStringAsFixed(1)}%',
                          color: data['color'],
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Wrap(
            children: statusData.map((data) {
              return Container(
                margin: const EdgeInsets.only(right: 16, bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: data['color'],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data['label'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRoomsCard(List<Booking> bookings) {
    final l10n = AppLocalizations.of(context)!;
    final topRooms = _getTopRooms(bookings);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.topPerformingRooms,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (topRooms.isEmpty)
            Center(child: Text(l10n.noDataAvailable))
          else
            ...topRooms.take(5).map((room) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        room['rank'].toString(),
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${room['bookings']} ${l10n.bookings}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatCurrency(room['revenue']),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentBookingsList(List<Booking> bookings) {
    final l10n = AppLocalizations.of(context)!;
    final recentBookings = bookings.take(10).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recentBookings,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (recentBookings.isEmpty)
            Center(child: Text(l10n.noBookingsFound))
          else
            ...recentBookings.map((booking) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _getStatusColor(booking.status).withOpacity(0.1),
                      child: Icon(
                        _getStatusIcon(booking.status),
                        color: _getStatusColor(booking.status),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.customerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatDate(booking.checkIn)} - ${_formatDate(booking.checkOut)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatCurrency(booking.totalAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getStatusText(booking.status),
                            style: TextStyle(
                              color: _getStatusColor(booking.status),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdown(List<Booking> bookings) {
    final l10n = AppLocalizations.of(context)!;
    // Implementation for revenue breakdown
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.revenueBreakdown,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Text(l10n.comingSoon)),
        ],
      ),
    );
  }

  Widget _buildMonthlyComparison(List<Booking> bookings) {
    final l10n = AppLocalizations.of(context)!;
    // Implementation for monthly comparison
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.monthlyComparison,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Text(l10n.comingSoon)),
        ],
      ),
    );
  }

  Widget _buildRoomOccupancyChart(List rooms) {
    final l10n = AppLocalizations.of(context)!;
    // Implementation for room occupancy chart
    return Container(
      constraints: const BoxConstraints(
        minHeight: 200,
        maxHeight: 300,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.roomOccupancy,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(child: Text(l10n.comingSoon)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomPerformanceList(List rooms) {
    final l10n = AppLocalizations.of(context)!;
    // Implementation for room performance list
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.roomPerformance,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Text(l10n.comingSoon)),
        ],
      ),
    );
  }

  // Helper methods
  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'week':
        _startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        _startDate = now.subtract(const Duration(days: 30));
        break;
      case 'year':
        _startDate = now.subtract(const Duration(days: 365));
        break;
    }
    _endDate = now;
    _loadReportData();
  }

  Future<void> _selectCustomDateRange() async {
    final l10n = AppLocalizations.of(context)!;
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      helpText: l10n.selectDateRange,
    );
    
    if (picked != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReportData();
    }
  }

  bool _isInDateRange(DateTime date) {
    return date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
           date.isBefore(_endDate.add(const Duration(days: 1)));
  }

  Map<String, dynamic> _calculateOverviewStats(List<Booking> bookings) {
    final filteredBookings = bookings.where((b) => _isInDateRange(b.createdAt)).toList();
    
    double totalRevenue = 0;
    int totalBookings = filteredBookings.length;
    double totalRating = 0;
    int ratingCount = 0;
    
    for (final booking in filteredBookings) {
      if (booking.status == 'confirmed' || booking.status == 'completed') {
        totalRevenue += booking.totalAmount;
      }
      // Add rating calculation if available
    }
    
    return {
      'totalRevenue': totalRevenue,
      'totalBookings': totalBookings,
      'averageRating': ratingCount > 0 ? totalRating / ratingCount : 0.0,
      'occupancyRate': 75.0, // Placeholder - calculate from actual data
    };
  }

  List<Map<String, dynamic>> _getRevenueData(List<Booking> bookings) {
    final filteredBookings = bookings.where((b) => _isInDateRange(b.createdAt)).toList();
    final Map<String, double> dailyRevenue = {};
    
    for (final booking in filteredBookings) {
      if (booking.status == 'confirmed' || booking.status == 'completed') {
        final date = '${booking.createdAt.month}/${booking.createdAt.day}';
        dailyRevenue[date] = (dailyRevenue[date] ?? 0) + booking.totalAmount;
      }
    }
    
    return dailyRevenue.entries.map((entry) {
      return {
        'date': entry.key,
        'revenue': entry.value,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _getBookingStatusData(List<Booking> bookings) {
    final statusCounts = <String, int>{};
    for (final booking in bookings) {
      statusCounts[booking.status] = (statusCounts[booking.status] ?? 0) + 1;
    }
    
    final total = bookings.length;
    if (total == 0) return [];
    
    return statusCounts.entries.map((entry) {
      return {
        'label': _getStatusText(entry.key),
        'value': entry.value,
        'percentage': (entry.value / total) * 100,
        'color': _getStatusColor(entry.key),
      };
    }).toList();
  }

  List<Map<String, dynamic>> _getTopRooms(List<Booking> bookings) {
    final roomStats = <String, Map<String, dynamic>>{};
    
    for (final booking in bookings.where((b) => _isInDateRange(b.createdAt))) {
      final roomId = booking.roomId;
      if (!roomStats.containsKey(roomId)) {
        roomStats[roomId] = {
          'name': 'Room ${roomId.substring(0, 8)}', // Placeholder
          'bookings': 0,
          'revenue': 0.0,
        };
      }
      roomStats[roomId]!['bookings']++;
      if (booking.status == 'confirmed' || booking.status == 'completed') {
        roomStats[roomId]!['revenue'] += booking.totalAmount;
      }
    }
    
    final sortedRooms = roomStats.values.toList()
      ..sort((a, b) => b['revenue'].compareTo(a['revenue']));
    
    return sortedRooms.asMap().entries.map((entry) {
      return {
        'rank': entry.key + 1,
        ...entry.value,
      };
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'confirmed':
        return l10n.confirmed;
      case 'pending':
        return l10n.pending;
      case 'cancelled':
        return l10n.cancelled;
      case 'completed':
        return l10n.completed;
      default:
        return status;
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B VND';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M VND';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K VND';
    } else {
      return '${amount.toStringAsFixed(0)} VND';
    }
  }

  String _formatCurrencyFull(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} VND';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
