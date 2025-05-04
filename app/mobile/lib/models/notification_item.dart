class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime date;
  final bool read;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.read = false,
  });

  factory NotificationItem.fake(int i) => NotificationItem(
    id: 'not_$i',
    title: i.isEven ? 'Nowe wyzwanie!' : 'Podziękowanie od schroniska',
    body: i.isEven
        ? 'Wspieraj zwierzaki przez 5 kolejnych dni i zdobądź 100 XP.'
        : 'Dziękujemy za wsparcie – Twoja darowizna już pomaga.',
    date: DateTime.now().subtract(Duration(hours: i * 6)),
    read: i % 3 == 0,
  );
}