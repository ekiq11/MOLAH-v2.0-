// splashscreen.dart - Debug Version
import 'package:flutter/material.dart';
import 'home.dart';
import 'login.dart';
import 'utils/login_preferences.dart';
import 'package:mmkv/mmkv.dart';

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
    print('🚀 SplashScreen initState started');
    _initAnimations();

    // Debug: Check MMKV status immediately with more detailed logging
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('📱 PostFrameCallback triggered');
      await _debugMMKVDetailed();
      await _initializeApp();
    });
  }

  void _initAnimations() {
    try {
      print('🎬 Initializing animations...');
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
      print('✅ Animations initialized successfully');
    } catch (e) {
      print('❌ Animation initialization error: $e');
    }
  }

  Future<void> _debugMMKVDetailed() async {
    print('🔍 Starting detailed MMKV debug...');
    try {
      // Check if MMKV is initialized
      print('🔍 Step 1: Checking MMKV initialization...');

      final mmkv = MMKV.defaultMMKV();

      print('✅ MMKV instance exists');
      _updateDebugInfo('MMKV: Initialized');

      // Test basic operations
      print('🔍 Step 2: Testing MMKV basic operations...');
      try {
        mmkv.encodeBool('test_splash', true);
        final testRead = mmkv.decodeBool('test_splash', defaultValue: false);
        print('✅ MMKV read/write test: $testRead');
        mmkv.removeValue('test_splash'); // cleanup
        _updateDebugInfo('MMKV: Read/Write OK');
      } catch (e) {
        print('❌ MMKV read/write test failed: $e');
        _updateDebugInfo('MMKV: R/W Error - $e');
      }

      // Check existing keys
      print('🔍 Step 3: Checking existing keys...');
      final allKeys = mmkv.allKeys;
      final keyCount = mmkv.count;
      print('🔍 All keys: $allKeys');
      print('🔍 Total count: $keyCount');
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
            print('🔍 $key: $value');
          } else {
            final value = mmkv.decodeString(key) ?? 'NULL';
            print('🔍 $key: "$value"');
          }
        } else {
          print('🔍 $key: NOT FOUND');
        }
      }
    } catch (e) {
      print('❌ MMKV detailed debug error: $e');
      _updateDebugInfo('MMKV Error: $e');
    }
  }

  Future<void> _initializeApp() async {
    print('🚀 Starting app initialization...');
    try {
      _updateStatus('Menginisialisasi aplikasi...');
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) {
        print('⚠️ Widget not mounted, stopping initialization');
        return;
      }

      _updateStatus('Memeriksa MMKV...');

      // Test LoginPreferences health
      print('🔍 Testing LoginPreferences health...');
      final isHealthy = await LoginPreferences.checkHealth();
      print('🔍 LoginPreferences health: $isHealthy');
      _updateDebugInfo('LoginPrefs: ${isHealthy ? 'OK' : 'Failed'}');

      if (!isHealthy) {
        print('⚠️ LoginPreferences unhealthy, proceeding to login');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _navigateToLogin();
        }
        return;
      }

      _updateStatus('Memeriksa status login...');

      // Check login status
      print('🔍 Checking login status...');
      final isLoggedIn = await LoginPreferences.isLoggedIn();
      final username = await LoginPreferences.getUsername();

      print(
        '🔍 Login check result: isLoggedIn=$isLoggedIn, username="$username"',
      );
      _updateDebugInfo('Login: $isLoggedIn, User: $username');

      if (!mounted) {
        print('⚠️ Widget not mounted after login check');
        return;
      }

      if (isLoggedIn && username != null && username.isNotEmpty) {
        _updateStatus('Selamat datang kembali, $username!');
        print('✅ User is logged in, navigating to home');
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          _navigateToHome(username);
        }
      } else {
        _updateStatus('Silakan login...');
        print('ℹ️ User not logged in, navigating to login');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _navigateToLogin();
        }
      }
    } catch (e) {
      print('💥 Initialization error: $e');
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
    print('📱 Status Update: $message');
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  void _updateDebugInfo(String info) {
    print('🐛 Debug Info: $info');
    if (mounted) {
      setState(() {
        _debugInfo = info;
      });
    }
  }

  void _navigateToHome(String username) {
    print('🏠 Navigating to HomeScreen for: $username');

    if (!mounted) {
      print('⚠️ Widget not mounted, cannot navigate to home');
      return;
    }

    try {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(username: username)),
      );
      print('✅ Navigation to home completed');
    } catch (e) {
      print('❌ Navigation to home error: $e');
      _navigateToLogin(); // fallback
    }
  }

  void _navigateToLogin() {
    print('🔐 Navigating to LoginScreen');

    if (!mounted) {
      print('⚠️ Widget not mounted, cannot navigate to login');
      return;
    }

    try {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
      print('✅ Navigation to login completed');
    } catch (e) {
      print('❌ Navigation to login error: $e');
      _updateStatus('Error navigasi: $e');
    }
  }

  @override
  void dispose() {
    print('🗑️ SplashScreen disposing...');
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE53E3E), Color(0xFFD53F8C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _logoAnimation.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          50,
                        ), // Agar gambar juga membulat
                        child: Image(
                          image: AssetImage('assets/img/molah.png'),
                          fit: BoxFit
                              .contain, // Gambar akan menyesuaikan proporsional di dalam container
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedBuilder(
                  animation: _textAnimation,
                  builder: (context, child) => Opacity(
                    opacity: _textAnimation.value,
                    child: Column(
                      children: const [
                        Text(
                          'MOLAH',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Aplikasi Monitoring Santri',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Debug info untuk troubleshooting
                if (_debugInfo.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Pesantren Islam Zaid bin Tsabit',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
                    'MOLAH v2.0.0 - Powered by Pizab',
                    style: TextStyle(fontSize: 10, color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Emergency bypass button untuk debugging
              ],
            ),
          ),
        ),
      ),
    );
  }
}
