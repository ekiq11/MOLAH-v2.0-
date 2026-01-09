import 'package:flutter/material.dart';

// Enhanced Shimmer Widget
class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _animation.value, 0.0),
              end: Alignment(1.0 + _animation.value, 0.0),
              colors: [
                Colors.grey[300]!.withOpacity(0.6),
                Colors.grey[100]!.withOpacity(0.8),
                Colors.grey[300]!.withOpacity(0.6),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerWidget(width: 100, height: 28, borderRadius: BorderRadius.circular(16)),
              Spacer(),
              ShimmerWidget(width: 70, height: 28, borderRadius: BorderRadius.circular(20)),
            ],
          ),
          SizedBox(height: 16),
          ShimmerWidget(width: double.infinity, height: 20, borderRadius: BorderRadius.circular(6)),
          SizedBox(height: 12),
          ShimmerWidget(width: double.infinity, height: 16, borderRadius: BorderRadius.circular(8)),
          SizedBox(height: 8),
          ShimmerWidget(width: MediaQuery.of(context).size.width * 0.6, height: 16, borderRadius: BorderRadius.circular(8)),
        ],
      ),
    );
  }
}