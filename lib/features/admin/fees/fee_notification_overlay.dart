// lib/core/widgets/fee_notification_overlay.dart
//
// WhatsApp-style popup notification for the admin dashboard.
// Shows when a parent submits payment proof.
//
// SETUP — wrap your admin home Scaffold body in FeeNotificationOverlay:
//
//   @override
//   Widget build(BuildContext context) {
//     return FeeNotificationOverlay(
//       child: Scaffold(
//         // ... your existing admin home scaffold
//       ),
//     );
//   }
//
// OR use it at the top-level shell (admin shell route) so it works
// across all admin screens. In your admin shell builder:
//
//   builder: (context, state, child) => FeeNotificationOverlay(child: child),
//
// HOW IT WORKS:
//   - Listens to Firestore 'fees' collection for newly added docs
//     with status == 'pending_verification' created in last 30 seconds.
//   - When one arrives, slides a WhatsApp-style card from the top.
//   - Tapping it navigates to /admin/home/fee-verification.
//   - Auto-dismisses after 5 seconds.
//   - Shows a badge count if multiple arrive while one is showing.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';

class FeeNotificationOverlay extends StatefulWidget {
  final Widget child;

  const FeeNotificationOverlay({super.key, required this.child});

  @override
  State<FeeNotificationOverlay> createState() =>
      _FeeNotificationOverlayState();
}

class _FeeNotificationOverlayState extends State<FeeNotificationOverlay>
    with TickerProviderStateMixin {
  StreamSubscription<QuerySnapshot>? _sub;

  // Queue of notifications waiting to be shown
  final List<_FeeNotif> _queue = [];

  // Currently showing
  _FeeNotif? _current;

  // Animation controller for slide + fade
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  Timer? _autoHideTimer;

  // Listen only to docs created after this moment (avoids showing old ones)
  late final Timestamp _listenFrom;

  @override
  void initState() {
    super.initState();
    _listenFrom = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(seconds: 5)),
    );

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutBack,
    ));

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn),
    );

    _startListening();
  }

  void _startListening() {
    _sub = FirebaseFirestore.instance
        .collection('fees')
        .where('status', isEqualTo: 'pending_verification')
        .where('createdAt', isGreaterThanOrEqualTo: _listenFrom)
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data == null) continue;

          // Only show if status changed to pending_verification recently
          final updatedAt = data['updatedAt'] as Timestamp?;
          final createdAt = data['createdAt'] as Timestamp?;
          final ts = updatedAt ?? createdAt;
          if (ts == null) continue;

          final age = DateTime.now().difference(ts.toDate()).inSeconds;
          if (age > 300) continue; // skip old ones

          final notif = _FeeNotif(
            docId: change.doc.id,
            studentName: data['studentName'] as String? ?? 'Student',
            feeType: data['feeType'] as String? ?? 'Fee',
            amount:
                (data['paymentProof']?['paidAmount'] as num?)?.toDouble() ??
                (data['amount'] as num?)?.toDouble() ??
                0,
            txnId: data['paymentProof']?['transactionId'] as String? ?? '',
            className: data['className'] as String? ?? '',
          );

          _enqueue(notif);
        }
      }
    });
  }

  void _enqueue(_FeeNotif notif) {
    if (!mounted) return;
    setState(() {
      if (_current == null) {
        _current = notif;
        _show();
      } else {
        _queue.add(notif);
      }
    });
  }

  void _show() {
    _animCtrl.forward(from: 0);
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 5), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _animCtrl.reverse();
    if (!mounted) return;
    setState(() {
      _current = null;
      if (_queue.isNotEmpty) {
        _current = _queue.removeAt(0);
        _show();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _autoHideTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_current != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _NotificationCard(
                  notif: _current!,
                  queueCount: _queue.length,
                  onTap: () {
                    _dismiss();
                    context.push('/admin/home/fee-verification');
                  },
                  onDismiss: _dismiss,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Notification card (WhatsApp-style) ───────────────────────────────────────

class _NotificationCard extends StatefulWidget {
  final _FeeNotif notif;
  final int queueCount;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notif,
    required this.queueCount,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  // Progress bar timer (5s countdown)
  double _progress = 1.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _startProgress();
  }

  void _startProgress() {
    const steps = 50;
    const interval = Duration(milliseconds: 100); // 5s total
    int tick = 0;
    _progressTimer =
        Timer.periodic(interval, (_) {
      if (!mounted) return;
      tick++;
      setState(() => _progress = 1.0 - (tick / steps));
      if (tick >= steps) _progressTimer?.cancel();
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount =
        'Rs. ${NumberFormat('#,##0').format(widget.notif.amount)}';

    return GestureDetector(
      onTap: widget.onTap,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(18),
        shadowColor: Colors.black26,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar (auto-dismiss timer)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18)),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 3,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation(Colors.white),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Icon bubble
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.payment_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.notifications_active_rounded,
                                size: 12, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              'NEW PAYMENT PROOF',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                                letterSpacing: 0.8,
                              ),
                            ),
                            if (widget.queueCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '+${widget.queueCount} more',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 4),
                          Text(
                            widget.notif.studentName,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.notif.feeType} · $amount · ${widget.notif.className}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.notif.txnId.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'TXN: ${widget.notif.txnId}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Colors.white54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Dismiss + action
                    Column(
                      children: [
                        GestureDetector(
                          onTap: widget.onDismiss,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 14),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Verify',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A56DB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class _FeeNotif {
  final String docId;
  final String studentName;
  final String feeType;
  final double amount;
  final String txnId;
  final String className;

  const _FeeNotif({
    required this.docId,
    required this.studentName,
    required this.feeType,
    required this.amount,
    required this.txnId,
    required this.className,
  });
}