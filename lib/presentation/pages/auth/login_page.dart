import 'package:expense/presentation/widgets/app_shell.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/presentation/blocs/auth/auth_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/pages/auth/verification_code_validator.dart';
import 'package:pinput/pinput.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _codeSent = false;
  String _email = '';
  String? _error; // inline, announced as an alert
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_isLoading) return;
    final email = _emailController.text.trim();
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = 'email_invalid'.tr());
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await context.read<AuthCubit>().sendMagicCode(email);
      if (mounted) {
        setState(() {
          _email = email;
          _codeSent = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'unexpected_error'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_isLoading) return;
    final code = _codeController.text.trim();
    if (!isValidVerificationCode(code)) {
      setState(() => _error = 'verification_code_length'.tr());
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await context.read<AuthCubit>().verifyMagicCode(_email, code);
      // Router redirect reacts to auth state change; nothing else to do.
    } catch (e) {
      if (mounted) setState(() => _error = 'unexpected_error'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await context.read<AuthCubit>().signInWithGoogle();
    } catch (_) {
      if (mounted) _showError('google_sign_in_failed'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _toggleLanguage() {
    final newLocale = context.locale.languageCode == 'en'
        ? const Locale('fr')
        : const Locale('en');
    context.read<SettingsCubit>().changeLanguage(newLocale.languageCode);
    context.setLocale(newLocale);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

    Widget errorText() => Semantics(
      liveRegion: true,
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 20),
          child: _error == null
              ? const SizedBox.shrink()
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: scheme.error,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    Widget primaryButton(String label, VoidCallback onPressed, {bool arrow = false}) =>
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _isLoading ? null : onPressed,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (arrow) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ],
                ),
        );

    final emailStep = <Widget>[
      Text('email_address'.tr(), style: labelStyle),
      const SizedBox(height: 6),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        textInputAction: TextInputAction.done,
        autocorrect: false,
        enableSuggestions: false,
        onSubmitted: (_) => _sendCode(),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        decoration: InputDecoration(
          hintText: 'email_placeholder'.tr(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          enabledBorder: _error == null
              ? null
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: scheme.error, width: 1.5),
                ),
        ),
      ),
      errorText(),
      const SizedBox(height: 14),
      primaryButton('send_code'.tr(), _sendCode, arrow: true),
      if (context.read<AuthCubit>().isGoogleSignInAvailable) ...[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or'.tr(), style: theme.textTheme.bodySmall),
              ),
              const Expanded(child: Divider()),
            ],
          ),
        ),
        OutlinedButton.icon(
          key: const ValueKey('google-sign-in-button'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: _isLoading ? null : _signInWithGoogle,
          icon: Image.asset(
            'assets/images/google_g.png',
            width: 18,
            height: 18,
            excludeFromSemantics: true,
          ),
          label: Text('continue_with_google'.tr()),
        ),
      ],
    ];

    final codeStep = <Widget>[
      Text('verification_code'.tr(), style: labelStyle),
      const SizedBox(height: 8),
      LayoutBuilder(
        builder: (context, box) {
          const gap = 8.0;
          final width = ((box.maxWidth - gap * (verificationCodeLength - 1)) /
                  verificationCodeLength)
              .clamp(36.0, 52.0);
          PinTheme pin(Color border, {double borderWidth = 1.5}) => PinTheme(
            width: width,
            height: 56,
            textStyle: theme.textTheme.titleLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              border: Border.all(color: border, width: borderWidth),
              borderRadius: BorderRadius.circular(14),
            ),
          );
          return Align(
            alignment: Alignment.centerLeft,
            child: Pinput(
              key: const ValueKey('magic-code-pinput'),
              controller: _codeController,
              length: verificationCodeLength,
              enabled: !_isLoading,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              separatorBuilder: (_) => const SizedBox(width: gap),
              forceErrorState: _error != null,
              defaultPinTheme: pin(theme.dividerColor),
              focusedPinTheme: pin(AppTheme.link(context), borderWidth: 2),
              errorPinTheme: pin(scheme.error),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onCompleted: (_) => _verifyCode(),
            ),
          );
        },
      ),
      const SizedBox(height: 8),
      Text('code_sent_to'.tr(args: [_email]), style: theme.textTheme.bodySmall),
      errorText(),
      const SizedBox(height: 14),
      primaryButton('verify'.tr(), _verifyCode),
      const SizedBox(height: 8),
      TextButton(
        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(44)),
        onPressed: _isLoading ? null : _resendCode,
        child: Text('resend_code'.tr()),
      ),
      TextButton(
        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(44)),
        onPressed: _isLoading
            ? null
            : () => setState(() {
                _codeSent = false;
                _error = null;
                _codeController.clear();
              }),
        child: Text('change_email'.tr()),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ExpenseBrand(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'theme'.tr(),
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    icon: Icon(
                      theme.brightness == Brightness.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 20,
                    ),
                    onPressed: () => context.read<SettingsCubit>().changeTheme(
                      theme.brightness == Brightness.dark
                          ? ThemeMode.light
                          : ThemeMode.dark,
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                    onPressed: _toggleLanguage,
                    child: Text(context.locale.languageCode.toUpperCase()),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Semantics(
                header: true,
                child: Text(
                  (_codeSent ? 'auth_check_mail' : 'auth_welcome').tr(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 34,
                    height: 1.08,
                    letterSpacing: -1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (_codeSent ? 'code_step_subtitle' : 'login_subtitle_nopass')
                    .tr(),
                style: muted,
              ),
              const SizedBox(height: 28),
              ..._codeSent ? codeStep : emailStep,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AuthCubit>().sendMagicCode(_email);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('code_resent'.tr())));
      }
    } catch (_) {
      if (mounted) _showError('unexpected_error'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
