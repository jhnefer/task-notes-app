import 'package:app/models/models.dart';
import 'package:app/services/api_client.dart';
import 'package:app/themes/app_colors.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    this.apiClient,
    this.onAuthenticated,
    this.onUserAuthenticated,
    this.onContinueOffline,
    super.key,
  });

  final ApiClient? apiClient;
  final void Function(String username)? onAuthenticated;
  final void Function(User user)? onUserAuthenticated;
  final VoidCallback? onContinueOffline;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final api = widget.apiClient;

    try {
      User user;
      if (api != null) {
        user = _isLogin
            ? await api.login(username, password)
            : await api.register(username, password);
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        user = User(id: 'local-$username', username: username);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isLogin
                ? 'Conectado! Sincronizando dados em segundo plano...'
                : 'Conta criada! Sincronizando seus dados locais...',
          ),
        ),
      );
      widget.onUserAuthenticated?.call(user);
      widget.onAuthenticated?.call(user.username);
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      final serverMsg = e.response?.data is String
          ? e.response?.data as String
          : null;
      setState(() {
        _isLoading = false;
        if (status == 401) {
          _errorMessage = 'Usuário ou senha incorretos.';
        } else if (status == 400 && serverMsg != null && serverMsg.isNotEmpty) {
          _errorMessage = serverMsg;
        } else {
          _errorMessage =
              'Servidor inacessível no momento. Você pode continuar usando o app 100% offline.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Não foi possível conectar ao servidor. Seus dados continuam salvos localmente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final cardBg = isDark
        ? AppColors.darkCardBackground
        : AppColors.cardBackGround;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.border;
    final textPrimary = isDark ? AppColors.darkOnSurface : AppColors.onPrimary;
    final textMuted = isDark ? AppColors.darkOnMuted : AppColors.onMuted;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo Circle
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.cloudUpload,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        'Sincronização na Nuvem',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                      ),
                      const SizedBox(height: 6),

                      // Subtitle
                      Text(
                        'Conecte uma conta para sincronizar em segundo plano. Tudo o que você já criou offline será preservado.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.destructive.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.destructive.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 12,
                              color: AppColors.destructive,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Username
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Usuário',
                          style: TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _usernameController,
                        style: TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 14,
                          color: textPrimary,
                        ),
                        decoration: _inputDecoration(
                          'Seu nome de usuário',
                          bgColor,
                          borderColor,
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Informe seu usuário'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Senha',
                          style: TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 14,
                          color: textPrimary,
                        ),
                        decoration: _inputDecoration(
                          '••••••••',
                          bgColor,
                          borderColor,
                        ),
                        validator: (val) => (val == null || val.isEmpty)
                            ? 'Informe sua senha'
                            : null,
                      ),
                      const SizedBox(height: 22),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoading) ...[
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                _isLogin
                                    ? 'Entrar e Sincronizar'
                                    : 'Criar Conta e Sincronizar',
                                style: const TextStyle(
                                  fontFamily: 'Lora',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Toggle Login/Register
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          Text(
                            _isLogin
                                ? 'Ainda não tem uma conta?'
                                : 'Já possui uma conta?',
                            style: TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isLogin = !_isLogin),
                            child: Text(
                              _isLogin ? 'Cadastre-se' : 'Faça Login',
                              style: const TextStyle(
                                fontFamily: 'Lora',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (widget.onContinueOffline != null) ...[
                        const SizedBox(height: 16),
                        Divider(color: borderColor),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: widget.onContinueOffline,
                          icon: Icon(
                            LucideIcons.arrowLeft,
                            size: 15,
                            color: textMuted,
                          ),
                          label: Text(
                            'Continuar usando somente offline',
                            style: TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 12.5,
                              color: textMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    Color bgColor,
    Color borderColor,
  ) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: bgColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
    );
  }
}
