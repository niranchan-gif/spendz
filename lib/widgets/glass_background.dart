import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

class GlassBackground extends StatefulWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  State<GlassBackground> createState() => _GlassBackgroundState();
}

class _GlassBackgroundState extends State<GlassBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.background;
    
    return Stack(
      children: [
        // Base solid color
        Container(color: bgColor),
        
        // Animated Orbs with ImageFiltered instead of BackdropFilter
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80, tileMode: TileMode.decal),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value;
                final width = MediaQuery.of(context).size.width;
                final height = MediaQuery.of(context).size.height;
                
                return Stack(
                  children: [
                    // Top Right Orb
                    Positioned(
                      top: height * 0.1 + sin(t * pi * 2) * 50,
                      right: width * -0.2 + cos(t * pi * 2) * 50,
                      child: Container(
                        width: width * 0.8,
                        height: width * 0.8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withAlpha(150),
                        ),
                      ),
                    ),
                    
                    // Bottom Left Orb
                    Positioned(
                      bottom: height * 0.05 + cos(t * pi * 2) * 60,
                      left: width * -0.3 + sin(t * pi * 2) * 40,
                      child: Container(
                        width: width * 0.9,
                        height: width * 0.9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryDark.withAlpha(130),
                        ),
                      ),
                    ),
                    
                    // Center Subtle Orb
                    Positioned(
                      top: height * 0.4 + sin(t * pi * 4) * 30,
                      left: width * 0.2 + cos(t * pi * 4) * 30,
                      child: Container(
                        width: width * 0.6,
                        height: width * 0.6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryLight.withAlpha(110),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        
        // Actual content
        Positioned.fill(child: widget.child),
      ],
    );
  }
}
