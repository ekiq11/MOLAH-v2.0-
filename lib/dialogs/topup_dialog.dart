import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/payment_confirmation.dart';
import '../utils/currency_formater.dart';

class TopUpDialog {
  static Future<void> show({
    required BuildContext context,
    required String currentBalance,
    required String nisn,
    required String namaSantri,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => _TopUpSheet(
        currentBalance: currentBalance,
        nisn: nisn,
        namaSantri: namaSantri,
      ),
    );
  }
}

class _TopUpSheet extends StatefulWidget {
  final String currentBalance;
  final String nisn;
  final String namaSantri;

  const _TopUpSheet({
    required this.currentBalance,
    required this.nisn,
    required this.namaSantri,
  });

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet>
    with SingleTickerProviderStateMixin {
  static const List<int> _quickAmounts = [
    10000, 25000, 50000, 75000,
    100000, 150000, 200000, 500000,
  ];

  int? _selectedAmount;
  bool _isCustom = false;
  final TextEditingController _customCtrl = TextEditingController();
  final FocusNode _customFocus = FocusNode();
  late AnimationController _animCtrl;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _customCtrl.dispose();
    _customFocus.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (_isCustom) {
      final v = int.tryParse(_customCtrl.text.replaceAll('.', '')) ?? 0;
      return v >= 5000 && v <= 10000000;
    }
    return _selectedAmount != null;
  }

  int get _finalAmount {
    if (_isCustom) {
      return int.tryParse(_customCtrl.text.replaceAll('.', '')) ?? 0;
    }
    return _selectedAmount ?? 0;
  }

  void _onQuickTap(int amount) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedAmount = amount;
      _isCustom = false;
      _customCtrl.clear();
    });
    _customFocus.unfocus();
  }

  void _onCustomTap() {
    setState(() {
      _isCustom = true;
      _selectedAmount = null;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _customFocus.requestFocus();
    });
  }

  void _proceed() {
    if (!_isValid) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: PaymentConfirmationScreen(
            amount: _finalAmount.toString(),
            nisn: widget.nisn,
            namaSantri: widget.namaSantri,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (_, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: child,
      ),
      child: GestureDetector(
        onTap: () => _customFocus.unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 0,
            bottom: mq.viewInsets.bottom + mq.padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              _buildHeader(),
              const SizedBox(height: 20),

              // Balance chip
              _buildBalanceChip(),
              const SizedBox(height: 24),

              // Quick amounts
              _buildQuickAmountsSection(),
              const SizedBox(height: 16),

              // Custom input
              _buildCustomInput(),
              const SizedBox(height: 24),

              // CTA Button
              _buildCTAButton(),
              const SizedBox(height: 8),
              Text(
                'Pembayaran diverifikasi dalam 1×24 jam kerja',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add_card_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top Up Saldo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                widget.namaSantri,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF6B7280)),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceChip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6EE7B7), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded,
              color: Color(0xFF059669), size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo Aktif',
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF059669).withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${widget.currentBalance}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'NISN: ${widget.nisn}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF065F46),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Nominal',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.2,
          ),
          itemCount: _quickAmounts.length,
          itemBuilder: (_, i) => _buildAmountChip(_quickAmounts[i]),
        ),
      ],
    );
  }

  Widget _buildAmountChip(int amount) {
    final isSelected = _selectedAmount == amount && !_isCustom;
    return GestureDetector(
      onTap: () => _onQuickTap(amount),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ],
        ),
        child: Center(
          child: Text(
            _formatShort(amount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }

  String _formatShort(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)}jt';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}rb';
    return amount.toString();
  }

  Widget _buildCustomInput() {
    return GestureDetector(
      onTap: _onCustomTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isCustom ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
            width: _isCustom ? 1.5 : 1,
          ),
          boxShadow: _isCustom
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ],
        ),
        child: Row(
          children: [
            Text(
              'Rp',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isCustom ? const Color(0xFF10B981) : Colors.grey[400],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _customCtrl,
                focusNode: _customFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [_ThousandSeparatorFormatter()],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  hintText: 'Nominal lainnya (min. Rp 5.000)',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onTap: _onCustomTap,
                onChanged: (v) => setState(() {}),
              ),
            ),
            if (_isCustom && _customCtrl.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _customCtrl.clear();
                  setState(() {});
                },
                child: Icon(Icons.cancel_rounded, color: Colors.grey[300], size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTAButton() {
    final valid = _isValid;
    return AnimatedOpacity(
      opacity: valid ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: valid ? _proceed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF10B981),
            elevation: valid ? 4 : 0,
            shadowColor: const Color(0xFF10B981).withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (valid) ...[
                const Icon(Icons.arrow_forward_rounded, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                valid
                    ? 'Lanjut  •  Rp ${CurrencyFormatter.format(_finalAmount.toString())}'
                    : 'Pilih Nominal Terlebih Dahulu',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Formatter ribuan untuk custom input
// ─────────────────────────────────────────────────────────────
class _ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final clean = newValue.text.replaceAll('.', '').replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isEmpty) return newValue.copyWith(text: '');
    final number = int.tryParse(clean) ?? 0;
    final formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
