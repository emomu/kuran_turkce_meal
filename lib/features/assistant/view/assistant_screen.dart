import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../onboarding/providers/tour_provider.dart';
import '../../onboarding/widgets/coach_mark.dart';
import '../../onboarding/widgets/tour_host.dart';
import '../data/assistant_message.dart';
import '../providers/assistant_provider.dart';
import '../providers/voice_input_provider.dart';
import 'assistant_results_screen.dart';
import 'widgets/assistant_message_bubble.dart';
import 'widgets/assistant_thinking_indicator.dart';

/// Meal asistanı.
///
/// Soru sorulur, ayet gelir. Asistan bir dil modeli çalıştırmaz: soruyu
/// tanır, mevcut veri katmanından karşılar, cevabı şablonla kurar. Bu yüzden
/// çevrimdışı çalışır, anında cevap verir ve uydurma yapamaz — gösterdiği
/// her cümle ya şablondan ya ayetten gelir.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  /// Tanıtımın işaret ettiği karşılama alanı.
  final _welcomeKey = GlobalKey();

  /// Tanıtımın işaret ettiği yazma kutusu.
  final _composerKey = GlobalKey();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = preset ?? _controller.text;
    if (text.trim().isEmpty) return;

    _controller.clear();
    ref.read(assistantProvider.notifier).ask(text);
    _scrollToEnd();
  }

  /// Yeni mesajdan sonra akışın sonuna iner.
  ///
  /// Liste `reverse: true` olduğu için "son" sıfır konumudur. Bir kare
  /// beklenir: mesaj listeye eklenmeden kaydırılırsa hedef konum eski
  /// yüksekliğe göre hesaplanır ve son mesaj yarım görünür.
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _onAction(AssistantAction action, AssistantMessage message) {
    switch (action.kind) {
      case AssistantActionKind.ask:
        if (action.followUpQuery != null) _send(action.followUpQuery);
      case AssistantActionKind.openAll:
        _openResults(message);
      case AssistantActionKind.navigate:
        break; // Gezinme balonun içinde yapılır.
    }
  }

  /// Cevabın bütün sonuçlarını ayrı sayfada açar.
  ///
  /// Liste mesajın kendisinden gelir, sağlayıcıdan değil: kullanıcı sohbette
  /// ilerledikten sonra eski bir cevabın listesini de açabilmeli.
  void _openResults(AssistantMessage message) {
    if (message.allAyahs.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AssistantResultsScreen(
          title: message.resultTitle ?? 'assistant.title'.tr(),
          ayahs: message.allAyahs,
          languageCode: context.locale.languageCode,
        ),
      ),
    );
  }

  /// Asistanın tanıtım adımları.
  ///
  /// İkisi de kullanıcının kendi başına anlaması zor olan şeyler. İlki ne
  /// yaptığı: soruyu anlayıp mealde arıyor, yani kullanıcı anahtar kelime
  /// değil cümle yazabilir. İkincisi — daha önemlisi — ne yapmadığı: bu bir
  /// dil modeli değil, yorum yapmıyor ve çevrimdışı çalışıyor. Bir din
  /// uygulamasında bu ayrımın söylenmemesi, söylenmesinden çok daha kötü.
  List<TourStep> _tourSteps() {
    return [
      TourStep(
        targetKey: _welcomeKey,
        icon: Icons.auto_awesome_rounded,
        title: 'tour.assistant.whatTitle'.tr(),
        body: 'tour.assistant.whatBody'.tr(),
      ),
      TourStep(
        targetKey: _composerKey,
        icon: Icons.lock_outline_rounded,
        title: 'tour.assistant.limitTitle'.tr(),
        body: 'tour.assistant.limitBody'.tr(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantProvider);

    // Arama dizini arayüz diliyle aynı olmalı.
    ref.read(assistantProvider.notifier).languageCode =
        context.locale.languageCode;

    ref.listen(assistantProvider, (_, _) => _scrollToEnd());

    // Asistan yüzen düğmeden açılır ve geri dönülür. Yığın boşken (doğrudan
    // bağlantı ya da bildirim) sistem geri jesti uygulamayı kapatmasın diye
    // projenin geri kalanıyla aynı kalıp kullanılır.
    return PopScope(
      canPop: canPopRoute(context),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) popOrHome(context);
      },
      child: TourHost(
        tour: TourId.assistant,
        steps: _tourSteps,
        child: Scaffold(
          appBar: AppBar(
            title: Text('assistant.title'.tr()),
            actions: [
              if (!state.isEmpty)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'assistant.clear'.tr(),
                  onPressed: () => ref.read(assistantProvider.notifier).clear(),
                ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: ReadableWidth(
              child: Column(
                children: [
                  Expanded(
                    child: state.isEmpty
                        ? _Welcome(
                            key: _welcomeKey,
                            onPick: _send,
                            languageCode: context.locale.languageCode,
                          )
                        : _MessageList(
                            state: state,
                            controller: _scrollController,
                            languageCode: context.locale.languageCode,
                            onAction: _onAction,
                          ),
                  ),
                  _Composer(
                    key: _composerKey,
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !state.isThinking,
                    onSend: _send,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sohbet akışı.
class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.state,
    required this.controller,
    required this.languageCode,
    required this.onAction,
  });

  final AssistantState state;
  final ScrollController controller;
  final String languageCode;
  final void Function(AssistantAction, AssistantMessage) onAction;

  @override
  Widget build(BuildContext context) {
    final typing = state.isThinking ? 1 : 0;
    final count = state.messages.length + typing;

    // Liste ters çizilir: `reverse` sıfır noktasını alta alır, yani sohbet
    // açıldığı anda son mesaj görünür ve yeni mesaj geldiğinde kaydırma
    // kendiliğinden orada kalır. Düz listede açılış en üstten başlıyor,
    // kullanıcı geçmişi olan bir sohbete girince ilk sorusunu görüyordu.
    //
    // Karşılığında dizin tersine döner: 0 en yeni mesajdır.
    return ListView.builder(
      controller: controller,
      reverse: true,
      // Alt pay (ters listede görsel olarak son mesajın altı) yazma
      // alanından ayrılsın diye geniş tutulur: 4pt'de son cevap kutuya
      // yapışıyor ve ikisi tek blok gibi okunuyordu.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: count,
      itemBuilder: (context, index) {
        if (typing == 1 && index == 0) {
          return const AssistantThinkingIndicator();
        }
        final message = state.messages[count - 1 - index];
        return AssistantMessageBubble(
          message: message,
          languageCode: languageCode,
          onAction: onAction,
        );
      },
    );
  }
}

/// Boş ekran: asistanın ne yapabildiğini örneklerle gösterir.
///
/// Boş bir sohbet kutusu kullanıcıya ne sorabileceğini söylemez. Örnekler
/// hem ilk soruyu kolaylaştırır hem de asistanın sınırını baştan çizer:
/// listedeki her örnek gerçekten karşılanabilen bir sorudur.
class _Welcome extends StatelessWidget {
  const _Welcome({super.key, required this.onPick, required this.languageCode});

  final void Function(String) onPick;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'assistant.welcomeTitle'.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'assistant.welcomeBody'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 26),
          Text(
            'assistant.tryThese'.tr(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in assistantSuggestionsFor(languageCode))
                Pressable(
                  onTap: () => onPick(suggestion),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Text(suggestion, style: theme.textTheme.bodySmall),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 26),
          // Sınırı baştan söylemek, sonradan reddetmekten iyidir.
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'assistant.disclaimer'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
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

/// Soru yazma alanı.
class _Composer extends ConsumerWidget {
  const _Composer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSend;

  /// Mikrofona basıldı.
  ///
  /// Dinleme sürüyorsa bitirir ve tanınan metni yazı alanına koyar;
  /// sürmüyorsa başlatır. Metin doğrudan gönderilmez — tanıma yanılabilir
  /// ve kullanıcı göndermeden önce görmeli.
  Future<void> _toggleVoice(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(voiceInputProvider.notifier);
    final voice = ref.read(voiceInputProvider);

    if (voice.isListening) {
      final text = await notifier.stop();
      if (text.trim().isEmpty) return;

      controller.text = text;
      controller.selection = TextSelection.collapsed(offset: text.length);
      focusNode.requestFocus();
      return;
    }

    final languageCode = context.locale.languageCode;
    await notifier.start(languageCode: languageCode);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final voice = ref.watch(voiceInputProvider);

    // Dinlerken tanınan metin yazı alanında canlı görünür: kullanıcı
    // söylediğinin doğru anlaşıldığını anında görmeli.
    if (voice.isListening && voice.transcript.isNotEmpty) {
      controller.value = TextEditingValue(
        text: voice.transcript,
        selection: TextSelection.collapsed(offset: voice.transcript.length),
      );
    }

    return Container(
      // Alt güvenli alan gövdeyi saran `SafeArea`'dan geliyor; burada bir
      // kez daha eklenirse yazma alanının altında ekranın onda birini yiyen
      // bir boşluk kalır. Asistan sekme çubuğunun dışında durduğu için o
      // payı kendisi hesaplamaz.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'assistant.hint'.tr(),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
            ),
          ),
          // Mikrofon. Cihazda konuşma tanıma yoksa düğme hiç çizilmez —
          // basılınca hiçbir şey yapmayan bir düğme, olmayan düğmeden
          // kötüdür.
          if (voice.status != VoiceStatus.unavailable) ...[
            const SizedBox(width: 6),
            Pressable(
              onTap: enabled ? () => _toggleVoice(context, ref) : null,
              child: _MicButton(listening: voice.isListening),
            ),
          ],
          const SizedBox(width: 8),
          Pressable(
            onTap: enabled ? onSend : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: enabled
                    ? theme.colorScheme.primary
                    : theme.disabledColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mikrofon düğmesi.
///
/// Dinlerken renk değiştirir ve nabız gibi atar: kullanıcı mikrofonun açık
/// olduğunu bir bakışta görmeli. Açık kalmış bir mikrofon, kullanıcının
/// fark etmediği bir şeydir ve fark ettirilmesi gerekir.
class _MicButton extends StatefulWidget {
  const _MicButton({required this.listening});

  final bool listening;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.listening) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_MicButton old) {
    super.didUpdateWidget(old);
    if (widget.listening == old.listening) return;

    if (widget.listening) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listening = widget.listening;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        // Nabız yalnızca dinlerken; durgunken sabit bir daire.
        final glow = listening ? 0.18 + _pulse.value * 0.22 : 0.0;

        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: listening
                ? theme.colorScheme.primary.withValues(alpha: 0.16)
                : theme.colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: listening ? theme.colorScheme.primary : theme.dividerColor,
            ),
            boxShadow: listening
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: glow),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            listening ? Icons.stop_rounded : Icons.mic_none_rounded,
            size: 20,
            color: listening
                ? theme.colorScheme.primary
                : theme.textTheme.bodySmall?.color,
          ),
        );
      },
    );
  }
}
