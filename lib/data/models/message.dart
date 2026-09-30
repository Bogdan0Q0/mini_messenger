class Message {
  final int id;
  final String text;
  final String time;
  final bool outgoing;
  final String? imagePath;

  const Message({
    required this.id,
    required this.text,
    required this.time,
    required this.outgoing,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'time': time,
        'outgoing': outgoing,
        'imagePath': imagePath,
      };

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'] as int,
        text: (j['text'] ?? '') as String,
        time: j['time'] as String,
        outgoing: j['outgoing'] as bool,
        imagePath: j['imagePath'] as String?,
      );
}
