import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/auth_storage.dart';
import '../../../core/services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final void Function(String phoneNumber) onOtpSent;

  const LoginScreen({super.key, required this.onOtpSent});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();

  bool _focused = false;
  bool _sending = false;
  bool _isTruecallerLoading = false;

  bool _isCheckingTruecaller = true;
  bool _isTruecallerAvailable = false;
  bool _forceManualInput = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      setState(() => _focused = _phoneFocusNode.hasFocus);
    });
    // Defer SDK init until after the first frame so Android's onAttachedToActivity has fired.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initTruecaller());
  }

  Future<void> _initTruecaller() async {
    await ref.read(authServiceProvider).initializeTruecallerForLogin();
    if (!mounted) return;
    setState(() {
      _isCheckingTruecaller = false;
      _isTruecallerAvailable =
          ref.read(authServiceProvider).isTruecallerAvailable;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  bool get _phoneValid => _phoneController.text.length == 10;

  Future<void> _handleTruecallerLogin() async {
    setState(() => _isTruecallerLoading = true);
    FocusScope.of(context).unfocus();

    try {
      final service = ref.read(authServiceProvider);

      final sdkResult = await service.loginWithTruecaller();

      if (!mounted) return;

      if (!sdkResult.success || sdkResult.authorizationCode == null) {
        return;
      }

      final result =
          await service.verifyTruecallerCode(sdkResult.authorizationCode!);

      if (!mounted) return;

      await ref.read(authTokenProvider.notifier).setTokens(
            result.accessToken,
            result.refreshToken,
            expiresInSeconds: result.expiresIn,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.profile.firstName != null
                  ? 'Welcome, ${result.profile.firstName}!'
                  : 'Logged in successfully!',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTruecallerLoading = false);
    }
  }

  Future<void> _handleSendOtp() async {
    if (!_phoneValid || _sending) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      await ref.read(authServiceProvider).sendOtp(_phoneController.text);
      if (mounted) widget.onOtpSent(_phoneController.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showTruecaller = _isTruecallerAvailable && !_forceManualInput;

    return Scaffold(
      backgroundColor: AppColors.lime,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 1),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Admin Login',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // App logo
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: Image.asset(
                              'assets/icons/bajaru_admin_icon.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.admin_panel_settings,
                                size: 96,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          _buildAuthContent(showTruecaller, _isCheckingTruecaller),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        'Bajaru Admin',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAuthContent(bool showTruecaller, bool isChecking) {
    if (showTruecaller) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TruecallerButton(
            onPressed: _handleTruecallerLogin,
            isLoading: _isTruecallerLoading,
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => setState(() => _forceManualInput = true),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Use another mobile number',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PhoneInput(
          controller: _phoneController,
          focusNode: _phoneFocusNode,
          focused: _focused,
          valid: _phoneValid,
          sending: _sending,
          onSubmit: _handleSendOtp,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sms_outlined,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'We will send an OTP via SMS',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        if (isChecking) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey.shade400,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Checking faster login options…',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

const Color _truecallerBlue = Color(0xFF0087FF);

class _TruecallerButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _TruecallerButton({required this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _truecallerBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _truecallerBlue.withValues(alpha: 0.6),
              elevation: 2,
              shadowColor: _truecallerBlue.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/TrueCaller_Icon.png',
                        width: 28,
                        height: 28,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.phone,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'One-Tap Login',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'powered by ',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            Image.asset(
              'assets/icons/TrueCaller_Logo.png',
              height: 14,
              errorBuilder: (_, __, ___) => Text(
                'truecaller',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _truecallerBlue,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PhoneInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final bool valid;
  final bool sending;
  final VoidCallback onSubmit;
  final ValueChanged<String> onChanged;

  const _PhoneInput({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.valid,
    required this.sending,
    required this.onSubmit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderW = focused ? 2.0 : 1.0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused ? AppColors.lime : Colors.grey.shade300,
          width: borderW,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12 - borderW),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 70,
                alignment: Alignment.center,
                color: Colors.grey.shade100,
                child: Text(
                  '+91',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Phone Number',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      counterText: '',
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: onChanged,
                    onSubmitted: (_) => onSubmit(),
                  ),
                ),
              ),
              GestureDetector(
                onTap: sending ? null : onSubmit,
                child: Container(
                  width: 50,
                  alignment: Alignment.center,
                  color: valid && !sending
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  child: sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
