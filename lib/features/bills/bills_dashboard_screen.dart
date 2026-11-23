import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models.dart';
import '../../data/repository_provider.dart';

class BillsDashboardScreen extends ConsumerStatefulWidget {
  const BillsDashboardScreen({super.key});

  @override
  ConsumerState<BillsDashboardScreen> createState() =>
      _BillsDashboardScreenState();
}

class _BillsDashboardScreenState extends ConsumerState<BillsDashboardScreen> {
  BillCategory? _selectedFilter; // null = All

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final allBills = repo.bills;

    final filteredBills = _selectedFilter == null
        ? allBills
        : allBills.where((b) => b.category == _selectedFilter).toList();

    final unpaidBills = allBills
        .where((b) => b.effectiveStatus == BillStatus.unpaid)
        .toList();
    final overdueBills = allBills
        .where((b) => b.effectiveStatus == BillStatus.overdue)
        .toList();
    final paidBills = allBills
        .where((b) => b.effectiveStatus == BillStatus.paid)
        .toList();
    final dueSoon = allBills.where((b) {
      if (b.effectiveStatus != BillStatus.unpaid) return false;
      return b.deadline.difference(DateTime.now()).inDays <= 7;
    }).toList();

    final totalUnpaidAmount = unpaidBills.fold<double>(
      0,
      (sum, b) => sum + (b.amount ?? 0),
    );

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Bills & Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Bill',
            onPressed: () async {
              await context.push('/add-bill');
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Summary Stats Row ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                CasamaSpacing.lg,
                CasamaSpacing.md,
                CasamaSpacing.lg,
                0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Unpaid',
                          value: '${unpaidBills.length}',
                          sub: 'bills',
                          color: CasamaColors.primaryCoral,
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Total Due',
                          value:
                              '₱${NumberFormat('#,##0.00').format(totalUnpaidAmount)}',
                          sub: 'unpaid amount',
                          color: CasamaColors.warningOrange,
                          icon: Icons.payments_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Due Soon',
                          value: '${dueSoon.length}',
                          sub: 'within 7 days',
                          color: const Color(0xFF1E88E5),
                          icon: Icons.calendar_today_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Paid',
                          value: '${paidBills.length}',
                          sub: 'bills settled',
                          color: CasamaColors.successGreen,
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                    ],
                  ),
                  if (overdueBills.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: CasamaColors.errorBg,
                          borderRadius: CasamaSpacing.roundedMd,
                          border: Border.all(
                            color: CasamaColors.errorRed.withAlpha(80),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: CasamaColors.errorRed,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${overdueBills.length} overdue bill${overdueBills.length > 1 ? 's' : ''} need attention!',
                                style: const TextStyle(
                                  color: CasamaColors.errorRed,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Category Filter Chips ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                CasamaSpacing.lg,
                CasamaSpacing.md,
                CasamaSpacing.lg,
                0,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _selectedFilter == null,
                      onTap: () => setState(() => _selectedFilter = null),
                    ),
                    const SizedBox(width: 8),
                    ...BillCategory.values.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: cat.label,
                          selected: _selectedFilter == cat,
                          onTap: () => setState(() => _selectedFilter = cat),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: CasamaSpacing.md)),

          // ── Bills List ─────────────────────────────────────
          filteredBills.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(CasamaSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: context.textMutedColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilter == null
                                ? 'No bills yet'
                                : 'No ${_selectedFilter!.label} bills',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to add your first household bill.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CasamaSpacing.lg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index == filteredBills.length) {
                        return const SizedBox(height: 90);
                      }
                      final bill = filteredBills[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: CasamaSpacing.md,
                        ),
                        child: _BillCard(bill: bill),
                      );
                    }, childCount: filteredBills.length + 1),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-bill'),
        backgroundColor: CasamaColors.primaryCoral,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Bill',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: CasamaSpacing.roundedLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
          Text(
            sub,
            style: TextStyle(fontSize: 11, color: context.textMutedColor),
          ),
        ],
      ),
    );
  }
}

// ── Filter Chip ────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? CasamaColors.primaryCoral : context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? CasamaColors.primaryCoral : context.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : context.textSecondaryColor,
          ),
        ),
      ),
    );
  }
}

// ── Bill Card ──────────────────────────────────────────────
class _BillCard extends ConsumerWidget {
  final HouseholdBill bill;

  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveStatus = bill.effectiveStatus;
    final dateStr = DateFormat('MMM dd, yyyy').format(bill.deadline);

    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    switch (effectiveStatus) {
      case BillStatus.paid:
        statusColor = CasamaColors.successGreen;
        statusBg = CasamaColors.successBg;
        statusIcon = Icons.check_circle_outline;
        break;
      case BillStatus.overdue:
        statusColor = CasamaColors.errorRed;
        statusBg = CasamaColors.errorBg;
        statusIcon = Icons.error_outline;
        break;
      case BillStatus.unpaid:
        statusColor = CasamaColors.warningOrange;
        statusBg = CasamaColors.warningBg;
        statusIcon = Icons.access_time_outlined;
    }

    return Material(
      color: context.cardColor,
      borderRadius: CasamaSpacing.roundedLg,
      child: InkWell(
        borderRadius: CasamaSpacing.roundedLg,
        onTap: () => context.push('/bill-detail?id=${bill.id}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: CasamaSpacing.roundedLg,
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row: Category icon + name + status badge
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _categoryBgColor(bill.category, context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        bill.category.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.effectiveBillName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: context.textColor,
                          ),
                        ),
                        Text(
                          bill.effectiveCategoryLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textMutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          effectiveStatus.label,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ── Bottom Row: Amount + deadline + member
              Row(
                children: [
                  if (bill.amount != null) ...[
                    Icon(
                      Icons.payments_outlined,
                      size: 14,
                      color: context.textMutedColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '₱${NumberFormat('#,##0.00').format(bill.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: context.textMutedColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondaryColor,
                    ),
                  ),
                  const Spacer(),
                  if (bill.responsibleMember != null)
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: context.textMutedColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          bill.responsibleMember!,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textMutedColor,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (bill.reminderEnabled) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 13,
                      color: CasamaColors.deepTeal,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Reminder: ${bill.reminderTiming.label}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: CasamaColors.deepTeal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _categoryBgColor(BillCategory cat, BuildContext context) {
    if (context.isDark) {
      switch (cat) {
        case BillCategory.electricity:
          return const Color(0xFF332B1A);
        case BillCategory.water:
          return const Color(0xFF19322F);
        case BillCategory.internet:
          return const Color(0xFF1A2B3D);
        case BillCategory.appliance:
          return const Color(0xFF2A1E3D);
        case BillCategory.rent:
          return const Color(0xFF332025);
        default:
          return const Color(0xFF1E2F4A);
      }
    }
    switch (cat) {
      case BillCategory.electricity:
        return const Color(0xFFFFF3E0);
      case BillCategory.water:
        return const Color(0xFFE3F2FD);
      case BillCategory.internet:
        return const Color(0xFFE8F5E9);
      case BillCategory.appliance:
        return const Color(0xFFF3E5F5);
      case BillCategory.rent:
        return const Color(0xFFFFECE8);
      default:
        return const Color(0xFFF3F5F4);
    }
  }
}
