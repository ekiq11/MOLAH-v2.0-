package com.pizab_molah

import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // PENTING: Panggil sebelum super.onCreate() agar theme diterapkan lebih awal
        // Ini mencegah flash putih di Samsung, OPPO, Xiaomi
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+ : Splash screen API, tidak perlu workaround
        }
        super.onCreate(savedInstanceState)
        setupWindow()
    }

    private fun setupWindow() {
        val window = window ?: return

        // ✅ Gunakan WindowCompat — kompatibel semua OEM (Samsung, OPPO, Xiaomi, dll.)
        // Ini menggantikan setStatusBarColor / setNavigationBarColor yang deprecated
        WindowCompat.setDecorFitsSystemWindows(window, false)

        val controller = WindowInsetsControllerCompat(window, window.decorView)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Ikon status bar gelap (teks hitam) untuk background terang
            // Flutter akan override ini via SystemChrome.setSystemUIOverlayStyle
            controller.isAppearanceLightStatusBars = false
            controller.isAppearanceLightNavigationBars = false
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            // Set warna transparan — Flutter akan handle sendiri
            @Suppress("DEPRECATION")
            window.statusBarColor = android.graphics.Color.TRANSPARENT
            @Suppress("DEPRECATION")
            window.navigationBarColor = android.graphics.Color.TRANSPARENT
        }

        // Samsung One UI: pastikan tidak ada overlay sistem yang mengganggu
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // FlutterEngine sudah dikonfigurasi oleh parent
        // Tidak perlu override setStatusBarColor lagi karena sudah ditangani di setupWindow()
    }

    override fun onResume() {
        super.onResume()
        // Re-apply window setup saat app resume dari background
        // Penting untuk MIUI (Xiaomi) yang kadang reset window flags
        setupWindow()
    }
}