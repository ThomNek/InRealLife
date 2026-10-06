import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/chat_repository.dart';

class ConversationPageArgs {
  const ConversationPageArgs({required this.conversationId, this.title});

  final String conversationId;
  final String? title;
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({
    super.key,
    this.repository,
    this.arguments,
    this.initialStream,
  });

  final ChatRepository? repository;
  final ConversationPageArgs? arguments;
  final Stream<List<Map<String, dynamic>>>? initialStream;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage>
    with WidgetsBindingObserver {
  late final ChatRepository _repository;
  final _controller = TextEditingController();
  ConversationPageArgs? _args;
  Stream<List<Map<String, dynamic>>>? _messagesStream;
  String? _lastMarkedMessageId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repository = widget.repository ?? ChatRepository();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _args ??=
        widget.arguments ??
        ModalRoute.of(context)?.settings.arguments as ConversationPageArgs?;
    final id = _args?.conversationId;
    if (id != null && _messagesStream == null) {
      _messagesStream = widget.initialStream ?? _repository.watchMessages(id);
      unawaited(_markReadInBackground(id));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final conversationId = _args?.conversationId;
    if (state == AppLifecycleState.resumed &&
        mounted &&
        conversationId != null) {
      _reconnect(conversationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    if (args == null) {
      return const Scaffold(
        body: Center(child: Text('Không xác định được cuộc trò chuyện.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          args.title?.trim().isNotEmpty == true
              ? args.title!.trim()
              : 'Trò chuyện',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Kết nối lại',
            onPressed: () => _reconnect(args.conversationId),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _messages(args.conversationId)),
          _composer(args.conversationId),
        ],
      ),
    );
  }

  Widget _messages(String conversationId) =>
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: _messagesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Không thể tải tin nhắn: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _reconnect(conversationId),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Kết nối lại'),
                    ),
                  ],
                ),
              ),
            );
          }
          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          if (rows.isNotEmpty) {
            final latestId = rows.last['id'] as String?;
            if (latestId != null && latestId != _lastMarkedMessageId) {
              _lastMarkedMessageId = latestId;
              unawaited(_markReadInBackground(conversationId));
            }
          }
          if (rows.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có tin nhắn.',
                style: TextStyle(color: AppColors.muted),
              ),
            );
          }
          return ListView.separated(
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final row = rows[rows.length - 1 - index];
              final mine = row['sender_id'] == _repository.currentUserId;
              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: mine ? AppColors.orange : AppColors.surface,
                    borderRadius: BorderRadius.circular(15),
                    border: mine ? null : Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: mine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (!mine && row['sender_display_name'] != null) ...[
                        Text(
                          row['sender_display_name'] as String,
                          style: const TextStyle(
                            color: AppColors.cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(row['content'] as String? ?? ''),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

  Widget _composer(String conversationId) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLength: ChatRepository.maxMessageLength,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(conversationId),
              decoration: const InputDecoration(
                hintText: 'Nhập tin nhắn...',
                isDense: true,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _sending ? null : () => _send(conversationId),
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    ),
  );

  Future<void> _send(String conversationId) async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      await _repository.sendMessage(
        conversationId: conversationId,
        content: text,
      );
    } catch (error) {
      if (!mounted) return;
      _controller.text = text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể gửi tin nhắn: $error')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _reconnect(String conversationId) {
    setState(() {
      _lastMarkedMessageId = null;
      _messagesStream = _repository.watchMessages(conversationId);
    });
    unawaited(_markReadInBackground(conversationId));
  }

  Future<void> _markReadInBackground(String conversationId) async {
    try {
      await _repository.markRead(conversationId);
    } catch (_) {
      // Best effort: session/quyền có thể đổi khi sự kiện Realtime vừa tới.
      // Lần mở phòng tiếp theo sẽ thử lại, không tạo lỗi Future không được bắt.
    }
  }
}
