import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/repository/auth_repository.dart';
import '../../provider/auth_usecase_providers.dart';
import '../widget/auth_provider_button.dart';
import '../widget/login_brand_block.dart';

/// 登录页(stub 协议:无定稿设计,功能优先)。
/// 结构:品牌区 → 第三方登录(Apple 按钮位预留,E1-Apple 落地后置于 Google 上方)
/// → 分隔 → 邮箱/密码折叠表单(登录/注册切换 + 忘记密码)。
class LoginPageView extends ConsumerStatefulWidget {
  const LoginPageView({super.key});

  @override
  ConsumerState<LoginPageView> createState() => _LoginPageViewState();
}

class _LoginPageViewState extends ConsumerState<LoginPageView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isEmailFormExpanded = false;
  bool _isRegisterMode = false;
  bool _isSubmittingEmail = false;
  bool _isSubmittingGoogle = false;
  String? _errorMessage;
  String? _infoMessage;

  bool get _isBusy => _isSubmittingEmail || _isSubmittingGoogle;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSubmittingGoogle = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      await ref.read(signInWithGoogleUsecaseProvider).execute();
    } on AuthCancelledException {
      // 用户主动取消,静默返回。
    } on FirebaseAuthException catch (error) {
      _showError(error.message ?? 'Google 登录失败,请重试。');
    } catch (_) {
      _showError('Google 登录失败,请重试。');
    } finally {
      if (mounted) {
        setState(() => _isSubmittingGoogle = false);
      }
    }
  }

  Future<void> _submitEmailForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmittingEmail = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (_isRegisterMode) {
        await ref
            .read(registerUsecaseProvider)
            .execute(email: email, password: password);
      } else {
        await ref
            .read(signInUsecaseProvider)
            .execute(email: email, password: password);
      }
    } on FirebaseAuthException catch (error) {
      _showError(error.message ?? '认证失败,请重试。');
    } catch (_) {
      _showError('发生未知错误,请重试。');
    } finally {
      if (mounted) {
        setState(() => _isSubmittingEmail = false);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('请先在邮箱栏填写有效邮箱,再点击「忘记密码」。');
      return;
    }
    setState(() {
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      await ref.read(sendPasswordResetUsecaseProvider).execute(email: email);
      if (!mounted) {
        return;
      }
      setState(() {
        _infoMessage = '重置邮件已发送至 $email,请查收。';
      });
    } on FirebaseAuthException catch (error) {
      _showError(error.message ?? '重置邮件发送失败,请重试。');
    } catch (_) {
      _showError('重置邮件发送失败,请重试。');
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _errorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.bgApp,
      // 顶部 lime 径向环境光(#19a)
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1,
            colors: [
              colors.primaryMain.withValues(alpha: CoFitOpacities.faint),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(CoFitDimens.spacing2xl),
            child: ConstrainedBox(
              // 大屏(iPad/横屏)下表单不无限拉宽,取 iPhone 视口级宽度。
              constraints:
                  const BoxConstraints(maxWidth: CoFitDimens.sizeAuthFormMaxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 品牌区(#19a):bob 小人 + 两侧斜插卡牌
                  const Center(child: LoginBrandBlock()),
                  const SizedBox(height: CoFitDimens.spacingSm),
                  Text(
                    'CoFit',
                    textAlign: TextAlign.center,
                    style: textTheme.displaySmall?.copyWith(
                      color: colors.primaryMain,
                      fontWeight: CoFitFontWeights.heading,
                    ),
                  ),
                  const SizedBox(height: CoFitDimens.spacingXs),
                  Text(
                    '和朋友在同一间虚拟健身房',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: CoFitDimens.spacing3xl),
                  // E1-Apple:Apple 登录按钮预留位(HIG 要求置于最上方,
                  // gray-50 底 + gray-950 字;未启用期整行隐藏不留洞)。
                  AuthProviderButton(
                    icon: Icon(
                      Icons.g_mobiledata_rounded,
                      color: colors.textPrimary,
                      size: CoFitDimens.sizeBannerIcon,
                    ),
                    label: '使用 Google 登录',
                    isLoading: _isSubmittingGoogle,
                    onPressed: _isBusy ? null : _signInWithGoogle,
                  ),
                  const SizedBox(height: CoFitDimens.spacingXl),
                  Row(
                    children: [
                      Expanded(child: Divider(color: colors.borderStrong)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CoFitDimens.spacingMd,
                        ),
                        child: Text(
                          '或',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: colors.borderStrong)),
                    ],
                  ),
                  const SizedBox(height: CoFitDimens.spacingXl),
                  if (!_isEmailFormExpanded)
                    SizedBox(
                      height: CoFitDimens.sizeMinTapTarget,
                      child: TextButton(
                        onPressed: _isBusy
                            ? null
                            : () =>
                                setState(() => _isEmailFormExpanded = true),
                        child: Text(
                          '使用邮箱登录',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ),
                    )
                  else
                    _buildEmailForm(colors),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: CoFitDimens.spacingMd),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.statusDanger),
                    ),
                  ],
                  if (_infoMessage != null) ...[
                    const SizedBox(height: CoFitDimens.spacingMd),
                    Text(
                      _infoMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.statusInfo),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(CoFitColors colors) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            enabled: !_isBusy,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: '邮箱',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) {
                return '请输入邮箱。';
              }
              if (!text.contains('@')) {
                return '请输入有效邮箱。';
              }
              return null;
            },
          ),
          const SizedBox(height: CoFitDimens.spacingMd),
          TextFormField(
            controller: _passwordController,
            enabled: !_isBusy,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '密码',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) {
                return '请输入密码。';
              }
              if (text.length < 6) {
                return '密码至少 6 位。';
              }
              return null;
            },
          ),
          const SizedBox(height: CoFitDimens.spacingLg),
          SizedBox(
            height: CoFitDimens.sizeMinTapTarget,
            child: FilledButton(
              onPressed: _isBusy ? null : _submitEmailForm,
              child: _isSubmittingEmail
                  ? SizedBox(
                      width: CoFitDimens.spacingLg,
                      height: CoFitDimens.spacingLg,
                      child: CircularProgressIndicator(
                        strokeWidth: CoFitDimens.borderWidthFocus,
                        color: colors.primaryOn,
                      ),
                    )
                  : Text(_isRegisterMode ? '注册' : '登录'),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _isBusy
                    ? null
                    : () {
                        setState(() {
                          _isRegisterMode = !_isRegisterMode;
                          _errorMessage = null;
                          _infoMessage = null;
                        });
                      },
                child: Text(
                  _isRegisterMode ? '已有账号?登录' : '没有账号?注册',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              if (!_isRegisterMode)
                TextButton(
                  onPressed: _isBusy ? null : _sendPasswordReset,
                  child: Text(
                    '忘记密码',
                    style: TextStyle(color: colors.textTertiary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
