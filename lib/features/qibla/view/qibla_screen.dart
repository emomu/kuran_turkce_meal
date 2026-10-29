import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../data/qibla_math.dart';
import '../providers/qibla_provider.dart';

/// Kıble pusulası.
///
/// İki girdiyi birleştirir: konumdan hesaplanan kıble açısı ve cihazın
/// manyetometresinden gelen yön. İkisi de gerçek kuzeye göre olduğu için
/// doğrudan karşılaştırılabilir.
///
/// Konum izni ekran açılır açılmaz istenmez. Kullanıcı düğmeye bastığında
/// sorulur — uygulamanın geri kalanı hiç izin istemiyor ve kıble bir araç,
/// kullanıcı onu kullanmaya karar verdiğinde sorulması doğru olur.
class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(qiblaLocationProvider);

    return Scaffold(
      appBar: AppBar(title: Text('qibla.title'.tr())),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: centeredContentPadding(
              context,
              top: Insets.lg,
              bottom: Insets.lg,
            ),
            child: switch (location) {
              QiblaLocationIdle() => const _PermissionPrompt(),
              QiblaLocationLoading() => const _Loading(),
              QiblaLocationError(:final reason) => _LocationError(reason: reason),
              QiblaLocationReady(:final bearing, :final distanceKm) =>
                _Compass(bearing: bearing, distanceKm: distanceKm),
            },
          ),
        ),
      ),
    );
  }
}

/// İzin istenmeden önceki açıklama.
///
/// Sistem izin kutusu çıkmadan önce neden sorulduğu anlatılır: kullanıcı
/// kutuyu gördüğünde ne istendiğini zaten bilir ve reddetme olasılığı
/// düşer. Gizlilik vaadi de burada tekrarlanır — uygulama hiçbir veri
/// toplamadığını söylüyor, bu ekran o vaadin istisnası gibi görünmemeli.
class _PermissionPrompt extends ConsumerWidget {
  const _PermissionPrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.explore_outlined,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: Insets.lg),
        Text(
          'qibla.permissionTitle'.tr(),
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Insets.sm),
        Text(
          'qibla.permissionBody'.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Insets.lg),
        FilledButton.icon(
          onPressed: () => ref.read(qiblaLocationProvider.notifier).locate(),
          icon: const Icon(Icons.my_location_rounded),
          label: Text('qibla.locate'.tr()),
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        const SizedBox(height: Insets.md),
        Text('qibla.locating'.tr()),
      ],
    );
  }
}

/// Konum alınamadığında ne yapılacağını söyler.
///
/// Her hata farklı bir çıkış yolu gösterir: kapalı servis ayarlardan
/// açılır, reddedilen izin yeniden istenebilir, kalıcı ret yalnızca
/// sistem ayarlarından geri alınır. Tek bir "hata oldu" mesajı kullanıcıyı
/// çıkmazda bırakırdı.
class _LocationError extends ConsumerWidget {
  const _LocationError({required this.reason});

  final QiblaLocationFailure reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(qiblaLocationProvider.notifier);

    final (title, body, actionLabel, action) = switch (reason) {
      QiblaLocationFailure.serviceDisabled => (
          'qibla.serviceDisabled'.tr(),
          'qibla.serviceDisabledBody'.tr(),
          'qibla.openLocationSettings'.tr(),
          notifier.openLocationSettings,
        ),
      QiblaLocationFailure.denied => (
          'qibla.denied'.tr(),
          'qibla.deniedBody'.tr(),
          'qibla.retry'.tr(),
          notifier.locate,
        ),
      QiblaLocationFailure.deniedForever => (
          'qibla.deniedForever'.tr(),
          'qibla.deniedForeverBody'.tr(),
          'qibla.openAppSettings'.tr(),
          notifier.openSettings,
        ),
      QiblaLocationFailure.unavailable => (
          'qibla.unavailable'.tr(),
          'qibla.unavailableBody'.tr(),
          'qibla.retry'.tr(),
          notifier.locate,
        ),
    };

