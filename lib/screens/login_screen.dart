// ignore_for_file: unused_local_variable
// ignore_for_file: avoid_print, deprecated_member_use, curly_braces_in_flow_control_structures, library_prefixes, use_build_context_synchronously, library_private_types_in_public_api
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../core/session_manager.dart';
import 'dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Premium Brand Colors
  final Color _primaryMaroon = const Color(0xFF6A1028);
  final Color _secondaryBurgundy = const Color(0xFF8A1C3C);
  final Color _accentGold = const Color(0xFFC89B3C);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      await AuthService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      final session = SessionManager();
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontFamily: 'Poppins')),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: MouseRegion(
          child: Stack(
            children: [
              // ULTRA PREMIUM LAYERED BACKGROUND
              const _UltraPremiumBackground(),
              
              // MAIN CONTENT WRAPPER
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Animated Logo Header
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: _buildHeader(),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Animated Form Card
                                  SlideTransition(
                                    position: _slideAnimation,
                                    child: FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: _buildLoginCard(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Radial Spotlight Behind Logo
        Stack(
          alignment: Alignment.center,
          children: [
            // Soft Radial Glow
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accentGold.withValues(alpha: 0.2),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            // Frosted Glass Logo Container
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        const Text(
          'Libro Espresso',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        
        Text(
          'DECISION SUPPORT SYSTEM',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 4.0,
            color: _accentGold.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF8F5).withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PremiumTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Email required';
                    if (!value.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                _PremiumTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    GestureDetector(
                      onTap: _isLoading ? null : () => setState(() => _rememberMe = !_rememberMe),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _rememberMe ? _primaryMaroon : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _rememberMe ? _primaryMaroon : const Color(0xFFD1D5DB),
                            width: 1.5,
                          ),
                        ),
                        child: _rememberMe
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _isLoading ? null : () => setState(() => _rememberMe = !_rememberMe),
                      child: const Text(
                        'Remember Me',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                
                _PremiumButton(
                  isLoading: _isLoading,
                  onPressed: _handleSignIn,
                  primaryColor: _primaryMaroon,
                  hoverColor: _secondaryBurgundy,
                ),
                
                const SizedBox(height: 16),
                const Text(
                  'Authorized Personnel Only',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// REUSABLE PREMIUM WIDGETS
// ---------------------------------------------------------

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final VoidCallback? onToggleVisibility;
  final String? Function(String?)? validator;

  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.onToggleVisibility,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color(0xFF1F2937)),
      cursorColor: const Color(0xFF6A1028),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontFamily: 'Poppins'),
        floatingLabelStyle: const TextStyle(color: Color(0xFF6A1028), fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
        filled: true,
        fillColor: const Color(0xFFFDF8F5),
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF9CA3AF),
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6A1028), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}

class _PremiumButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final Color primaryColor;
  final Color hoverColor;

  const _PremiumButton({
    required this.onPressed,
    this.isLoading = false,
    required this.primaryColor,
    required this.hoverColor,
  });

  @override
  __PremiumButtonState createState() => __PremiumButtonState();
}

class __PremiumButtonState extends State<_PremiumButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: _isHovered
                ? [widget.hoverColor, widget.primaryColor]
                : [widget.primaryColor, widget.hoverColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withValues(alpha: 0.3),
              blurRadius: _isHovered ? 15 : 10,
              offset: Offset(0, _isHovered ? 6 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.isLoading ? null : widget.onPressed,
            splashColor: Colors.white.withValues(alpha: 0.1),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: widget.isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Signing In...',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
            _buildBlurBlob(size.width * -0.1 + 50, size.height * -0.1 + 30, 600, const Color(0xFFC89B3C).withValues(alpha: 0.08)), // Gold
            _buildBlurBlob(size.width * 0.6 + 60, size.height * 0.8 + 50, 700, const Color(0xFF4A0818).withValues(alpha: 0.6)), // Dark
            _buildBlurBlob(size.width * 0.8 + 80, size.height * 0.2 + 40, 500, const Color(0xFF9B1B3C).withValues(alpha: 0.3)), // Wine
            _buildBlurBlob(size.width * 0.2 + 40, size.height * 0.9 + 70, 450, const Color(0xFF6A1028).withValues(alpha: 0.4)), // Maroon
            _buildBlurBlob(size.width * 0.5 + 30, size.height * 0.5 + 60, 800, const Color(0xFF3B000C).withValues(alpha: 0.5)), // Center Dark
            _buildBlurBlob(size.width * 0.0 + 90, size.height * 0.4 + 50, 550, const Color(0xFF8A1C3C).withValues(alpha: 0.2)),
            _buildBlurBlob(size.width * 0.9 + 60, size.height * -0.05 + 40, 400, const Color(0xFFD4AF37).withValues(alpha: 0.05)), // Pale Gold
            _buildBlurBlob(size.width * 0.3 + 70, size.height * 0.1 + 80, 650, const Color(0xFF5B0018).withValues(alpha: 0.4)),
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
              color: Colors.white.withValues(alpha: 0.02),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
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
    paint.color = const Color(0xFF8A1C3C).withValues(alpha: 0.15);
    final path1 = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.6 + 50, 0)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.2 + 30, 0, size.height * 0.4)
      ..close();
    canvas.drawPath(path1, paint);

    // Wave 2: Bottom Right
    paint.color = const Color(0xFF4A0818).withValues(alpha: 0.3);
    final path2 = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.2 + 40, size.height)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.7 + 40, size.width, size.height * 0.4)
      ..close();
    canvas.drawPath(path2, paint);

    // Wave 3: Crossing behind center
    paint.color = const Color(0xFF6A1028).withValues(alpha: 0.2);
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
      ..color = const Color(0xFFC89B3C).withValues(alpha: 0.08)
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
    canvas.drawPath(path3, paint..color = const Color(0xFFC89B3C).withValues(alpha: 0.05));
  }

  @override
  bool shouldRepaint(covariant _StaticGoldAccentPainter oldDelegate) => false;
}

class _StaticCoffeePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Espresso Ring 1 (Top Left)
    canvas.drawCircle(Offset(size.width * 0.15 + 15, size.height * 0.1 + 15), 80, paint);
    canvas.drawCircle(Offset(size.width * 0.14 + 12, size.height * 0.09 + 12), 75, paint..strokeWidth = 0.5);

    // Espresso Ring 2 (Bottom Right)
    canvas.drawCircle(Offset(size.width * 0.85 + 20, size.height * 0.85 + 20), 100, paint..strokeWidth = 2.0);

    // Steam Curve (Center Left)
    final steamPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
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
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.save();
    canvas.translate(size.width * 0.8, size.height * 0.25 + 10);
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
