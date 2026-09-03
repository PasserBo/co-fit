import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../avatar/presentation/idle_avatar_figure.dart';
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
                    Text(
                      '你的小人已就位',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: CoFitFontWeights.heading,
                      ),
                    ),
                    const SizedBox(height: CoFitDimens.spacingXs),
                    Text(
                      '起个名字,朋友在房间里认出你',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: CoFitDimens.spacing2xl),
                    // 发光圆环 + bob 小人;头像区可点但仅提示「即将上线」(#19b)。
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(content: Text('形象定制:即将上线')),
                            );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: CoFitDimens.sizeAuthGlow,
                              height: CoFitDimens.sizeAuthGlow,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.primaryMain.withValues(
                                  alpha: CoFitOpacities.faint,
                                ),
                                border: Border.all(
                                  color: colors.primaryBorder,
                                  width: CoFitDimens.borderWidthHairline,
                                ),
                              ),
                            ),
                            const IdleAvatarFigure(
                              figureHeight: CoFitDimens.sizeFigureHero,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: CoFitDimens.spacingSm,
                                  vertical: CoFitDimens.spacingXs / 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.bgOverlay,
                                  borderRadius: BorderRadius.circular(
                                    CoFitDimens.radiusSm,
                                  ),
                                  border: Border.all(
                                    color: colors.borderStrong,
                                    width: CoFitDimens.borderWidthHairline,
                                  ),
                                ),
                                child: Text(
                                  '形象定制 即将上线',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colors.textTertiary,
                                    fontWeight: CoFitFontWeights.label,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: CoFitDimens.spacing2xl),
                    TextFormField(
                      controller: _nicknameController,
                      enabled: !_isSubmitting,
                      onChanged: (_) => setState(() {}),
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
                        // 空名禁用(#19b:lime@30% 底 + 半透字)
                        onPressed: _isSubmitting ||
                                _nicknameController.text.trim().isEmpty
                            ? null
                            : _submit,
                        style: FilledButton.styleFrom(
                          disabledBackgroundColor: colors.primaryMain
                              .withValues(alpha: CoFitOpacities.disabledFill),
                          disabledForegroundColor: colors.primaryOn
                              .withValues(alpha: CoFitOpacities.disabledOn),
                        ),
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