    return EmptyState(
      icon: Icons.location_off_outlined,
      title: title,
      message: body,
      action: FilledButton(
        onPressed: () => action(),
        child: Text(actionLabel),
      ),
    );
  }
}

/// Pusula kadranı ve hizalanma bilgisi.
class _Compass extends ConsumerStatefulWidget {
  const _Compass({required this.bearing, required this.distanceKm});

  final double bearing;
  final double distanceKm;

  @override
  ConsumerState<_Compass> createState() => _CompassState();
}

class _CompassState extends ConsumerState<_Compass> {
  /// En son titreşim verilen hizalanma durumu.
  ///
  /// Titreşim yalnızca durum değiştiğinde verilir; her karede verilseydi
  /// kullanıcı kıbleye dönükken telefon sürekli titrerdi.
  bool _wasAligned = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compass = ref.watch(compassProvider);
    final heading = compass.valueOrNull?.heading;

    // Pusulası olmayan cihaz: yön gösterilemez ama açı ve uzaklık yine de
    // işe yarar — kullanıcı başka bir pusulayla o açıya dönebilir.
    if (compass.hasValue && heading == null) {
      return _NoCompass(bearing: widget.bearing, distanceKm: widget.distanceKm);
    }

    final aligned = heading != null &&
        QiblaMath.isAligned(heading: heading, qiblaBearing: widget.bearing);

    if (aligned != _wasAligned) {
      _wasAligned = aligned;
      if (aligned) HapticFeedback.mediumImpact();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (needsCalibration(compass.valueOrNull)) ...[
          _CalibrationNotice(),
          const SizedBox(height: Insets.lg),
        ],

        _Dial(
          heading: heading ?? 0,
          bearing: widget.bearing,
          aligned: aligned,
        ),

        const SizedBox(height: Insets.lg),

        // Hizalanma durumu: iğneye bakmadan da anlaşılsın diye yazıyla da
        // söylenir. Yön bilgisi ("sağa dön") sapmanın işaretinden gelir.
        if (heading != null)
          _AlignmentLabel(heading: heading, bearing: widget.bearing),

        const SizedBox(height: Insets.sm),

        Text(
          'qibla.distance'.tr(
            args: [widget.distanceKm.round().toString()],
          ),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),

        const SizedBox(height: Insets.lg),

        Text(
          'qibla.accuracyNote'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Dönen pusula kadranı.
///
/// Kadran cihazla birlikte döner (kuzey hep gerçek kuzeyi gösterir), iğne
/// ise kıbleyi işaret eder. Böylece kullanıcı hem nereye baktığını hem
/// kıblenin nerede olduğunu aynı anda görür.
class _Dial extends StatelessWidget {
  const _Dial({
    required this.heading,
    required this.bearing,
    required this.aligned,
  });

  final double heading;
  final double bearing;
  final bool aligned;

  static const _size = 260.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final needle = QiblaMath.needleAngle(
      heading: heading,
      qiblaBearing: bearing,
    );

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Kadran: cihaz döndükçe ters yönde döner, yön harfleri gerçek
          // yönlerinde kalır.
          AnimatedRotation(
            turns: -heading / 360,
            duration: const Duration(milliseconds: 120),
            child: CustomPaint(
              size: const Size.square(_size),
              painter: _DialPainter(
                ringColor: theme.colorScheme.outlineVariant,
                tickColor: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                labelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                northColor: theme.colorScheme.error,
                textDirection: Directionality.of(context),
              ),
            ),
          ),

          // Kıble iğnesi.
          AnimatedRotation(
            turns: needle / 360,
            duration: const Duration(milliseconds: 120),
            child: CustomPaint(
              size: const Size.square(_size),
              painter: _NeedlePainter(
                color: aligned
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                glow: aligned,
              ),
            ),
          ),

          // Merkezdeki Kâbe simgesi; hizalanınca vurgulanır.
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: aligned
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
            ),
            child: Icon(
              Icons.mosque_outlined,
              size: 28,
              color: aligned
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kadranın halkası, derece çizgileri ve yön harfleri.
class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.ringColor,
    required this.tickColor,
    required this.labelColor,
    required this.northColor,
    required this.textDirection,
  });

  final Color ringColor;
  final Color tickColor;
  final Color labelColor;
  final Color northColor;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = ringColor,
    );

