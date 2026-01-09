import 'package:flutter/material.dart';
import 'package:pizab_molah/pelanggaran/model/reward_model.dart';


class PelanggaranNotification {
  static OverlayEntry? _currentOverlay;

  static void show(BuildContext context, RewardPelanggaranData data) {
    // Remove any existing notification
    dismiss();

    _currentOverlay = _createOverlayEntry(context, data);
    Overlay.of(context).insert(_currentOverlay!);

    // Auto dismiss after 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      dismiss();
    });
  }

  static void dismiss() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  static OverlayEntry _createOverlayEntry(BuildContext context, RewardPelanggaranData data) {
    return OverlayEntry(
      builder: (context) => _NotificationWidget(data: data),
    );
  }
}

class _NotificationWidget extends StatefulWidget {
  final RewardPelanggaranData data;

  const _NotificationWidget({required this.data});

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      PelanggaranNotification.dismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isReward = widget.data.isReward;
    Color bgColor = isReward ? Color(0xFF4CAF50) : Color(0xFFDC2626);
    IconData icon = isReward ? Icons.star_rounded : Icons.warning_rounded;
    String title = isReward ? 'Selamat! Reward Diterima' : '⚠️ Pelanggaran Tercatat';

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: bgColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header dengan gradient
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isReward
                                    ? [Color(0xFF4CAF50), Color(0xFF45a049)]
                                    : [Color(0xFFDC2626), Color(0xFFB91C1C)],
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icon, color: Colors.white, size: 24),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        widget.data.hariTanggal,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.white, size: 20),
                                  onPressed: _dismiss,
                                ),
                              ],
                            ),
                          ),
                          
                          // Content
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nama Santri
                                Row(
                                  children: [
                                    Icon(Icons.person, size: 18, color: Colors.grey[600]),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        widget.data.namaSantri,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                SizedBox(height: 12),
                                
                                // Jenis Etika
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: bgColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: bgColor.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    widget.data.jenisEtika,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: bgColor,
                                    ),
                                  ),
                                ),
                                
                                if (widget.data.rincianKejadian.isNotEmpty) ...[
                                  SizedBox(height: 12),
                                  Text(
                                    widget.data.rincianKejadian,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                
                                SizedBox(height: 12),
                                
                                // Poin
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isReward ? Icons.add_circle : Icons.remove_circle,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            isReward
                                                ? '${widget.data.jumlahReward} poin'
                                                : '${widget.data.jumlahPelanggaran} poin',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Spacer(),
                                    if (widget.data.waktu.isNotEmpty)
                                      Text(
                                        widget.data.waktu,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}