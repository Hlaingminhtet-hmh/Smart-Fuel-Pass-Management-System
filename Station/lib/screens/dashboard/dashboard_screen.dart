import 'package:flutter/material.dart';
import 'package:smart_fuel_station/models/fuel_price.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/station_report.dart';
import '../../models/station_session.dart';
import '../qr_scanner/qr_scanner_screen.dart';
import '../transaction_history/transaction_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  final StationSession session;

  const DashboardScreen({super.key, required this.session});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiClient _api = const ApiClient();

  late Future<StationReport> _todayFuture;
  late Future<List<FuelPrice>> _fuelPricesFuture;

  @override
  void initState() {
    super.initState();

    _todayFuture = _loadToday();
    _fuelPricesFuture = _loadFuelPrices();
  }

  Future<StationReport> _loadToday() {
    return _api.getStationReport(days: 1);
  }

  Future<List<FuelPrice>> _loadFuelPrices() async {
    return Future.wait([
      _api.getCurrentFuelPrice('petrol_92'),
      _api.getCurrentFuelPrice('petrol_95'),
      _api.getCurrentFuelPrice('diesel'),
    ]);
  }

  Future<void> _refresh() async {
    setState(() {
      _todayFuture = _loadToday();
      _fuelPricesFuture = _loadFuelPrices();
    });

    await Future.wait([_todayFuture, _fuelPricesFuture]);
  }

  void _openScanner() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const QrScannerScreen()));
  }

  void _openHistory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()));
  }

  Future<void> _logout() async {
    await _api.logout();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      // ======================================================
      // APP BAR
      // ======================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,

        title: const Text(
          'Petro Manager',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.text),
        ),

        actions: [
          IconButton(
            tooltip: 'Transactions',
            onPressed: _openHistory,
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ======================================================
      // BODY
      // ======================================================
      body: SafeArea(
        child: FutureBuilder<StationReport>(
          future: _todayFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              final message =
                  snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'Could not load station statistics.';

              return _ErrorBody(message: message, onRetry: _refresh);
            }

            if (!snapshot.hasData) {
              return _ErrorBody(
                message: 'No station data available.',
                onRetry: _refresh,
              );
            }

            final report = snapshot.data!;

            return FutureBuilder<List<FuelPrice>>(
              future: _fuelPricesFuture,
              builder: (context, priceSnapshot) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: _DashboardContent(
                    session: widget.session,
                    report: report,
                    priceSnapshot: priceSnapshot,
                    onHistory: _openHistory,
                  ),
                );
              },
            );
          },
        ),
      ),

      // ======================================================
      // CENTER QR SCAN BUTTON
      // ======================================================
      floatingActionButton: FloatingActionButton.large(
        onPressed: _openScanner,
        elevation: 5,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        tooltip: 'Scan Vehicle QR',
        child: const Icon(Icons.qr_code_scanner_rounded, size: 34),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ======================================================
      // BOTTOM NAVIGATION
      // ======================================================
      bottomNavigationBar: BottomAppBar(
        height: 68,
        padding: EdgeInsets.zero,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 8,
        shape: const CircularNotchedRectangle(),
        notchMargin: 7,

        child: Row(
          children: [
            // ------------------------------------------------
            // HOME
            // ------------------------------------------------
            Expanded(
              child: Center(
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(
                    width: 70,
                    height: 58,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_rounded,
                          size: 23,
                          color: AppTheme.primary,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Home',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ------------------------------------------------
            // SPACE FOR FAB
            // ------------------------------------------------
            const SizedBox(width: 90),

            // ------------------------------------------------
            // HISTORY
            // ------------------------------------------------
            Expanded(
              child: Center(
                child: InkWell(
                  onTap: _openHistory,
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(
                    width: 70,
                    height: 58,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 23,
                          color: Colors.black54,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'History',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DASHBOARD CONTENT
// ============================================================

class _DashboardContent extends StatelessWidget {
  final StationSession session;
  final StationReport report;
  final AsyncSnapshot<List<FuelPrice>> priceSnapshot;
  final VoidCallback onHistory;

  const _DashboardContent({
    required this.session,
    required this.report,
    required this.priceSnapshot,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final recent = report.transactions.take(5).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),

      children: [
        // ====================================================
        // WELCOME SECTION
        // ====================================================
        const Text(
          'Welcome back',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          session.stationName.isEmpty
              ? 'Station Operator'
              : session.stationName,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: AppTheme.text,
          ),
        ),

        const SizedBox(height: 7),

        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                '${session.regionZone ?? 'Assigned station'} • ${session.operatorCode}',
                style: const TextStyle(
                  color: AppTheme.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 26),

        // ====================================================
        // FUEL PRICES
        // ====================================================
        _FuelPricesSection(snapshot: priceSnapshot),

        const SizedBox(height: 28),

        // ====================================================
        // TODAY'S OVERVIEW
        // ====================================================
        const Text(
          "Today's Overview",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.text,
          ),
        ),

        const SizedBox(height: 12),

        _OverviewGrid(report: report),

        const SizedBox(height: 28),

        // ====================================================
        // RECENT TRANSACTIONS HEADER
        // ====================================================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.text,
              ),
            ),
            TextButton(
              onPressed: onHistory,
              child: const Text(
                'View All',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ====================================================
        // RECENT TRANSACTIONS
        // ====================================================
        if (recent.isEmpty)
          const _EmptyTransactionsCard()
        else
          ...recent.map(
            (tx) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecentTransactionCard(transaction: tx),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// FUEL PRICE SECTION
// ============================================================

class _FuelPricesSection extends StatelessWidget {
  final AsyncSnapshot<List<FuelPrice>> snapshot;

  const _FuelPricesSection({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Fuel Prices',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.text,
          ),
        ),

        const SizedBox(height: 4),

        const Text(
          "Today's price per liter",
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),

        const SizedBox(height: 14),

        if (snapshot.connectionState == ConnectionState.waiting)
          const _FuelPriceLoading()
        else if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.length < 3)
          const _FuelPriceError()
        else
          _FuelPriceCards(prices: snapshot.data!),
      ],
    );
  }
}

// ============================================================
// FUEL PRICE CARDS
// ============================================================

class _FuelPriceCards extends StatelessWidget {
  final List<FuelPrice> prices;

  const _FuelPriceCards({required this.prices});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              _FuelPriceCard(
                title: 'Petrol 92',
                subtitle: 'Regular',
                price: prices[0],
                icon: Icons.local_gas_station_rounded,
              ),
              const SizedBox(height: 10),
              _FuelPriceCard(
                title: 'Petrol 95',
                subtitle: 'Premium',
                price: prices[1],
                icon: Icons.local_gas_station_rounded,
              ),
              const SizedBox(height: 10),
              _FuelPriceCard(
                title: 'Diesel',
                subtitle: 'Diesel',
                price: prices[2],
                icon: Icons.local_shipping_rounded,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _FuelPriceCard(
                title: 'Petrol 92',
                subtitle: 'Regular',
                price: prices[0],
                icon: Icons.local_gas_station_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FuelPriceCard(
                title: 'Petrol 95',
                subtitle: 'Premium',
                price: prices[1],
                icon: Icons.local_gas_station_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FuelPriceCard(
                title: 'Diesel',
                subtitle: 'Diesel',
                price: prices[2],
                icon: Icons.local_shipping_rounded,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// SINGLE FUEL PRICE CARD
// ============================================================

class _FuelPriceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final FuelPrice price;
  final IconData icon;

  const _FuelPriceCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,

      child: Padding(
        padding: const EdgeInsets.all(15),

        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,

              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(13),
              ),

              child: Icon(icon, color: AppTheme.primary, size: 24),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.text,
                    ),
                  ),

                  const SizedBox(height: 1),

                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black45, fontSize: 11),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '${price.pricePerLiter.toStringAsFixed(0)} ${price.currency}/L',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FUEL PRICE LOADING
// ============================================================

class _FuelPriceLoading extends StatelessWidget {
  const _FuelPriceLoading();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: const [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Loading fuel prices...',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FUEL PRICE ERROR
// ============================================================

class _FuelPriceError extends StatelessWidget {
  const _FuelPriceError();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppTheme.danger),
            SizedBox(width: 12),
            Expanded(child: Text('Fuel prices are currently unavailable.')),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// OVERVIEW GRID
// ============================================================

class _OverviewGrid extends StatelessWidget {
  final StationReport report;

  const _OverviewGrid({required this.report});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 500) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Transactions',
                      value: report.totalTransactions.toString(),
                      icon: Icons.receipt_long_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: 'Fuel Distributed',
                      value: '${report.totalLiters.toStringAsFixed(1)} L',
                      icon: Icons.local_gas_station_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Vehicles',
                      value: report.uniqueVehicles.toString(),
                      icon: Icons.directions_car_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: 'Avg. Fueling',
                      value: '${report.averageLiters.toStringAsFixed(1)} L',
                      icon: Icons.speed_outlined,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Transactions',
                value: report.totalTransactions.toString(),
                icon: Icons.receipt_long_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                title: 'Fuel Distributed',
                value: '${report.totalLiters.toStringAsFixed(1)} L',
                icon: Icons.local_gas_station_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                title: 'Vehicles',
                value: report.uniqueVehicles.toString(),
                icon: Icons.directions_car_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                title: 'Avg. Fueling',
                value: '${report.averageLiters.toStringAsFixed(1)} L',
                icon: Icons.speed_outlined,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// STAT CARD
// ============================================================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,

              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),

              child: Icon(icon, color: AppTheme.primary, size: 21),
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
                    style: const TextStyle(color: Colors.black54, fontSize: 11),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// RECENT TRANSACTION
// ============================================================

class _RecentTransactionCard extends StatelessWidget {
  final dynamic transaction;

  const _RecentTransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),

        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEAF3FB),
          child: Icon(
            Icons.local_gas_station_outlined,
            color: AppTheme.primary,
          ),
        ),

        title: Text(
          transaction.plateNumber.isEmpty
              ? 'Vehicle #${transaction.vehicleId}'
              : transaction.plateNumber,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),

        subtitle: Text(_format(transaction.pumpedAt)),

        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${transaction.litersPumped.toStringAsFixed(2)} L',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 2),

            Text(
              '${transaction.amountPaid.toStringAsFixed(0)} MMK',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(DateTime? value) {
    if (value == null) {
      return 'Unknown time';
    }

    final local = value.toLocal();

    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(local.hour)}:${two(local.minute)}';
  }
}

// ============================================================
// EMPTY TRANSACTIONS
// ============================================================

class _EmptyTransactionsCard extends StatelessWidget {
  const _EmptyTransactionsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,

      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 24),

        child: Column(
          children: const [
            Icon(Icons.receipt_long_outlined, size: 42, color: Colors.black38),

            SizedBox(height: 12),

            Text(
              'No transactions yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),

            SizedBox(height: 6),

            Text(
              'Completed fueling transactions will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ERROR BODY
// ============================================================

class _ErrorBody extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppTheme.danger,
            ),

            const SizedBox(height: 14),

            Text(message, textAlign: TextAlign.center),

            const SizedBox(height: 18),

            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
