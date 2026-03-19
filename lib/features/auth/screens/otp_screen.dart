import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/auth_storage.dart';
import '../../../core/services/auth_service.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final VoidCallback onBack;

  const OtpScreen({super.key, required this.phoneNumber, required this.onBack});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  bool _focused = false;
  bool _verifying = false;
  bool _resending = false;
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _otpFocusNode.addListener(() {
      setState(() => _focused = _otpFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _resendSeconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        t.cancel();
      }
    });
  }

  String get _maskedPhone {
    final n = widget.phoneNumber;
    if (n.length == 10) return '+91 ${n.substring(0, 5)}XXXXX';
    return '+91 $n';
  }

  bool get _otpComplete => _otpController.text.length == 4;

  Future<void> _verify() async {
    if (!_otpComplete || _verifying) return;
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);
    try {
      final result = await ref
          .read(authServiceProvider)
          .verifyOtp(widget.phoneNumber, _otpController.text);
      if (!mounted) return;
      await ref.read(authTokenProvider.notifier).setTokens(
            result.accessToken,
            result.refreshToken,
            expiresInSeconds: result.expiresIn,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _verifying = false);
      _otpController.clear();
      _otpFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _resend() async {
    if (_resendSeconds > 0 || _resending) return;
    setState(() => _resending = true);
    try {
      await ref.read(authServiceProvider).sendOtp(widget.phoneNumber);
      if (!mounted) return;
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent via SMS!'),
          backgroundColor: AppColors.primary,
        ),
      );
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
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            'Log in',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.sms_outlined,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Check your messages for OTP',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _maskedPhone,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: widget.onBack,
                                child: Text(
                                  'edit',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.lime,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _OtpInput(
                            controller: _otpController,
                            focusNode: _otpFocusNode,
                            focused: _focused,
                            complete: _otpComplete,
                            verifying: _verifying,
                            onVerify: _verify,
                            onChanged: (v) {
                              setState(() {});
                              if (v.length == 4) _verify();
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Didn't get it? Resend via SMS",
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _resendSeconds == 0 ? _resend : null,
                                child: Text(
                                  _resendSeconds > 0
                                      ? '0:${_resendSeconds.toString().padLeft(2, '0')}'
                                      : (_resending ? '...' : 'Resend'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _resendSeconds > 0
                                        ? Colors.grey
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          if (_verifying) ...[
                            const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Verifying...',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Waiting for SMS OTP...',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
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
}

class _OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final bool complete;
  final bool verifying;
  final VoidCallback onVerify;
  final ValueChanged<String> onChanged;

  const _OtpInput({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.complete,
    required this.verifying,
    required this.onVerify,
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
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 4,
                    enabled: !verifying,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 12,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '----',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 22,
                        letterSpacing: 12,
                        color: Colors.grey.shade400,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: onChanged,
                  ),
                ),
              ),
              GestureDetector(
                onTap: verifying ? null : onVerify,
                child: Container(
                  width: 50,
                  alignment: Alignment.center,
                  color: complete && !verifying
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  child: verifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
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
