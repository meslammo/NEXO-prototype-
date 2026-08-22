import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/nexo_theme.dart';
import '../models/trade_models.dart';
import '../services/escrow_service.dart';
import 'trade_security_sheet.dart';
import 'dispute_resolution_screen.dart';

class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  final _escrow = EscrowService.instance;

  static const currentUserId = 'user_nexo_king';
  static const currentUserName = 'NEXO_KING';
  static const otherUserId = 'user_shadoww';
  static const otherUserName = 'Shadoww';

  Trade? _trade;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  final List<TradeItem> myItems = const [
    TradeItem(id: 'i1', name: 'Crown Shine', iconName: 'crown', colorValue: 0xFFFFD700, qty: 1, unitValue: 900),
    TradeItem(id: 'i2', name: 'Neon Heart', iconName: 'heart', colorValue: 0xFFFF6B9D, qty: 1, unitValue: 450),
  ];

  final List<TradeItem> theirItems = const [
    TradeItem(id: 'i3', name: 'Galaxy Aura', iconName: 'star', colorValue: 0xFFFFB300, qty: 1, unitValue: 700),
    TradeItem(id: 'i4', name: 'Shadow Flame', iconName: 'flame', colorValue: 0xFF9C27B0, qty: 1, unitValue: 550),
  ];

  @override
  void initState() {
    super.initState();
    _startEscrowTrade();
  }

  void _startEscrowTrade() {
    final trade = _escrow.createAndLockTrade(
      fromUserId: currentUserId,
      fromUserName: currentUserName,
      toUserId: otherUserId,
      toUserName: otherUserName,
      fromItems: myItems,
      toItems: theirItems,
    );
    setState(() {
      _trade = trade;
      _remaining = trade.remainingTime;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_trade == null) return;
      final updated = _escrow.checkExpiry(_trade!.id);
      if (updated != null && updated.status == TradeStatus.expired) {
        setState(() {
          _trade = updated;
          _remaining = Duration.zero;
        });
        _timer?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('انتهت مهلة الصفقة وتم إرجاع العناصر'), backgroundColor: Colors.orange),
          );
        }
        return;
      }
      setState(() => _remaining = _trade!.remainingTime);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return '00:00:00';
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'crown': return Icons.workspace_premium;
      case 'heart': return Icons.favorite;
      case 'star': return Icons.star;
      case 'flame': return Icons.local_fire_department;
      default: return Icons.inventory_2;
    }
  }

  void _confirmReceipt() {
    if (_trade == null) return;
    try {
      final updated = _escrow.confirmReceipt(tradeId: _trade!.id, userId: currentUserId);
      setState(() => _trade = updated);
      if (updated.status == TradeStatus.completed) {
        _timer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إكمال الصفقة بنجاح! العناصر اتحولت'), backgroundColor: NexoColors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تأكيد استلامك. في انتظار تأكيد الطرف الآخر')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _cancelTrade() {
    if (_trade == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NexoColors.card,
        title: const Text('إلغاء الصفقة؟', style: TextStyle(color: Colors.white)),
        content: const Text('سيتم إرجاع العناصر للطرفين وإلغاء الحجز.', style: TextStyle(color: NexoColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('رجوع')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final updated = _escrow.cancelTrade(tradeId: _trade!.id, userId: currentUserId, reason: 'إلغاء من المستخدم');
              setState(() => _trade = updated);
              _timer?.cancel();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الصفقة وإرجاع العناصر')));
            },
            child: const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }


  void _openDispute() {
    if (_trade == null) return;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NexoColors.card,
        title: const Text('فتح نزاع', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'اكتب سبب النزاع...', hintStyle: TextStyle(color: NexoColors.textSecondary)),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                final updated = _escrow.openDispute(tradeId: _trade!.id, userId: currentUserId, reason: controller.text.trim());
                setState(() => _trade = updated);
                _timer?.cancel();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم فتح النزاع')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent));
              }
            },
            child: const Text('إرسال', style: TextStyle(color: NexoColors.primary)),
          ),
        ],
      ),
    );
  }

  void _openResolution() async {
    if (_trade == null) return;
    final result = await Navigator.push<Trade>(
      context,
      MaterialPageRoute(builder: (_) => DisputeResolutionScreen(trade: _trade!)),
    );
    if (result != null) setState(() => _trade = result);
  }

  @override
  Widget build(BuildContext context) {
    final trade = _trade;
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
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                  const Expanded(
                    child: Text('التداول (Escrow)', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () {
                      if (trade == null) return;
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => TradeSecuritySheet(
                          itemValue: trade.totalValue,
                          feePercent: trade.feePercent,
                          feeAmount: trade.appFee,
                          totalReceive: trade.netAmount,
                        ),
                      );
                    },
                    icon: const Icon(Icons.shield_rounded, color: NexoColors.success),
                  ),
                ],
              ),
            ),
            if (trade == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildStatusBanner(trade),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _playerAvatar(trade.fromUserName, true, trade.fromConfirmed),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: NexoColors.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: NexoColors.primary.withOpacity(0.5)),
                            ),
                            child: const Icon(Icons.swap_horiz, color: NexoColors.primary, size: 28),
                          ),
                          _playerAvatar(trade.toUserName, false, trade.toConfirmed),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _tradePanel('أنت تقدم', trade.fromItems, true)),
                          const SizedBox(width: 12),
                          Expanded(child: _tradePanel('هو يقدم', trade.toItems, false)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSummary(trade),
                      const SizedBox(height: 20),
                      if (trade.status.isActive) ...[
                        if (!trade.fromConfirmed)
                          _actionButton(label: 'أكدت الاستلام', color: NexoColors.success, icon: Icons.check_circle, onTap: _confirmReceipt)
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: NexoColors.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: NexoColors.success.withOpacity(0.4)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: NexoColors.success),
                                SizedBox(width: 8),
                                Text('تم تأكيد استلامك — في انتظار الطرف الآخر',
                                    style: TextStyle(color: NexoColors.success, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (trade.status.canCancel)
                              Expanded(child: _actionButton(label: 'إلغاء الصفقة', color: Colors.redAccent, icon: Icons.cancel_outlined, onTap: _cancelTrade, outlined: true)),
                            if (trade.status.canCancel) const SizedBox(width: 12),
                            Expanded(child: _actionButton(label: 'فتح نزاع', color: Colors.orange, icon: Icons.gavel, onTap: _openDispute, outlined: true)),
                          ],
                        ),
                      ] else
                        _finalStatusCard(trade),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => TradeSecuritySheet(
                              itemValue: trade.totalValue,
                              feePercent: trade.feePercent,
                              feeAmount: trade.appFee,
                              totalReceive: trade.netAmount,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: NexoColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: NexoColors.success.withOpacity(0.35)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shield_rounded, size: 18, color: NexoColors.success),
                              SizedBox(width: 8),
                              Text('تفاصيل أمان Escrow ونسبة التطبيق 5%',
                                  style: TextStyle(color: NexoColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(Trade trade) {
    Color statusColor;
    IconData statusIcon;
    switch (trade.status) {
      case TradeStatus.locked:
        statusColor = NexoColors.primary;
        statusIcon = Icons.lock;
        break;
      case TradeStatus.confirmedA:
      case TradeStatus.confirmedB:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top;
        break;
      case TradeStatus.completed:
        statusColor = NexoColors.success;
        statusIcon = Icons.check_circle;
        break;
      case TradeStatus.cancelled:
      case TradeStatus.expired:
        statusColor = Colors.redAccent;
        statusIcon = Icons.cancel;
        break;
      case TradeStatus.disputed:
        statusColor = Colors.orange;
        statusIcon = Icons.gavel;
        break;
      case TradeStatus.resolved:
        statusColor = NexoColors.success;
        statusIcon = Icons.verified;
        break;
      default:
        statusColor = NexoColors.textSecondary;
        statusIcon = Icons.info;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(trade.status.labelAr, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          if (trade.status.isActive) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, color: NexoColors.ticket, size: 18),
                const SizedBox(width: 6),
                Text(_formatDuration(_remaining),
                    style: const TextStyle(color: NexoColors.ticket, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const Text('متبقي على انتهاء الحجز', style: TextStyle(color: NexoColors.textSecondary, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _playerAvatar(String name, bool isMe, bool confirmed) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isMe ? NexoColors.primary : NexoColors.secondary, width: 2),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: NexoColors.surface,
                child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              ),
            ),
            if (confirmed)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: NexoColors.background, shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle, color: NexoColors.success, size: 18),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(name, style: TextStyle(color: isMe ? NexoColors.primary : Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        if (confirmed) const Text('أكد الاستلام', style: TextStyle(color: NexoColors.success, fontSize: 10)),
      ],
    );
  }

  Widget _tradePanel(String title, List<TradeItem> items, bool isMine) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NexoColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isMine ? NexoColors.primary.withOpacity(0.4) : NexoColors.secondary.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: isMine ? NexoColors.primary : NexoColors.secondary, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: NexoColors.surface, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Color(item.colorValue).withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: Icon(_iconFor(item.iconName), color: Color(item.colorValue), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('x${item.qty}', style: const TextStyle(color: NexoColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSummary(Trade trade) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: NexoColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: NexoColors.cardBorder)),
      child: Column(
        children: [
          const Text('ملخص الصفقة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          _row('قيمة العناصر', '${trade.totalValue}', NexoColors.ticket),
          _row('نسبة التطبيق (${trade.feePercent}%)', '${trade.appFee}', Colors.redAccent),
          const Divider(color: NexoColors.cardBorder, height: 24),
          _row('المبلغ النهائي للمستلم', '${trade.netAmount}', NexoColors.success, bold: true),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: NexoColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: NexoColors.primary),
                SizedBox(width: 8),
                Expanded(child: Text('العناصر محجوزة بنظام Escrow. نسبة التطبيق 5% تُخصم تلقائيًا.', style: TextStyle(color: NexoColors.textSecondary, fontSize: 11))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: NexoColors.textSecondary, fontSize: 13, fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
          Row(children: [
            Text(value, style: TextStyle(color: color, fontSize: bold ? 18 : 15, fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(Icons.confirmation_number, size: 16, color: color),
          ]),
        ],
      ),
    );
  }

  Widget _actionButton({required String label, required Color color, required IconData icon, required VoidCallback onTap, bool outlined = false}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: color, size: 20),
              label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: color.withOpacity(0.6)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: Colors.white, size: 20),
              label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
    );
  }

  Widget _finalStatusCard(Trade trade) {
    String msg;
    Color color;
    switch (trade.status) {
      case TradeStatus.completed:
        msg = 'الصفقة اكتملت بنجاح وتم تحويل العناصر';
        color = NexoColors.success;
        break;
      case TradeStatus.cancelled:
        msg = 'تم إلغاء الصفقة وإرجاع العناصر\n${trade.cancelReason ?? ""}';
        color = Colors.redAccent;
        break;
      case TradeStatus.expired:
        msg = 'انتهت مهلة الصفقة وتم إرجاع العناصر تلقائيًا';
        color = Colors.orange;
        break;
      case TradeStatus.disputed:
        msg = 'نزاع مفتوح\n${trade.disputeReason ?? ""}';
        color = Colors.orange;
        break;
      case TradeStatus.resolved:
        msg = 'تم حل النزاع بنجاح\n${trade.resolution?.labelAr ?? ""}\n${trade.resolutionNote ?? ""}';
        color = NexoColors.success;
        break;
      default:
        msg = trade.status.labelAr;
        color = NexoColors.textSecondary;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.4))),
      child: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
