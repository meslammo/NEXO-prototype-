import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';
import '../models/trade_models.dart';
import '../services/escrow_service.dart';

/// شاشة حل النزاع (محاكاة لوحة الدعم)
class DisputeResolutionScreen extends StatefulWidget {
  final Trade trade;

  const DisputeResolutionScreen({super.key, required this.trade});

  @override
  State<DisputeResolutionScreen> createState() => _DisputeResolutionScreenState();
}

class _DisputeResolutionScreenState extends State<DisputeResolutionScreen> {
  final _escrow = EscrowService.instance;
  late Trade _trade;
  DisputeResolution? _selected;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _trade = widget.trade;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _resolve() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختار طريقة الحل أولاً')),
      );
      return;
    }
    try {
      final updated = _escrow.resolveDispute(
        tradeId: _trade.id,
        resolution: _selected!,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      setState(() => _trade = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حل النزاع بنجاح: ${_selected!.labelAr}'),
          backgroundColor: NexoColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isResolved = _trade.status == TradeStatus.resolved;

    return Scaffold(
      backgroundColor: NexoColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context, _trade),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                  const Expanded(
                    child: Text(
                      'حل النزاع',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dispute info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.gavel, color: Colors.orange, size: 22),
                              SizedBox(width: 8),
                              Text('تفاصيل النزاع', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('رقم الصفقة: ${_trade.id}', style: const TextStyle(color: NexoColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text('من: ${_trade.fromUserName}  ↔  إلى: ${_trade.toUserName}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          const Text('سبب النزاع:', style: TextStyle(color: NexoColors.textSecondary, fontSize: 12)),
                          Text(_trade.disputeReason ?? '—', style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (isResolved) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: NexoColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: NexoColors.success.withOpacity(0.4)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle, color: NexoColors.success, size: 40),
                            const SizedBox(height: 10),
                            const Text('تم حل النزاع بنجاح', style: TextStyle(color: NexoColors.success, fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text(
                              _trade.resolution?.labelAr ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                            ),
                            if (_trade.resolutionNote != null) ...[
                              const SizedBox(height: 6),
                              Text(_trade.resolutionNote!, style: const TextStyle(color: NexoColors.textSecondary, fontSize: 13)),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      const Text('اختر طريقة الحل:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      ...DisputeResolution.values.map((r) {
                        final selected = _selected == r;
                        return GestureDetector(
                          onTap: () => setState(() => _selected = r),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: selected ? NexoColors.primary.withOpacity(0.2) : NexoColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? NexoColors.primary : NexoColors.cardBorder,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: selected ? NexoColors.primary : NexoColors.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(r.labelAr, style: TextStyle(
                                    color: selected ? Colors.white : NexoColors.textSecondary,
                                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                  )),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'ملاحظة الحل (اختياري)...',
                          hintStyle: const TextStyle(color: NexoColors.textSecondary),
                          filled: true,
                          fillColor: NexoColors.card,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _resolve,
                          icon: const Icon(Icons.check_circle, color: Colors.white),
                          label: const Text('تأكيد حل النزاع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NexoColors.success,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Tips for successful resolution
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: NexoColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: NexoColors.cardBorder),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('كيف تحل النزاع بنجاح؟', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          SizedBox(height: 10),
                          Text('1. راجع سبب النزاع وسجل الصفقة', style: TextStyle(color: NexoColors.textSecondary, fontSize: 13)),
                          Text('2. تأكد من العناصر المحجوزة عند الطرفين', style: TextStyle(color: NexoColors.textSecondary, fontSize: 13)),
                          Text('3. اختار الحل العادل (إرجاع / لصالح طرف / إكمال)', style: TextStyle(color: NexoColors.textSecondary, fontSize: 13)),
                          Text('4. اكتب ملاحظة واضحة للطرفين', style: TextStyle(color: NexoColors.textSecondary, fontSize: 13)),
                          Text('5. نفّذ الحل — العناصر تتحرك تلقائيًا', style: TextStyle(color: NexoColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
