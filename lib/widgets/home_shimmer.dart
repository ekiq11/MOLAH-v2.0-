import 'package:flutter/material.dart';

class HomeShimmerLoading extends StatefulWidget {
  final Size screenSize;

  const HomeShimmerLoading({super.key, required this.screenSize});

  @override
  State<HomeShimmerLoading> createState() => _HomeShimmerLoadingState();
}

class _HomeShimmerLoadingState extends State<HomeShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Widget _buildShimmerContainer({
    required double width,
    required double height,
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.grey[300],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.grey[300]!,
                    Colors.grey[100]!,
                    Colors.grey[300]!,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  transform: GradientRotation(_shimmerAnimation.value * 0.3),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderShimmer(Size screenSize) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: screenSize.width * 0.05,
        horizontal: screenSize.width * 0.06,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(screenSize.width * 0.06),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildShimmerContainer(
                width: screenSize.width * 0.14,
                height: screenSize.width * 0.14,
                borderRadius: 16,
              ),
              SizedBox(width: screenSize.width * 0.05),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerContainer(
                      width: screenSize.width * 0.3,
                      height: screenSize.width * 0.035,
                      borderRadius: 6,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                    _buildShimmerContainer(
                      width: screenSize.width * 0.45,
                      height: screenSize.width * 0.05,
                      borderRadius: 8,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.003),
                    _buildShimmerContainer(
                      width: screenSize.width * 0.35,
                      height: screenSize.width * 0.035,
                      borderRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.035),
          Container(
            padding: EdgeInsets.all(screenSize.width * 0.055),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerContainer(
                        width: screenSize.width * 0.25,
                        height: screenSize.width * 0.032,
                        borderRadius: 6,
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                      _buildShimmerContainer(
                        width: screenSize.width * 0.4,
                        height: screenSize.width * 0.065,
                        borderRadius: 10,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: screenSize.width * 0.04),
                _buildShimmerContainer(
                  width: screenSize.width * 0.09,
                  height: screenSize.width * 0.09,
                  borderRadius: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsShimmer(Size screenSize) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenSize.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerContainer(
            width: screenSize.width * 0.3,
            height: screenSize.width * 0.05,
            borderRadius: 10,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              4,
              (index) => Column(
                children: [
                  _buildShimmerContainer(
                    width: screenSize.width * 0.125,
                    height: screenSize.width * 0.125,
                    borderRadius: screenSize.width * 0.0625,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  _buildShimmerContainer(
                    width: screenSize.width * 0.15,
                    height: screenSize.width * 0.03,
                    borderRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportShimmer(Size screenSize) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenSize.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerContainer(
            width: screenSize.width * 0.25,
            height: screenSize.width * 0.05,
            borderRadius: 10,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildShimmerContainer(
                      width: double.infinity,
                      height: screenSize.width * 0.04,
                      borderRadius: 8,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    _buildShimmerContainer(
                      width: screenSize.width * 0.2,
                      height: screenSize.width * 0.06,
                      borderRadius: 12,
                    ),
                  ],
                ),
              ),
              SizedBox(width: screenSize.width * 0.04),
              Expanded(
                child: Column(
                  children: [
                    _buildShimmerContainer(
                      width: double.infinity,
                      height: screenSize.width * 0.04,
                      borderRadius: 8,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    _buildShimmerContainer(
                      width: screenSize.width * 0.2,
                      height: screenSize.width * 0.06,
                      borderRadius: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfoShimmer(Size screenSize) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenSize.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerContainer(
            width: screenSize.width * 0.3,
            height: screenSize.width * 0.05,
            borderRadius: 10,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          ...List.generate(
            4,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.015),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShimmerContainer(
                    width: screenSize.width * 0.25,
                    height: screenSize.width * 0.04,
                    borderRadius: 8,
                  ),
                  _buildShimmerContainer(
                    width: screenSize.width * 0.2,
                    height: screenSize.width * 0.04,
                    borderRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              widget.screenSize.width * 0.04,
              widget.screenSize.width * 0.04,
              widget.screenSize.width * 0.04,
              0,
            ),
            child: _buildHeaderShimmer(widget.screenSize),
          ),
          Padding(
            padding: EdgeInsets.all(widget.screenSize.width * 0.05),
            child: Column(
              children: [
                _buildQuickActionsShimmer(widget.screenSize),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                _buildReportShimmer(widget.screenSize),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                _buildStudentInfoShimmer(widget.screenSize),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
