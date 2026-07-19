import 'dart:io';

void main() {
  final file = File(r'C:\Users\CYBORG\Documents\Libro Espresso App\lib\screens\login_screen.dart');
  final lines = file.readAsLinesSync();
  
  lines[21] = '';
  lines[114] = '';
  lines[118] = '            const _UltraPremiumBackground(),';
  
  final newBackground = '''
// ============================================================================
// ULTRA PREMIUM STATIC BACKGROUND
// ============================================================================

class _UltraPremiumBackground extends StatelessWidget {
  const _UltraPremiumBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // ==========================================
        // LAYER 1: Deep Burgundy Base Gradient
        // ==========================================
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A0008), // Almost black burgundy
                Color(0xFF5B0018), // Deep Maroon
                Color(0xFF8A1C3C), // Rich Wine
                Color(0xFF3A0010),
              ],
              stops: [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        ),

        // ==========================================
        // LAYER 2: Large Blurred Blobs
        // ==========================================
        Stack(
          children: [
            _buildBlurBlob(size.width * -0.1 + 50, size.height * -0.1 + 30, 600, const Color(0xFFC89B3C).withOpacity(0.08)), // Gold
            _buildBlurBlob(size.width * 0.6 + 60, size.height * 0.8 + 50, 700, const Color(0xFF4A0818).withOpacity(0.6)), // Dark
            _buildBlurBlob(size.width * 0.8 + 80, size.height * 0.2 + 40, 500, const Color(0xFF9B1B3C).withOpacity(0.3)), // Wine
            _buildBlurBlob(size.width * 0.2 + 40, size.height * 0.9 + 70, 450, const Color(0xFF6A1028).withOpacity(0.4)), // Maroon
            _buildBlurBlob(size.width * 0.5 + 30, size.height * 0.5 + 60, 800, const Color(0xFF3B000C).withOpacity(0.5)), // Center Dark
            _buildBlurBlob(size.width * 0.0 + 90, size.height * 0.4 + 50, 550, const Color(0xFF8A1C3C).withOpacity(0.2)),
            _buildBlurBlob(size.width * 0.9 + 60, size.height * -0.05 + 40, 400, const Color(0xFFD4AF37).withOpacity(0.05)), // Pale Gold
            _buildBlurBlob(size.width * 0.3 + 70, size.height * 0.1 + 80, 650, const Color(0xFF5B0018).withOpacity(0.4)),
          ],
        ),

        // ==========================================
        // LAYER 3: Glass Shapes, Curves, and Circles
        // ==========================================
        Stack(
          children: [
            // Curved Wave Layers
            Positioned.fill(child: CustomPaint(painter: _StaticWavePainter())),
            
            // Golden Accent Lines
            Positioned.fill(child: CustomPaint(painter: _StaticGoldAccentPainter())),

            // Very Subtle Coffee Decorations
            Positioned.fill(child: CustomPaint(painter: _StaticCoffeePainter())),
            
            // Floating Glass Circles
            _buildGlassCircle(size.width * 0.15 + 20, size.height * 0.15 + 20, 120),
            _buildGlassCircle(size.width * 0.85 + 30, size.height * 0.75 + 25, 200),
            _buildGlassCircle(size.width * 0.7 + 40, size.height * 0.25 + 35, 80),
            _buildGlassCircle(size.width * 0.25 + 25, size.height * 0.85 + 15, 160),

            // Background Glassmorphism Shapes (Panels)
            Positioned(
              left: size.width * 0.5 - 220 + 10,
              top: size.height * 0.5 - 300 + 15,
              child: Transform.rotate(
                angle: -3.14159 / 12,
                child: _buildFrostedPanel(150, 200),
              ),
            ),
            Positioned(
              left: size.width * 0.5 + 80 + 12,
              top: size.height * 0.5 + 150 + 10,
              child: Transform.rotate(
                angle: 3.14159 / 8,
                child: _buildFrostedPanel(180, 180),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBlurBlob(double x, double y, double size, Color color) {
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildGlassCircle(double x, double y, double size) {
    return Positioned(
      left: x,
      top: y,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.02),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrostedPanel(double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// STATIC BACKGROUND PAINTERS
// ---------------------------------------------------------

class _StaticWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Wave 1: Top Left
    paint.color = const Color(0xFF8A1C3C).withOpacity(0.15);
    final path1 = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.6 + 50, 0)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.2 + 30, 0, size.height * 0.4)
      ..close();
    canvas.drawPath(path1, paint);

    // Wave 2: Bottom Right
    paint.color = const Color(0xFF4A0818).withOpacity(0.3);
    final path2 = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.2 + 40, size.height)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.7 + 40, size.width, size.height * 0.4)
      ..close();
    canvas.drawPath(path2, paint);

    // Wave 3: Crossing behind center
    paint.color = const Color(0xFF6A1028).withOpacity(0.2);
    final path3 = Path()
      ..moveTo(0, size.height * 0.8 + 30)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.9, size.width, size.height * 0.5 + 50)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant _StaticWavePainter oldDelegate) => false;
}

class _StaticGoldAccentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC89B3C).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path1 = Path()
      ..moveTo(-50, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.1 + 40, size.width + 50, size.height * 0.3);
    canvas.drawPath(path1, paint);

    final path2 = Path()
      ..moveTo(size.width + 50, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.9 + 50, -50, size.height * 0.85);
    canvas.drawPath(path2, paint);

    final path3 = Path()
      ..moveTo(size.width * 0.2, -50)
      ..quadraticBezierTo(size.width * 0.3 + 60, size.height * 0.5, size.width * 0.8, size.height + 50);
    canvas.drawPath(path3, paint..color = const Color(0xFFC89B3C).withOpacity(0.05));
  }

  @override
  bool shouldRepaint(covariant _StaticGoldAccentPainter oldDelegate) => false;
}

class _StaticCoffeePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03) // Very subtle 3% opacity
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Espresso Ring 1 (Top Left)
    canvas.drawCircle(Offset(size.width * 0.15 + 15, size.height * 0.1 + 15), 80, paint);
    canvas.drawCircle(Offset(size.width * 0.14 + 12, size.height * 0.09 + 12), 75, paint..strokeWidth = 0.5);

    // Espresso Ring 2 (Bottom Right)
    canvas.drawCircle(Offset(size.width * 0.85 + 20, size.height * 0.85 + 20), 100, paint..strokeWidth = 2.0);

    // Steam Curve (Center Left)
    final steamPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    final steamPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.2 + 20, size.height * 0.5, size.width * 0.1, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.0 + 20, size.height * 0.3, size.width * 0.15, size.height * 0.2);
    canvas.drawPath(steamPath, steamPaint);

    // Coffee Bean (Top Right)
    final beanPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.save();
    canvas.translate(size.width * 0.8, size.height * 0.25 + 10);
    // Use 1.628 instead of math.pi / 5 + 1.0 (approx)
    canvas.rotate(1.628); 
    canvas.drawOval(const Rect.fromLTWH(-20, -35, 40, 70), beanPaint);
    canvas.drawLine(const Offset(-8, -30), const Offset(8, 30), beanPaint);
    canvas.restore();

    // Coffee Leaf (Bottom Left)
    canvas.save();
    canvas.translate(size.width * 0.2, size.height * 0.8 + 15);
    canvas.rotate(-0.785); // -math.pi / 4
    final leafPath = Path()
      ..moveTo(0, -40)
      ..quadraticBezierTo(25, 0, 0, 40)
      ..quadraticBezierTo(-25, 0, 0, -40)
      ..moveTo(0, -40)
      ..lineTo(0, 40);
    canvas.drawPath(leafPath, beanPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StaticCoffeePainter oldDelegate) => false;
}
''';

  final newLines = lines.sublist(0, 567);
  newLines.add(newBackground);
  
  file.writeAsStringSync(newLines.join('\\n'));
}
