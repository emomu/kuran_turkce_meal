import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../data/assistant_message.dart';
import '../providers/assistant_provider.dart';
import 'assistant_results_screen.dart';
import 'widgets/assistant_message_bubble.dart';

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
        if (typing == 1 && index == 0) return const _TypingIndicator();
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
  const _Welcome({required this.onPick, required this.languageCode});

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
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

/// Asistan cevabı hazırlarken görünen üç nokta.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).textTheme.bodySmall?.color;

    return Padding(
      padding: const EdgeInsets.only(top: 18, left: 2),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              // Her nokta bir öncekinden gecikmeli parlar; dalga etkisi
              // sabit bir göstergeye göre bekleyişi kısaltır.
              Opacity(
                opacity:
                    0.3 +
                    0.7 *
                        ((_controller.value * 3 - i).clamp(0.0, 1.0) *
                            (1 -
                                (_controller.value * 3 - i - 1).clamp(
                                  0.0,
                                  1.0,
                                ))),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (i < 2) const SizedBox(width: 5),
            ],
          ],
        ),
      ),
    );
  }
}
