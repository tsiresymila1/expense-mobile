import 'package:expense/presentation/widgets/app_shell.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
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
  final _formKey = GlobalKey<FormBuilderState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _codeSent = false;
  String _email = '';

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    setState(() => _isLoading = true);
    final email = (_formKey.currentState!.value['email'] as String).trim();
    try {
      await context.read<AuthCubit>().sendMagicCode(email);
      if (mounted) {
        setState(() {
          _email = email;
          _codeSent = true;
        });
      }
    } catch (e) {
      _showError('unexpected_error'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final code = _codeController.text.trim();
    if (!isValidVerificationCode(code)) {
      _showError('verification_code_length'.tr());
      return;
    }
    setState(() => _isLoading = true);
    try {
      await context.read<AuthCubit>().verifyMagicCode(_email, code);
      // Router redirect reacts to auth state change; nothing else to do.
    } catch (e) {
      _showError('unexpected_error'.tr());
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const ExpenseBrand(),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
        actions: [
          IconButton(
            tooltip: 'theme'.tr(),
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 19,
            ),
            onPressed: () => context.read<SettingsCubit>().changeTheme(
              theme.brightness == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
          ),
          TextButton(
            onPressed: _toggleLanguage,
            child: Text(context.locale.languageCode.toUpperCase()),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_codeSent)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                              _codeSent = false;
                              _codeController.clear();
                            }),
                      child: Text('change_email'.tr()),
                    ),
                  ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _codeSent
                          ? Icons.mail_outline
                          : Icons.account_balance_wallet_outlined,
                      color: AppTheme.link(context),
                      size: 25,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  (_codeSent ? 'auth_code_heading' : 'auth_heading').tr(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 34,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _codeSent
                      ? '${'enter_code_subtitle'.tr()}\n$_email'
                      : 'auth_intro'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 28),
                if (!_codeSent)
                  FormBuilderTextField(
                    name: 'email',
                    decoration: InputDecoration(labelText: 'email'.tr()),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.email(),
                    ]),
                  ),
                if (_codeSent) ...[
                  Text(
                    'verification_code'.tr(),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Pinput(
                    key: const ValueKey('magic-code-pinput'),
                    controller: _codeController,
                    length: verificationCodeLength,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    defaultPinTheme: PinTheme(
                      width: 44,
                      height: 58,
                      textStyle: theme.textTheme.titleLarge,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    validator: (v) => verificationCodeValidationKey(v)?.tr(),
                    onCompleted: (_) => _verifyCode(),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_codeSent ? _verifyCode : _sendCode),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text((_codeSent ? 'verify' : 'send_code').tr()),
                ),
                if (_codeSent)
                  TextButton(
                    onPressed: _isLoading ? null : _resendCode,
                    child: Text('resend_code'.tr()),
                  ),
                if (!_codeSent &&
                    context.read<AuthCubit>().isGoogleSignInAvailable) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or'.tr(),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('google-sign-in-button'),
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
              ],
            ),
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
