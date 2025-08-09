import 'package:flutter/material.dart';

class ConnectionCard extends StatefulWidget {
  final String title;
  final String imagePath;
  final double imageTop;
  final double imageRight;
  final double imageSize;
  final VoidCallback onTap;

  const ConnectionCard({
    required this.title,
    required this.imagePath,
    this.imageTop = -40,
    this.imageRight = -40,
    this.imageSize = 80,
    required this.onTap,
    super.key,
  });

  @override
  State<ConnectionCard> createState() => _ConnectionCardState();
}

class _ConnectionCardState extends State<ConnectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(_animController);
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(tag: widget.title, child: _buildAnimatedCard(context));
  }

  Widget _buildAnimatedCard(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _animController.forward(),
      onExit: (_) => _animController.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _animController.forward(),
        onTapUp: (_) {
          _animController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _animController.reverse(),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Material(
                  color: Colors.transparent,
                  child: _buildCardContent(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.7,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 128, 203, 233),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: widget.imageTop,
          right: widget.imageRight,
          child: Center(
            child: Image.asset(
              widget.imagePath,
              width: widget.imageSize,
              height: widget.imageSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}