    // Her 15 derecede bir çizgi; ana yönlerde uzun.
    for (var degree = 0; degree < 360; degree += 15) {
      final isMajor = degree % 90 == 0;
      final length = isMajor ? 14.0 : 7.0;
      final angle = _toRadians(degree - 90);
      final outer = center +
          Offset(math.cos(angle), math.sin(angle)) * (radius - 4);
      final inner = center +
          Offset(math.cos(angle), math.sin(angle)) * (radius - 4 - length);

      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..strokeWidth = isMajor ? 2 : 1
          ..color = degree == 0 ? northColor : tickColor,
      );
    }

    // Yön harfleri. Kuzey ayrı renkte: kullanıcının kadranı okurken
    // tutunacağı tek sabit nokta odur.
    const labels = {0: 'K', 90: 'D', 180: 'G', 270: 'B'};
    for (final entry in labels.entries) {
      final angle = _toRadians(entry.key - 90);
      final position = center +
          Offset(math.cos(angle), math.sin(angle)) * (radius - 34);

      final painter = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: entry.key == 0 ? northColor : labelColor,
          ),
        ),
        textDirection: textDirection,
      )..layout();

      painter.paint(
        canvas,
        position - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  static double _toRadians(num degrees) => degrees * math.pi / 180;

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.ringColor != ringColor ||
      old.tickColor != tickColor ||
      old.labelColor != labelColor ||
      old.northColor != northColor;
}

/// Kıbleyi gösteren iğne.
class _NeedlePainter extends CustomPainter {
  _NeedlePainter({required this.color, required this.glow});

  final Color color;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // Üçgen uç: merkezden yukarı doğru, kadranın iç kenarına kadar.
    final tip = center + Offset(0, -(radius - 24));
    final left = center + const Offset(-11, -34);
    final right = center + const Offset(11, -34);

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    if (glow) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_NeedlePainter old) =>
      old.color != color || old.glow != glow;
}

/// "Kıbleye dönüksün" / "Sağa dön" bilgisi.
class _AlignmentLabel extends StatelessWidget {
  const _AlignmentLabel({required this.heading, required this.bearing});

  final double heading;
  final double bearing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aligned =
        QiblaMath.isAligned(heading: heading, qiblaBearing: bearing);

    if (aligned) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: Insets.xs),
          Text(
            'qibla.aligned'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    // Hangi yöne dönüleceği: kıble açısı cihazın yönünden büyükse sağa.
    // 180 dereceyi aşan fark kısa yoldan ters yöne işaret eder.
    final diff = (bearing - heading + 360) % 360;
    final turnRight = diff < 180;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          turnRight ? Icons.turn_right_rounded : Icons.turn_left_rounded,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        const SizedBox(width: Insets.xs),
        Text(
          (turnRight ? 'qibla.turnRight' : 'qibla.turnLeft').tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// Manyetometre güvenilmezken gösterilen uyarı.
class _CalibrationNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Insets.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.screen_rotation_alt_rounded,
            size: 20,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: Insets.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'qibla.calibrate'.tr(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                Text(
                  'qibla.calibrateBody'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer
                        .withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pusulası olmayan cihazda gösterilen bilgi.
///
/// Yön çizilemez ama hesap yine de işe yarar: kullanıcı açıyı okuyup
/// başka bir pusulayla o yöne dönebilir.
class _NoCompass extends StatelessWidget {
  const _NoCompass({required this.bearing, required this.distanceKm});

  final double bearing;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.explore_off_outlined,
          size: 56,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(height: Insets.md),
        Text(
          'qibla.noCompass'.tr(),
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Insets.xs),
        Text(
          'qibla.noCompassBody'.tr(args: [bearing.round().toString()]),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Insets.md),
        Text(
          'qibla.distance'.tr(args: [distanceKm.round().toString()]),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
