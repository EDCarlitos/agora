import 'package:flutter/material.dart';
import '../normal_user/views/chat_room_view.dart';

class MessageBubble extends StatelessWidget {
  final Message msg;
  final Color bgOutgoing;
  final Color bgIncoming;
  final Color textOutColor;
  final Color textInColor;

  const MessageBubble({
    super.key,
    required this.msg,
    required this.bgOutgoing,
    required this.bgIncoming,
    required this.textOutColor,
    required this.textInColor,
  });

  @override
  Widget build(BuildContext context) {
    if (msg.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            msg.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      );
    }

    final align = msg.isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = msg.isOutgoing ? bgOutgoing : bgIncoming;
    final textColor = msg.isOutgoing ? textOutColor : textInColor;

    final corners = msg.isOutgoing
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(2),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(2),
          );

    final displayTime = '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: corners,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        msg.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 150,
                            width: 200,
                            color: Colors.grey.withOpacity(0.2),
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (msg.text.isNotEmpty)
                    Text(
                      msg.text,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.8,
                        height: 1.35,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Spacer(),
                      Text(
                        displayTime,
                        style: TextStyle(
                          color: msg.isOutgoing ? Colors.white.withOpacity(0.6) : Colors.grey.shade500,
                          fontSize: 9.5,
                        ),
                      ),
                      if (msg.isOutgoing) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all_rounded,
                          size: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}