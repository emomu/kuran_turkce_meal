import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/pressable.dart';
import '../../data/assistant_message.dart';
import '../../domain/answer_composer.dart';
import 'assistant_ayah_card.dart';

/// Sohbetteki tek bir mesaj.
///
/// Kullanıcı mesajı sağda ve dolgulu, asistan mesajı solda ve düz. Asistan
/// tarafında balon çerçevesi yok: cevap uzundur ve ayet kartları taşır;
/// çerçeve içine alınınca ekran daralır ve okuma zorlaşır.
class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({
    super.key,
    required this.message,
    required this.languageCode,
    required this.onAction,
  });

  final AssistantMessage message;
  final String languageCode;
  /// Eylem tetiklendiğinde çağrılır; mesajın kendisi de verilir çünkü
  /// "Tümünü gör" o mesajın sonuç listesini açar.
  final void Function(AssistantAction, AssistantMessage) onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(top: 16, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            message.text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),

          // Çoklu konu cevabı: her bölüm kendi başlığıyla. Başlıklar
          // olmadan iki konunun ayetleri tek listeye karışır ve
          // karşılaştırma kaybolur.
          for (final section in message.sections)
            _Section(
              section: section,
              languageCode: languageCode,
              highlightTerms: message.highlightTerms,
            ),

          // Cevabın dayandığı ayetler. Son öğenin altına ayırıcı çizilmez:
          // orada liste bitiyor, çizgi havada kalırdı.
          for (var i = 0; i < message.ayahs.length; i++)
            AssistantAyahCard(
              answer: message.ayahs[i],
              languageCode: languageCode,
              showDivider: i < message.ayahs.length - 1,
              highlightTerms: message.highlightTerms,
            ),

          if (message.actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in message.actions)
                  _ActionChip(
                    action: action,
                    onTap: () => _handle(context, action),
                  ),
              ],
            ),
          ],
          // Uyarı notu en altta: kullanıcı önce ayetleri okur, sonra
          // eylemi görür, en son sınırı. Not ile düğme yer değiştirdi çünkü
          // ikisi yan yanayken göz önce nota takılıyor ve "tümünü gör"
          // bir dipnot gibi duruyordu.
          if (message.note != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    message.note!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],

        ],
      ),
    );
  }

  void _handle(BuildContext context, AssistantAction action) {
    if (action.kind == AssistantActionKind.navigate && action.route != null) {
      context.push(action.route!);
      return;
    }
    onAction(action, message);
  }
}

/// Çoklu konu cevabında tek bir bölüm: başlık ve ayetleri.
class _Section extends StatelessWidget {
  const _Section({
    required this.section,
    required this.languageCode,
    required this.highlightTerms,
  });

  final AnswerSection section;
  final String languageCode;
  final List<String> highlightTerms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 2),
          child: Row(
            children: [
              Text(
                section.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${section.totalFound})',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < section.ayahs.length; i++)
          AssistantAyahCard(
            answer: section.ayahs[i],
            languageCode: languageCode,
            showDivider: i < section.ayahs.length - 1,
            highlightTerms: highlightTerms,
          ),
      ],
    );
  }
}

/// Cevabın altındaki eylem düğmesi.
class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.action, required this.onTap});

  final AssistantAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNavigate = action.kind == AssistantActionKind.navigate;

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: isNavigate
              ? theme.colorScheme.primary.withValues(alpha: 0.10)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isNavigate
                ? theme.colorScheme.primary.withValues(alpha: 0.25)
                : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              switch (action.kind) {
                AssistantActionKind.navigate => Icons.open_in_new_rounded,
                AssistantActionKind.openAll => Icons.list_rounded,
                AssistantActionKind.ask => Icons.help_outline_rounded,
              },
              size: 14,
              color: isNavigate
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 6),
            Text(
              action.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isNavigate ? theme.colorScheme.primary : null,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
