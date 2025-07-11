import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final LinearGradient? gradient;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: gradient != null ? null : Colors.purple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      ).copyWith(
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (gradient != null) {
            return null; // Let gradient handle the background
          }
          return states.contains(MaterialState.pressed)
              ? Colors.purple[700]
              : Colors.purple;
        }),
      ),
      child: gradient != null
          ? ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => gradient!.createShader(bounds),
              child: Text(
                text,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          : Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
    );
  }
}
