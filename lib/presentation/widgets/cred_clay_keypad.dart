import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// CRED-Inspired Tactile Pastel Clay Keypad for financial inputs.
/// Features pillowy pastel keys, dual physical clay shadows, zero harsh borders,
/// and responsive haptic feedback.
class CredClayKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyPress;
  final VoidCallback onBackspace;
  final VoidCallback? onClear;
  final bool showDecimal;

  const CredClayKeypad({
    super.key,
    required this.onKeyPress,
    required this.onBackspace,
    this.onClear,
    this.showDecimal = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4D2), // Soft Butter Cream Base
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x162C221E),
            blurRadius: 8,
            offset: Offset(0, -3),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildKey('1'),
              const SizedBox(width: 10),
              _buildKey('2'),
              const SizedBox(width: 10),
              _buildKey('3'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildKey('4'),
              const SizedBox(width: 10),
              _buildKey('5'),
              const SizedBox(width: 10),
              _buildKey('6'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildKey('7'),
              const SizedBox(width: 10),
              _buildKey('8'),
              const SizedBox(width: 10),
              _buildKey('9'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (showDecimal)
                _buildKey('.', isSpecial: true)
              else
                _buildActionKey(
                  icon: Icons.clear_all_rounded,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onClear?.call();
                  },
                ),
              const SizedBox(width: 10),
              _buildKey('0'),
              const SizedBox(width: 10),
              _buildActionKey(
                icon: Icons.backspace_outlined,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onBackspace();
                },
                isDelete: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String value, {bool isSpecial = false}) {
    return Expanded(
      child: _CredKeyButton(
        label: value,
        isSpecial: isSpecial,
        onTap: () {
          HapticFeedback.lightImpact();
          onKeyPress(value);
        },
      ),
    );
  }

  Widget _buildActionKey({
    required IconData icon,
    required VoidCallback onTap,
    bool isDelete = false,
  }) {
    return Expanded(
      child: _CredKeyButton(
        icon: icon,
        isDelete: isDelete,
        onTap: onTap,
      ),
    );
  }
}

class _CredKeyButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final bool isSpecial;
  final bool isDelete;
  final VoidCallback onTap;

  const _CredKeyButton({
    this.label,
    this.icon,
    this.isSpecial = false,
    this.isDelete = false,
    required this.onTap,
  });

  @override
  State<_CredKeyButton> createState() => _CredKeyButtonState();
}

class _CredKeyButtonState extends State<_CredKeyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDelete
        ? const Color(0xFFF19C79) // Coral Terracotta
        : const Color(0xFFCBDFBD); // Pale Pistachio Clay

    final textColor = widget.isDelete
        ? const Color(0xFF2C221E)
        : const Color(0xFF2C221E);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _isPressed
                ? const [
                    BoxShadow(
                      color: Color(0x1F2C221E),
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x1F2C221E),
                      blurRadius: 4,
                      offset: Offset(1.5, 2.5),
                    ),
                    BoxShadow(
                      color: Colors.white,
                      blurRadius: 1.5,
                      offset: Offset(-1, -1),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: widget.icon != null
              ? Icon(
                  widget.icon,
                  size: 21,
                  color: textColor,
                )
              : Text(
                  widget.label!,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
        ),
      ),
    );
  }
}
