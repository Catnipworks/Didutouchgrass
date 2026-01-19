import 'package:flutter/material.dart';

class SharedCardWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const SharedCardWidget({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 40, vertical: 56),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade900, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(8, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
