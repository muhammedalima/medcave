import 'package:flutter/material.dart';
import 'package:medcave/config/colors/appcolor.dart';
import 'package:medcave/config/fonts/font.dart';

class WaveyMessage extends StatelessWidget {
  final String message;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double waveyLineWidth;
  final Color waveyLineColor;
  final double spacing;

  const WaveyMessage({
    Key? key,
    required this.message,
    this.textColor = AppColor.backgroundWhite,
    this.fontSize = 60,
    this.fontWeight = FontWeight.bold,
    this.waveyLineWidth = 2.0,
    this.waveyLineColor = Colors.black,
    this.spacing = 42.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top wavey line
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width * 0.5, 20),
            painter: WaveyLinePainter(
              lineWidth: waveyLineWidth,
              lineColor: waveyLineColor,
            ),
          ),

          // Spacing
          SizedBox(height: spacing),

          // Message text
          Text(
            message,
            style: FontStyles.titleHero.copyWith(
              color: textColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
            textAlign: TextAlign.center,
          ),

          // Spacing
          SizedBox(height: spacing),

          // Bottom wavey line
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width * 0.5, 20),
            painter: WaveyLinePainter(
              lineWidth: waveyLineWidth,
              lineColor: waveyLineColor,
            ),
          ),
        ],
      ),
    );
  }
}

class WaveyLinePainter extends CustomPainter {
  final double lineWidth;
  final Color lineColor;

  WaveyLinePainter({
    required this.lineWidth,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Path path = Path();

    // Start from the left edge
    path.moveTo(0, size.height / 2);

    // Create 3 wave peaks
    final double segmentWidth = size.width / 3;

    // First peak
    path.quadraticBezierTo(
        segmentWidth * 0.5, 0, segmentWidth, size.height / 2);

    // Second peak
    path.quadraticBezierTo(
        segmentWidth * 1.5, size.height, segmentWidth * 2, size.height / 2);

    // Third peak
    path.quadraticBezierTo(segmentWidth * 2.5, 0, size.width, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
