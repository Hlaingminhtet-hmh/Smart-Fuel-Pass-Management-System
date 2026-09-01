import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../models/transaction.dart';
import '../../models/user.dart';
import '../../models/vehicle.dart';
import '../about/about_screen.dart';
import '../claim/claim_screen.dart';
import '../history/history_screen.dart';
import '../login/login_screen.dart';
import '../vehicle/vehicle_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppUser user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiClient _api = ApiClient();

  final PageController _vehiclePageController = PageController(
    viewportFraction: 0.88,
  );

  int _currentIndex = 0;
  int _currentVehicleIndex = 0;

  List<UserVehicle> _vehicles = [];
  List<UserTransaction> _transactions = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
    _vehiclePageController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final vehicles = await _api.vehicles();

      List<UserTransaction> transactions = [];

      try {
        transactions = await _api.history();
      } catch (_) {
        // History is secondary.
      }

      if (!mounted) return;

      setState(() {
        _vehicles = vehicles;
        _transactions = transactions;

        if (_currentVehicleIndex >= _vehicles.length) {
          _currentVehicleIndex = _vehicles.isEmpty ? 0 : _vehicles.length - 1;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _api.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  String _fuelLabel(String type) {
    switch (type) {
      case 'petrol_92':
        return 'Petrol 92';
      case 'petrol_95':
        return 'Petrol 95';
      case 'diesel':
        return 'Diesel';
      default:
        return type;
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final local = value.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    final hour =
        local.hour == 0
            ? 12
            : local.hour > 12
            ? local.hour - 12
            : local.hour;

    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month  $hour:$minute $period';
  }

  Color _fuelColor(String fuelType) {
    switch (fuelType) {
      case 'petrol_92':
        return Colors.blue;
      case 'petrol_95':
        return Colors.purple;
      case 'diesel':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  double _quotaProgress(UserVehicle vehicle) {
    final total = vehicle.weeklyQuota;

    if (total <= 0) {
      return 0;
    }

    final used = total - vehicle.remaining;

    return (used / total).clamp(0.0, 1.0);
  }

  Future<void> _openClaimScreen() async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ClaimScreen()));

    if (changed == true) {
      await _loadDashboard();
    }
  }

  void _openVehicle(int index) {
    if (index < 0 || index >= _vehicles.length) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VehicleScreen(vehicle: _vehicles[index]),
      ),
    );
  }

  Widget _buildHomePage() {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F7FB),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: const Text(
          'Petro Manager',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 20),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildErrorCard()
            else ...[
              _buildSummaryCards(),
              const SizedBox(height: 24),
              _buildVehicleSection(),
              const SizedBox(height: 26),
              _buildRecentTransactions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.nationalId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final vehicleCount = _vehicles.length;
    final transactionCount = _transactions.length;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.directions_car_rounded,
            title: 'Vehicles',
            value: '$vehicleCount',
            subtitle: 'Registered',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.receipt_long_rounded,
            title: 'Transactions',
            value: '$transactionCount',
            subtitle: 'Recent records',
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Colors.redAccent,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load dashboard',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'My Vehicles',
          subtitle: '${_vehicles.length} registered',
          actionText: 'Register',
          onPressed: _openClaimScreen,
        ),
        const SizedBox(height: 12),

        if (_vehicles.isEmpty)
          _buildEmptyVehicleCard()
        else ...[
          SizedBox(
            height: 214,
            child: PageView.builder(
              controller: _vehiclePageController,
              itemCount: _vehicles.length,
              onPageChanged: (index) {
                setState(() {
                  _currentVehicleIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == _vehicles.length - 1 ? 0 : 12,
                  ),
                  child: _buildVehicleCard(_vehicles[index]),
                );
              },
            ),
          ),

          if (_vehicles.length > 1) ...[
            const SizedBox(height: 12),
            _buildVehicleIndicator(),
          ],
        ],
      ],
    );
  }

  Widget _buildVehicleIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_vehicles.length, (index) {
        final active = index == _currentVehicleIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 18 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color:
                active ? Theme.of(context).colorScheme.primary : Colors.black12,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_car_outlined,
              size: 34,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No vehicle registered',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Register your vehicle to start managing your fuel quota.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _openClaimScreen,
            icon: const Icon(Icons.add),
            label: const Text('Register Vehicle'),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(UserVehicle vehicle) {
    final progress = _quotaProgress(vehicle);
    final fuelColor = _fuelColor(vehicle.fuelType);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            final index = _vehicles.indexOf(vehicle);
            _openVehicle(index);
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: fuelColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.directions_car_filled_outlined,
                        color: fuelColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.plateNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${vehicle.vehicleType} • '
                            '${_fuelLabel(vehicle.fuelType)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.black38,
                    ),
                  ],
                ),

                const Spacer(),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Remaining Quota',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${vehicle.remaining.toStringAsFixed(2)} L',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.black.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(fuelColor),
                  ),
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% used',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${vehicle.weeklyQuota.toStringAsFixed(2)} L weekly',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final recent = _transactions.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Recent Transactions',
          subtitle:
              recent.isEmpty
                  ? 'No recent activity'
                  : '${_transactions.length} records',
          actionText: _transactions.isNotEmpty ? 'View All' : null,
          onPressed:
              _transactions.isNotEmpty
                  ? () {
                    setState(() {
                      _currentIndex = 2;
                    });
                  }
                  : null,
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          _buildEmptyTransactionCard()
        else
          ...recent.map(_buildTransactionCard),
      ],
    );
  }

  Widget _buildEmptyTransactionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Colors.black45,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No fuel transactions yet.',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(UserTransaction tx) {
    final fuelColor = _fuelColor(tx.fuelType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: fuelColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.local_gas_station_outlined, color: fuelColor),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.stationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tx.stationRegion,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    Text(
                      tx.plateNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Text(
                '${tx.amount.toStringAsFixed(0)} MMK',
                maxLines: 1,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.water_drop_outlined,
                        size: 17,
                        color: fuelColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${tx.liters.toStringAsFixed(2)} L',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _fuelLabel(tx.fuelType),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  _formatDate(tx.pumpedAt),
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomePage(),
          const AboutScreen(),
          const HistoryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'About',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onPressed;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
        ),
        if (actionText != null)
          TextButton(onPressed: onPressed, child: Text(actionText!)),
      ],
    );
  }
}
