import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models.dart';
import '../../data/repository_provider.dart';

class BillDetailScreen extends ConsumerWidget {
  final String billId;
  const BillDetailScreen({super.key, required this.billId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    final bill = repo.bills.cast<HouseholdBill?>().firstWhere(
      (b) => b?.id == billId,
      orElse: () => null,
    );

    if (bill == null) {
      return Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: AppBar(title: const Text('Bill Details')),
        body: Center(
          child: Text(
            'Bill not found.',
            style: TextStyle(color: context.textSecondaryColor),
          ),
        ),
      );
    }

    final effectiveStatus = bill.effectiveStatus;
    final isCreator = bill.creatorId == repo.currentUser.id;
    final isPaid = effectiveStatus == BillStatus.paid;

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

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Bill Details'),
        actions: [
          if (isCreator)
            PopupMenuButton<String>(
              onSelected: (value) =>
                  _handleMenuAction(context, ref, value, bill),
              itemBuilder: (_) => [
                if (isPaid)
                  const PopupMenuItem(
                    value: 'reopen',
                    child: Row(
                      children: [
                        Icon(Icons.undo, size: 18),
                        SizedBox(width: 10),
                        Text('Reopen Bill'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(CasamaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Card ───────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: CasamaSpacing.roundedLg,
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: CasamaColors.primaryCoral.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        bill.category.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bill.effectiveBillName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bill.effectiveCategoryLabel,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textMutedColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          effectiveStatus.label,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Details ───────────────────────────────────
            _DetailCard(
              children: [
                if (bill.amount != null)
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Amount',
                    value: '₱${NumberFormat('#,##0.00').format(bill.amount)}',
                    valueStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: CasamaColors.primaryCoral,
                    ),
                  ),
                _DetailRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Deadline',
                  value: DateFormat('MMMM dd, yyyy').format(bill.deadline),
                ),
                if (bill.responsibleMember != null)
                  _DetailRow(
                    icon: Icons.person_outline,
                    label: 'Responsible',
                    value: bill.responsibleMember!,
                  ),
                _DetailRow(
                  icon: Icons.person_outlined,
                  label: 'Created By',
                  value: bill.creatorName,
                ),
                _DetailRow(
                  icon: Icons.access_time_outlined,
                  label: 'Created',
                  value: DateFormat('MMM dd, yyyy').format(bill.createdAt),
                ),
                if (isPaid && bill.paidAt != null) ...[
                  _DetailRow(
                    icon: Icons.check_circle_outline,
                    label: 'Paid On',
                    value: DateFormat('MMM dd, yyyy').format(bill.paidAt!),
                  ),
                  if (bill.paidByName != null)
                    _DetailRow(
                      icon: Icons.how_to_reg_outlined,
                      label: 'Paid By',
                      value: bill.paidByName!,
                    ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── Reminder ──────────────────────────────────
            if (bill.reminderEnabled) ...[
              _DetailCard(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: CasamaColors.primaryCoral.withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: CasamaColors.primaryCoral,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reminder Active',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: context.textColor,
                              ),
                            ),
                            Text(
                              bill.reminderTiming.label,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.textSecondaryColor,
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
                          color: CasamaColors.successBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ON',
                          style: TextStyle(
                            color: CasamaColors.successGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.group_outlined,
                    label: 'Recipients',
                    value: bill.recipientType.label,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ── Notes ─────────────────────────────────────
            if (bill.notes != null && bill.notes!.isNotEmpty) ...[
              _DetailCard(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notes_outlined,
                        size: 18,
                        color: context.textMutedColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: context.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bill.notes!,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textSecondaryColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ── Actions ───────────────────────────────────
            if (!isPaid) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmMarkPaid(context, ref, bill),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CasamaColors.successGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: CasamaSpacing.roundedLg,
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Mark as Paid',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (isPaid && isCreator) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(repositoryProvider).reopenBill(bill.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bill reopened.')),
                    );
                    context.pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CasamaColors.warningOrange,
                    side: const BorderSide(color: CasamaColors.warningOrange),
                    shape: RoundedRectangleBorder(
                      borderRadius: CasamaSpacing.roundedLg,
                    ),
                  ),
                  icon: const Icon(Icons.undo),
                  label: const Text('Reopen Bill'),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    HouseholdBill bill,
  ) {
    if (action == 'reopen') {
      ref.read(repositoryProvider).reopenBill(bill.id);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bill reopened.')));
      context.pop();
    } else if (action == 'delete') {
      _confirmDelete(context, ref, bill);
    }
  }

  void _confirmMarkPaid(
    BuildContext context,
    WidgetRef ref,
    HouseholdBill bill,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Paid?'),
        content: Text(
          'Mark "${bill.effectiveBillName}" as paid?\n\nThis awards +5 Kasama Points!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(repositoryProvider).markBillPaid(bill.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.star, color: Colors.white),
                      SizedBox(width: 10),
                      Text('Bill paid! +5 Kasama Points 🎉'),
                    ],
                  ),
                  backgroundColor: CasamaColors.successGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CasamaColors.successGreen,
            ),
            child: const Text(
              'Mark Paid',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, HouseholdBill bill) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bill?'),
        content: Text(
          'Are you sure you want to delete "${bill.effectiveBillName}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(repositoryProvider).deleteBill(bill.id);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Bill deleted.')));
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CasamaColors.errorRed,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Detail Card ────────────────────────────────────────────
class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: CasamaSpacing.roundedLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ── Detail Row ─────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.textMutedColor),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style:
                  valueStyle ??
                  TextStyle(
                    fontSize: 14,
                    color: context.textColor,
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
