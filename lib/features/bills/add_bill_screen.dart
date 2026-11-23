import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models.dart';
import '../../data/repository_provider.dart';

class AddBillScreen extends ConsumerStatefulWidget {
  const AddBillScreen({super.key});

  @override
  ConsumerState<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends ConsumerState<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _billNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _customCategoryCtrl = TextEditingController();

  BillCategory _selectedCategory = BillCategory.electricity;
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  bool _reminderEnabled = true;
  ReminderTiming _reminderTiming = ReminderTiming.oneDayBefore;
  BillRecipientType _recipientType = BillRecipientType.allMembers;
  String? _responsibleMember;
  bool _showMoreCategories = false;
  bool _isSaving = false;

  final List<BillCategory> _primaryCategories = [
    BillCategory.electricity,
    BillCategory.water,
    BillCategory.internet,
    BillCategory.appliance,
  ];

  final List<BillCategory> _moreCategories = [
    BillCategory.rent,
    BillCategory.associationDues,
    BillCategory.gas,
    BillCategory.maintenanceFee,
    BillCategory.other,
  ];

  @override
  void dispose() {
    _billNameCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _customCategoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final members = repo.members;

    // Build unique, clean list of selectable member names
    final memberOptions = members
        .map((m) {
          if (m.profile.id == repo.currentUser.id ||
              m.profile.displayName == 'You') {
            return repo.currentUser.displayName;
          }
          return m.profile.displayName;
        })
        .toSet()
        .toList();

    if (memberOptions.isEmpty) {
      memberOptions.add(repo.currentUser.displayName);
    }

    if (_responsibleMember == null ||
        !memberOptions.contains(_responsibleMember)) {
      _responsibleMember = memberOptions.first;
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Add Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/dashboard'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(CasamaSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Illustration Header ───────────────────────
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      _BillIllustration(),
                      const SizedBox(height: 14),
                      Text(
                        'Add a New Bill',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep track of your household bills\nand never miss a deadline!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondaryColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Bill Type ─────────────────────────────────
              _SectionLabel(label: 'Bill Type'),
              const SizedBox(height: 10),
              Row(
                children: [
                  ..._primaryCategories.map((cat) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _CategoryTile(
                          category: cat,
                          selected:
                              _selectedCategory == cat && !_showMoreCategories,
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                              _showMoreCategories = false;
                            });
                          },
                        ),
                      ),
                    );
                  }),
                  Expanded(
                    child: _CategoryMoreTile(
                      selected: _showMoreCategories,
                      onTap: () {
                        setState(() {
                          _showMoreCategories = !_showMoreCategories;
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (_showMoreCategories) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _moreCategories.map((cat) {
                    return _CategoryPill(
                      category: cat,
                      selected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    );
                  }).toList(),
                ),
              ],
              // Custom category input when "Other" is selected
              if (_selectedCategory == BillCategory.other) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customCategoryCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Cable Subscription, Parking Fee…',
                    labelText: 'Custom Category',
                    filled: true,
                    fillColor: context.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: CasamaSpacing.roundedMd,
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: CasamaSpacing.roundedMd,
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // ── Bill Name ─────────────────────────────────
              _SectionLabel(label: 'Bill Name (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _billNameCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Meralco Bill',
                  filled: true,
                  fillColor: context.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: CasamaSpacing.roundedMd,
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: CasamaSpacing.roundedMd,
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Amount ────────────────────────────────────
              _SectionLabel(label: 'Amount (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  prefixText: '₱  ',
                  prefixStyle: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: context.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: CasamaSpacing.roundedMd,
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: CasamaSpacing.roundedMd,
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Deadline Date ─────────────────────────────
              _SectionLabel(label: 'Deadline Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: CasamaSpacing.roundedMd,
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: CasamaColors.primaryCoral,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(_deadline),
                          style: TextStyle(
                            fontSize: 15,
                            color: context.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: context.textMutedColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Responsible Member ────────────────────────
              _SectionLabel(label: 'Responsible Member'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: CasamaSpacing.roundedMd,
                  border: Border.all(color: context.borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _responsibleMember,
                    isExpanded: true,
                    dropdownColor: context.cardColor,
                    style: TextStyle(color: context.textColor, fontSize: 15),
                    items: memberOptions.map((name) {
                      final label = name == repo.currentUser.displayName
                          ? 'You ($name)'
                          : name;
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _responsibleMember = val),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Notes ─────────────────────────────────────
              _SectionLabel(label: 'Notes (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Any extra details…',
                  filled: true,
                  fillColor: context.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: CasamaSpacing.roundedMd,
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: CasamaSpacing.roundedMd,
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Set Reminder ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _reminderEnabled
                      ? CasamaColors.primaryCoral.withAlpha(18)
                      : context.cardColor,
                  borderRadius: CasamaSpacing.roundedLg,
                  border: Border.all(
                    color: _reminderEnabled
                        ? CasamaColors.primaryCoral.withAlpha(60)
                        : context.borderColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                'Set Reminder',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: context.textColor,
                                ),
                              ),
                              Text(
                                'Get notified before your bill is due.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _reminderEnabled,
                          onChanged: (val) =>
                              setState(() => _reminderEnabled = val),
                          activeThumbColor: CasamaColors.primaryCoral,
                          activeTrackColor: CasamaColors.primaryCoral.withAlpha(
                            120,
                          ),
                        ),
                      ],
                    ),
                    if (_reminderEnabled) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            'Notify me',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: CasamaSpacing.roundedMd,
                                border: Border.all(color: context.borderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<ReminderTiming>(
                                  value: _reminderTiming,
                                  isExpanded: true,
                                  dropdownColor: context.cardColor,
                                  style: TextStyle(
                                    color: context.textColor,
                                    fontSize: 13,
                                  ),
                                  items: ReminderTiming.values
                                      .map(
                                        (t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(t.label),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _reminderTiming = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Notify:',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...BillRecipientType.values.map((type) {
                        final selected = _recipientType == type;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: GestureDetector(
                            onTap: () => setState(() => _recipientType = type),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selected
                                          ? CasamaColors.primaryCoral
                                          : context.borderColor,
                                      width: 2,
                                    ),
                                    color: selected
                                        ? CasamaColors.primaryCoral
                                        : Colors.transparent,
                                  ),
                                  child: selected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 12,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  type.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.textColor,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Save Bill Button ──────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveBill,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CasamaColors.primaryCoral,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: CasamaSpacing.roundedLg,
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Save Bill',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme
                .copyWith(primary: CasamaColors.primaryCoral),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _saveBill() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 300));

    final amount = double.tryParse(_amountCtrl.text.trim());
    final customLabel = _selectedCategory == BillCategory.other
        ? _customCategoryCtrl.text.trim()
        : null;

    ref
        .read(repositoryProvider)
        .addBill(
          category: _selectedCategory,
          customCategoryLabel: customLabel,
          billName: _billNameCtrl.text.trim().isEmpty
              ? null
              : _billNameCtrl.text.trim(),
          amount: amount,
          deadline: _deadline,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          reminderEnabled: _reminderEnabled,
          reminderTiming: _reminderTiming,
          recipientType: _recipientType,
          responsibleMember: _responsibleMember,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Bill saved successfully!'),
          ],
        ),
        backgroundColor: CasamaColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    context.pop();
  }
}

// ── Illustration ───────────────────────────────────────────
class _BillIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 110,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Pink blob background
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            bottom: 10,
            child: Container(
              decoration: BoxDecoration(
                color: CasamaColors.primaryCoral.withAlpha(26),
                borderRadius: BorderRadius.circular(60),
              ),
            ),
          ),
          // Calendar icon (bottom-left)
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: CasamaColors.primaryCoral.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: CasamaColors.primaryCoral,
                size: 20,
              ),
            ),
          ),
          // Peso coin (bottom-right)
          Positioned(
            bottom: 0,
            right: 4,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: CasamaColors.warmGold.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '₱',
                  style: TextStyle(
                    color: CasamaColors.warningOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
          // Receipt (center)
          Positioned.fill(
            child: Center(
              child: Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.bolt,
                      color: CasamaColors.primaryCoral,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    ...List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: CasamaColors.borderGray,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Tile ──────────────────────────────────────────
class _CategoryTile extends StatelessWidget {
  final BillCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? CasamaColors.primaryCoral.withAlpha(26)
              : context.cardColor,
          borderRadius: CasamaSpacing.roundedMd,
          border: Border.all(
            color: selected ? CasamaColors.primaryCoral : context.borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected
                    ? CasamaColors.primaryCoral
                    : context.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── More Tile ──────────────────────────────────────────────
class _CategoryMoreTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _CategoryMoreTile({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? CasamaColors.deepTeal.withAlpha(26)
              : context.cardColor,
          borderRadius: CasamaSpacing.roundedMd,
          border: Border.all(
            color: selected ? CasamaColors.deepTeal : context.borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.more_horiz,
              color: selected
                  ? CasamaColors.deepTeal
                  : context.textSecondaryColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              'More',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected
                    ? CasamaColors.deepTeal
                    : context.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Pill (for expanded More section) ──────────────
class _CategoryPill extends StatelessWidget {
  final BillCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? CasamaColors.primaryCoral : context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? CasamaColors.primaryCoral : context.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : context.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Label ──────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: context.textColor,
      ),
    );
  }
}
