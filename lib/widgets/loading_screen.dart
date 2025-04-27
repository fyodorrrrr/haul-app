import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // Function to show loading screen (overlay)
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing it by tapping outside
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        double boxWidth = size.width * 0.10; // 25% of the screen width (adjust width as needed)
        double boxHeight = size.height * 0.15; // 15% of the screen height (adjust height as needed)

        return Dialog(
          backgroundColor: Colors.transparent, // Transparent background for the dialog
          child: Container(
            width: boxWidth,
            height: boxHeight, // Square (same width and height)
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white,
                // width: 2,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  // Function to hide the loading screen (dismiss the overlay)
  static void hide(BuildContext context) {
    Navigator.of(context).pop(); // Dismiss the dialog
  }
}
