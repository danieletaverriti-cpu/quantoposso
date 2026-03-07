import 'package:flutter/material.dart';
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('FAQ / Aiuto')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _SectionTitle(title: 'Come funziona Quanto Posso', theme: theme),

          const _FaqCard(
            title: 'A cosa serve l’app?',
            body: [
              'Quanto Posso ti aiuta a capire quanto puoi spendere ogni giorno '
              'senza sforare il tuo budget mensile.',
              'L’app tiene conto di:',
              '• entrate',
              '• spese fisse',
              '• spese variabili',
              '• obiettivi di risparmio',
            ],
          ),

          const _FaqCard(
            title: 'Cosa significa “Oggi puoi spendere”?',
            body: [
              'È la quota giornaliera consigliata.',
              'Viene calcolata dividendo il budget rimasto per i giorni che mancano '
              'alla fine del mese.',
              'Se diventa bassa o negativa, l’app ti avvisa.',
            ],
          ),

          const _FaqCard(
            title: 'Il pulsante grande blu (CTA) a cosa serve?',
            body: [
              'È il pulsante principale dell’app.',
              'Ti guida automaticamente verso l’azione più utile:',
              '• se non hai entrate → ti invita ad aggiungere un’entrata',
              '• se stai sforando → ti suggerisce di aggiungere un’entrata',
              '• altrimenti → ti permette di aggiungere una spesa',
            ],
          ),

          const SizedBox(height: 10),
          _SectionTitle(title: 'Azioni rapide', theme: theme),

          const _FaqCard(
            title: 'Spesa / Entrata / Fissa',
            body: [
              'I pulsanti “Azioni rapide” servono per muoverti velocemente:',
              '• Spesa → aggiungi subito una spesa',
              '• Entrata → aggiungi uno stipendio, bonus o rimborso',
              '• Fissa → gestisci le spese fisse mensili',
            ],
          ),

          const SizedBox(height: 10),
          _SectionTitle(title: 'Notifiche', theme: theme),

          const _FaqCard(
            title: 'A cosa servono le notifiche?',
            body: [
              'Le notifiche servono per ricordarti:',
              '• quanto puoi spendere oggi',
              '• se stai andando oltre il budget',
              '• di tenere sotto controllo le spese',
            ],
          ),

          const _FaqCard(
            title: 'Perché a volte le notifiche arrivano in ritardo?',
            body: [
              'Su alcuni telefoni Android le notifiche possono essere ritardate '
              'per il risparmio energetico.',
              'Questo succede soprattutto su Samsung e telefoni simili.',
            ],
          ),

          const _FaqCard(
            title: 'Cosa posso fare se le notifiche non arrivano?',
            body: [
              'Controlla queste impostazioni sul telefono:',
              '• Impostazioni → App → Quanto Posso',
              '• Attiva le notifiche',
              '• Imposta batteria su “Nessuna restrizione” o simile',
              '• Evita il risparmio energetico quando vuoi notifiche puntuali',
            ],
          ),

          const _FaqCard(
            title: 'Samsung: attenzione speciale',
            body: [
              'Samsung tende a “mettere a dormire” le app.',
              'Se usi Samsung:',
              '• rimuovi Quanto Posso dalle app in sospensione',
              '• disattiva le limitazioni della batteria per l’app',
            ],
          ),

          const SizedBox(height: 10),
          _SectionTitle(title: 'Budget e dati', theme: theme),

          const _FaqCard(
            title: 'I miei dati sono al sicuro?',
            body: [
              'Sì. I dati restano solo sul tuo dispositivo.',
              'L’app non condivide le tue spese con nessuno.',
            ],
          ),

          const _FaqCard(
            title: 'Se sbaglio una spesa o un’entrata?',
            body: [
              'Puoi sempre modificarla o eliminarla.',
              'Il budget si aggiorna automaticamente.',
            ],
          ),

          const SizedBox(height: 20),
          Center(
            child: Text(
              'Consiglio: inserisci le spese ogni giorno per avere un budget più preciso.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionTitle({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 10),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final String title;
  final List<String> body;

  const _FaqCard({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            for (final line in body) ...[
              Text(line),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}