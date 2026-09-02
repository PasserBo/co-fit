import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/entity/user_profile_entity.dart';
import '../../provider/user_profile_repository_provider.dart';

/// 首登 onboarding(stub 协议:无定稿设计,功能优先)。
/// 昵称必填;形象定制未设计,仅展示占位小人。
/// 完成后写 users/{uid},AuthGate 监听 profile 流自动切入主壳。
class OnboardingPageView extends ConsumerStatefulWidget {
  const OnboardingPageView({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<OnboardingPageView> createState() => _OnboardingPageViewState();
}

class _OnboardingPageViewState extends ConsumerState<OnboardingPageView> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(completeOnboardingUsecaseProvider).execute(
            uid: widget.userId,
            nickname: _nicknameController.text,
          );
      // 成功后无需导航:AuthGate watch userProfileProvider,流出新 profile 即切主壳。
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = '保存失败,请重试。';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.bgApp,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(CoFitDimens.spacing2xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: CoFitDimens.sizeAuthFormMaxWidth,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 形象占位:avatar 编辑功能未设计(见 STATUS.md stub 登记)。
                    Center(
                      child: Container(
                        width: CoFitDimens.sizeHeroGlow,
                        height: CoFitDimens.sizeHeroGlow,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primarySubtle,
                          border: Border.all(
                            color: colors.primaryBorder,
                            width: CoFitDimens.borderWidthHairline,
                          ),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: CoFitDimens.sizeFigureHero,
                          color: colors.primaryMain,
                        ),
                      ),
                    ),
                    const SizedBox(height: CoFitDimens.spacing2xl),
                    Text(
                      '给自己起个名字',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: CoFitFontWeights.heading,
                      ),
                    ),
                    const SizedBox(height: CoFitDimens.spacingSm),
                    Text(
                      '朋友会在房间里看到这个昵称',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: CoFitDimens.spacing2xl),
                    TextFormField(
                      controller: _nicknameController,
                      enabled: !_isSubmitting,
                      maxLength: UserProfileEntity.nicknameMaxLength,
                      decoration: const InputDecoration(
                        labelText: '昵称',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) {
                          return '请输入昵称。';
                        }
                        if (text.length >
                            UserProfileEntity.nicknameMaxLength) {
                          return '昵称最多 '
                              '${UserProfileEntity.nicknameMaxLength} 个字符。';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: CoFitDimens.spacingLg),
                    SizedBox(
                      height: CoFitDimens.sizeMinTapTarget,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? SizedBox(
                                width: CoFitDimens.spacingLg,
                                height: CoFitDimens.spacingLg,
                                child: CircularProgressIndicator(
                                  strokeWidth: CoFitDimens.borderWidthFocus,
                                  color: colors.primaryOn,
                                ),
                              )
                            : const Text('进入 CoFit'),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: CoFitDimens.spacingMd),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.statusDanger),
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
}
