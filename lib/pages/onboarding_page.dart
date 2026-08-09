import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/translations.dart';
import '../services/locale_service.dart';
import '../services/open_router_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final TextEditingController _tokenController = TextEditingController();
  int _currentPage = 0;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch URL')),
        );
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);

    if (_tokenController.text.trim().isNotEmpty) {
      await settings.setApiToken(_tokenController.text.trim());
    }

    if (mounted) {
      context.read<LocaleProvider>().setTutorialComplete(true);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Translations.of(context);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.7),
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
                child: Row(
                  children: [
                    const Text(
                      'AI Mind',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: AppColors.accentLight,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted),
                      child: Text(l10n.skip),
                    ),
                  ],
                ),
              ),

              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _Step1(
                      l10n: l10n,
                      onLogin: () => _launchUrl('https://openrouter.ai/sign-in'),
                      onRegister: () => _launchUrl('https://openrouter.ai/sign-up'),
                    ),
                    _Step2(
                      l10n: l10n,
                      onAction: () => _launchUrl(
                          'https://openrouter.ai/settings/keys')),
                    _Step3(l10n: l10n, controller: _tokenController),
                  ],
                ),
              ),

              // Bottom Navigation
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    _currentPage > 0
                        ? IconButton(
                            onPressed: () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                            ),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 20),
                            color: AppColors.textSecondary,
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.surfaceLight,
                              padding: const EdgeInsets.all(12),
                            ),
                          )
                        : const SizedBox(width: 48),

                    // Indicators
                    Row(
                      children: List.generate(3, (index) {
                        final isActive = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          width: isActive ? 20 : 6,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.accent
                                : AppColors.surfaceBorder,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),

                    // Next/Finish Button
                    GestureDetector(
                      onTap: () {
                        if (_currentPage < 2) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: AppColors.gradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPage < 2 ? l10n.next : l10n.finish,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage < 2
                                  ? Icons.arrow_forward_rounded
                                  : Icons.check_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
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

class _Step1 extends StatelessWidget {
  const _Step1({
    required this.l10n,
    required this.onLogin,
    required this.onRegister,
  });
  final Translations l10n;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return _OnboardingTemplate(
      title: l10n.get('onboarding_1_title'),
      description: l10n.get('onboarding_1_desc'),
      icon: Icons.person_add_rounded,
      content: Column(
        children: [
          const _ScreenshotCard(
            imagePath: 'tutorial/1.png',
            label: 'Login/Register',
            height: 320, // Увеличили высоту
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceLight,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.surfaceBorder),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.login,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                    foregroundColor: AppColors.accentLight,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                          color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.register,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Step2 extends StatefulWidget {
  const _Step2({required this.l10n, required this.onAction});
  final Translations l10n;
  final VoidCallback onAction;

  @override
  State<_Step2> createState() => _Step2State();
}

class _Step2State extends State<_Step2> {
  final PageController _galleryController = PageController();
  int _activeImage = 0;

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = ['tutorial/2.png', 'tutorial/3.png'];
    final labels = ['API Keys Settings', 'Create Key'];

    return _OnboardingTemplate(
      title: widget.l10n.get('onboarding_2_title'),
      description: widget.l10n.get('onboarding_2_desc'),
      icon: Icons.vpn_key_rounded,
      content: Column(
        children: [
          // Галерея скриншотов
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 320, // Увеличили высоту галереи
                child: PageView.builder(
                  controller: _galleryController,
                  onPageChanged: (idx) => setState(() => _activeImage = idx),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _ScreenshotCard(
                        imagePath: images[index],
                        label: labels[index],
                        height: 320, // Увеличили высоту карточки
                      ),
                    );
                  },
                ),
              ),

              // Кнопки навигации (для десктопа/удобства)
              if (images.length > 1) ...[
                Positioned(
                  left: -10,
                  child: _GalleryNavButton(
                    icon: Icons.chevron_left_rounded,
                    onPressed: _activeImage > 0
                        ? () => _galleryController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut)
                        : null,
                  ),
                ),
                Positioned(
                  right: -10,
                  child: _GalleryNavButton(
                    icon: Icons.chevron_right_rounded,
                    onPressed: _activeImage < images.length - 1
                        ? () => _galleryController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut)
                        : null,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Индикаторы галереи
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 4,
                width: _activeImage == index ? 12 : 4,
                decoration: BoxDecoration(
                  color: _activeImage == index
                      ? AppColors.accentLight
                      : AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),

          const SizedBox(height: 20), // Уменьшили с 32 до 20
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onAction,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(widget.l10n.getKey),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceLight,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.surfaceBorder),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryNavButton extends StatelessWidget {
  const _GalleryNavButton({required this.icon, this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0 : 1,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        color: Colors.white,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.4),
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }
}

class _Step3 extends StatefulWidget {
  const _Step3({required this.l10n, required this.controller});
  final Translations l10n;
  final TextEditingController controller;

  @override
  State<_Step3> createState() => _Step3State();
}

class _Step3State extends State<_Step3> {
  bool _isVerifying = false;
  bool _isValid = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTokenChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTokenChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onTokenChanged() {
    final token = widget.controller.text.trim();
    if (token.isEmpty) {
      setState(() {
        _isValid = false;
        _error = null;
        _isVerifying = false;
      });
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      _verifyToken(token);
    });
  }

  Future<void> _verifyToken(String token) async {
    if (!token.startsWith('sk-or-v1-')) {
      setState(() {
        _isValid = false;
        _error = 'Invalid token format';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final service = OpenRouterService();

      // Сначала сохраняем как основной ключ
      await settings.setApiToken(token);

      // Проверяем баланс как способ верификации ключа
      await service.fetchBalance(token);

      if (mounted) {
        setState(() {
          _isVerifying = false;
          _isValid = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _isValid = false;
          _error = 'Verification failed. Please check your key.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _OnboardingTemplate(
      title: widget.l10n.get('onboarding_3_title'),
      description: widget.l10n.get('onboarding_3_desc'),
      icon: Icons.input_rounded,
      content: Column(
        children: [
          const _ScreenshotCard(
            imagePath: 'tutorial/4.png',
            label: 'Settings Field',
            height: 280,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: widget.controller,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.l10n.get('enter_key_hint'),
              prefixIcon: const Icon(Icons.vpn_key_rounded,
                  color: AppColors.accentLight),
              suffixIcon: _isVerifying
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.accent),
                    )
                  : (_isValid
                      ? const Icon(Icons.check_circle_rounded,
                          color: Colors.greenAccent)
                      : null),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.all(20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
              ),
            ),
          ),
          if (_isValid) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_outline_rounded,
                      color: Colors.greenAccent, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'API Key is valid and saved!',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _OnboardingTemplate extends StatelessWidget {
  const _OnboardingTemplate({
    required this.title,
    required this.description,
    required this.content,
    required this.icon,
  });

  final String title;
  final String description;
  final Widget content;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(), // Заменили Bouncing на Clamping
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center, // Центрируем колонку
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.accentLight, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              content,
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScreenshotCard extends StatelessWidget {
  const _ScreenshotCard({
    required this.label,
    this.height, // Сделали высоту опциональной
    this.imagePath,
  });
  final String label;
  final double? height;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        height: height,
        constraints: height == null
            ? const BoxConstraints(maxHeight: 300) // Максимальный лимит если высота не задана
            : null,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1924),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder, width: 1),
        ),
        child: Stack(
          children: [
            if (imagePath != null)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.asset(
                    imagePath!,
                    fit: BoxFit.contain, // Сохраняем пропорции, не обрезаем
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(Icons.error_outline_rounded,
                            color: Colors.redAccent.withValues(alpha: 0.5),
                            size: 24),
                      );
                    },
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_outlined,
                        color: AppColors.textMuted.withValues(alpha: 0.4),
                        size: 32),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'GUIDE',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
