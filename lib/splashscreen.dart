// splashscreen.dart - Debug Version
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mmkv/mmkv.dart';
import 'login.dart';
import 'home.dart';
import 'screens/onboarding_screen.dart' as screens_onboarding;
import 'utils/login_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;

  String _statusMessage = 'Memulai aplikasi...';
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 SplashScreen initState started');
    _initAnimations();

    // Debug: Check MMKV status immediately with more detailed logging
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('📱 PostFrameCallback triggered');
      await _debugMMKVDetailed();
      await _initializeApp();
    });
  }

  void _initAnimations() {
    try {
      debugPrint('🎬 Initializing animations...');
      _logoController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );

      _textController = AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: this,
      );

      _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
      );

      _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeOut),
      );

      _logoController.forward();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _textController.forward();
        }
      });
      debugPrint('✅ Animations initialized successfully');
    } catch (e) {
      debugPrint('❌ Animation initialization error: $e');
    }
  }

  Future<void> _debugMMKVDetailed() async {
    debugPrint('🔍 Starting detailed MMKV debug...');
    try {
      // Check if MMKV is initialized
      debugPrint('🔍 Step 1: Checking MMKV initialization...');

      final mmkv = MMKV.defaultMMKV();

      debugPrint('✅ MMKV instance exists');
      _updateDebugInfo('MMKV: Initialized');

      // Test basic operations
      debugPrint('🔍 Step 2: Testing MMKV basic operations...');
      try {
        mmkv.encodeBool('test_splash', true);
        final testRead = mmkv.decodeBool('test_splash', defaultValue: false);
        debugPrint('✅ MMKV read/write test: $testRead');
        mmkv.removeValue('test_splash'); // cleanup
        _updateDebugInfo('MMKV: Read/Write OK');
      } catch (e) {
        debugPrint('❌ MMKV read/write test failed: $e');
        _updateDebugInfo('MMKV: R/W Error - $e');
      }

      // Check existing keys
      debugPrint('🔍 Step 3: Checking existing keys...');
      final allKeys = mmkv.allKeys;
      final keyCount = mmkv.count;
      debugPrint('🔍 All keys: $allKeys');
      debugPrint('🔍 Total count: $keyCount');
      _updateDebugInfo('Keys: $keyCount found');

      // Check login-specific keys
      final loginKeys = [
        'user_logged_in',
        'user_username',
        'user_login_time',
        'user_data_json',
      ];

      for (final key in loginKeys) {
        if (mmkv.containsKey(key)) {
          if (key == 'user_logged_in') {
            final value = mmkv.decodeBool(key, defaultValue: false);
            debugPrint('🔍 $key: $value');
          } else {
            final value = mmkv.decodeString(key) ?? 'NULL';
            debugPrint('🔍 $key: "$value"');
          }
        } else {
          debugPrint('🔍 $key: NOT FOUND');
        }
      }
    } catch (e) {
      debugPrint('❌ MMKV detailed debug error: $e');
      _updateDebugInfo('MMKV Error: $e');
    }
  }

  Future<void> _initializeApp() async {
    debugPrint('🚀 Starting app initialization...');
    try {
      _updateStatus('Menginisialisasi aplikasi...');
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) {
        debugPrint('⚠️ Widget not mounted, stopping initialization');
        return;
      }

      _updateStatus('Memeriksa MMKV...');

      // Test LoginPreferences health
      debugPrint('🔍 Testing LoginPreferences health...');
      final isHealthy = await LoginPreferences.checkHealth();
      debugPrint('🔍 LoginPreferences health: $isHealthy');
      _updateDebugInfo('LoginPrefs: ${isHealthy ? 'OK' : 'Failed'}');

      if (!isHealthy) {
        debugPrint('⚠️ LoginPreferences unhealthy, proceeding to login');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _navigateToLogin();
        }
        return;
      }

      _updateStatus('Memeriksa status login...');

      // Check login status
      debugPrint('🔍 Checking login status...');
      final isLoggedIn = await LoginPreferences.isLoggedIn();
      final username = await LoginPreferences.getUsername();

      debugPrint(
        '🔍 Login check result: isLoggedIn=$isLoggedIn, username="$username"',
      );
      _updateDebugInfo('Login: $isLoggedIn, User: $username');

      if (!mounted) {
        debugPrint('⚠️ Widget not mounted after login check');
        return;
      }

      if (isLoggedIn && username != null && username.isNotEmpty) {
        _updateStatus('Selamat datang kembali, $username!');
        debugPrint('✅ User is logged in, navigating to home');
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          _navigateToHome(username);
        }
      } else {
        _updateStatus('Silakan login...');
        debugPrint('ℹ️ User not logged in, navigating to login');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _navigateToLogin();
        }
      }
    } catch (e) {
      debugPrint('💥 Initialization error: $e');
      _updateDebugInfo('Init Error: $e');
      _updateStatus('Terjadi kesalahan: $e');

      // Fallback: always go to login if error
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _navigateToLogin();
      }
    }
  }

  void _updateStatus(String message) {
    debugPrint('📱 Status Update: $message');
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  void _updateDebugInfo(String info) {
    debugPrint('🐛 Debug Info: $info');
    if (mounted) {
      setState(() {
        _debugInfo = info;
      });
    }
  }

  void _navigateToHome(String username) {
    debugPrint('🏠 Navigating to HomeScreen for: $username');

    if (!mounted) {
      debugPrint('⚠️ Widget not mounted, cannot navigate to home');
      return;
    }

    try {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(username: username)),
      );
      debugPrint('✅ Navigation to home completed');
    } catch (e) {
      debugPrint('❌ Navigation to home error: $e');
      _navigateToLogin(); // fallback
    }
  }

  void _navigateToLogin() {
    debugPrint('🔐 Navigating to Login/Onboarding');

    if (!mounted) {
      debugPrint('⚠️ Widget not mounted, cannot navigate');
      return;
    }

    try {
      final mmkv = MMKV.defaultMMKV();
      final hasSeenOnboarding = mmkv.decodeBool('has_seen_onboarding', defaultValue: false);

      if (!hasSeenOnboarding) {
        debugPrint('🚀 First time user, navigating to OnboardingScreen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => screens_onboarding.OnboardingScreen()),
        );
      } else {
        debugPrint('🔐 Returning user, navigating to LoginScreen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      }
      debugPrint('✅ Navigation completed');
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      _updateStatus('Error navigasi: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('🗑️ SplashScreen disposing...');
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF10B981), Color(0xFF059669)], // Green gradient
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative background elements (Bento aesthetic)
              Positioned(
                top: -100,
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -100,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              
              // Main Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _logoAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _logoAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32), // Bento radius
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: const Image(
                                image: AssetImage('assets/img/molah.png'),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    AnimatedBuilder(
                      animation: _textAnimation,
                      builder: (context, child) => Opacity(
                        opacity: _textAnimation.value,
                        child: Column(
                          children: [
                            const Text(
                              'MOLAH',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Aplikasi Monitoring Santri',
                                style: TextStyle(
                                  fontSize: 13, 
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    
                    // Loading indicator area
                    Container(
                      height: 48,
                      width: 48,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const CircularProgressIndicator(
                        color: Color(0xFF059669),
                        strokeWidth: 3,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _statusMessage,
                            style: const TextStyle(
                              color: Color(0xFF64748B), 
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    // Debug info
                    if (_debugInfo.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          _debugInfo,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Bottom Footer
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        'Pesantren Islam Zaid bin Tsabit',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'MOLAH v2.0.0 • Powered by Pizab',
                      style: TextStyle(
                        fontSize: 10, 
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
