class Message {
  final int id;
  final String text;
  final String time;
  final bool outgoing;

  const Message({
    required this.id,
    required this.text,
    required this.time,
    required this.outgoing,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'time': time,
        'outgoing': outgoing,
      };

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'] as int,
        text: j['text'] as String,
        time: j['time'] as String,
        outgoing: j['outgoing'] as bool,
      );
}
