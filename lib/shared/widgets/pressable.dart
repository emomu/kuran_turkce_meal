import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_typography.dart';

/// Dokunulduğunda hafifçe küçülen basılabilir sarmalayıcı.
///
/// Material'ın dalga (ripple) efekti yerine kullanılır: iOS'ta dalga yabancı
/// durur, bu ölçek geri bildirimi ise hem iki platformda da doğal görünür hem
/// de parmağın altındaki alanı kapatmaz.
///
/// [scale] varsayılanı büyük yüzeyler (kartlar) için ayarlıdır; küçük
/// düğmelerde daha belirgin bir değer verilebilir.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.hapticOnTap = false,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;

  /// Dokunuşta hafif titreşim. Yer imi, vurgu gibi kalıcı eylemlerde açılır;
  /// gezinme dokunuşlarında kapalı bırakılır.
  final bool hapticOnTap;

  final BorderRadius? borderRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onTap != null || widget.onLongPress != null;

  void _setPressed(bool value) {
    if (!_isEnabled || _isPressed == value) return;
    setState(() => _isPressed = value);
  }

  void _handleTap() {
    if (widget.hapticOnTap) HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap == null ? null : _handleTap,
      onLongPress: widget.onLongPress == null ? null : _handleLongPress,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? widget.scale : 1,
        duration: Motion.fast,
        curve: Motion.standard,
        child: widget.child,
      ),
    );
  }
}
