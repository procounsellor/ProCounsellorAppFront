import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class StateTagSelector extends StatefulWidget {
  final Map<String, List<dynamic>> stateCounsellors;
  final List<String> activeStates;
  final Function(String) onToggleState;

  const StateTagSelector({
    Key? key,
    required this.stateCounsellors,
    required this.activeStates,
    required this.onToggleState,
  }) : super(key: key);

  @override
  _StateTagSelectorState createState() => _StateTagSelectorState();
}

class _StateTagSelectorState extends State<StateTagSelector> {
  final Map<String, bool> _isFlipped = {};

  void _handleTap(String state) {
    if (mounted) {
      setState(() {
        _isFlipped[state] = !(_isFlipped[state] ?? false);
      });
    }
    widget.onToggleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: widget.stateCounsellors.keys.map((state) {
          final isActive = widget.activeStates.contains(state);
          final flipped = _isFlipped[state] ?? false;

          return GestureDetector(
            onTap: () => _handleTap(state),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: flipped ? 1 : 0),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  final angle = value * pi;
                  final isFront = value < 0.5;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX(angle),
                    child: isFront
                        ? _buildCardFront(state, isActive)
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationX(pi),
                            child: _buildCardBack(state),
                          ),
                  );
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCardFront(String text, bool isActive) {
    return Container(
      width: 100,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            spreadRadius: 0.5,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isActive ? Colors.orange : Colors.grey.shade300,
          width: 1.2,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isActive ? Colors.orange : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCardBack(String state) {
    return Container(
      width: 100,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.green, // ✅ Solid green background
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            spreadRadius: 0.5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        state,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.white, // ✅ White text
        ),
      ),
    );
  }
}
