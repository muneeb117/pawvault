import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <_Message>[
    _Message(
      text: "Hi! I'm Biscuit's care assistant. Tell me what's going on and I'll suggest next steps. 🐾",
      isUser: false,
      isWelcome: true,
    ),
  ];
  bool _isTyping = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _isTyping = true;
    });
    _ctrl.clear();
    _scrollDown();

    // Simulate AI response
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(_Message(
        text: "That combo — head shaking, scratching, and an odor — usually points to an ear infection. Common in Goldens because of their floppy ears trapping moisture.",
        isUser: false,
        triageCard: _TriageCardData(
          title: 'RECOMMENDED WITHIN 48 HR',
          action: 'Book a vet visit',
          severity: 'Moderate',
        ),
      ));
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bone,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paw Assistant'),
            const Text('Talking about Biscuit',
                style: TextStyle(fontSize: 12, color: AppColors.stone)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.clay50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('AI · BETA',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.clay500)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Pet context chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.pets, size: 14, color: AppColors.clay500),
                const SizedBox(width: 6),
                const Text('Biscuit · Golden Retriever · 3 yr · 62 lbs',
                    style: TextStyle(fontSize: 12, color: AppColors.stone)),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, minimumSize: const Size(40, 24)),
                  child: const Text('Change',
                      style: TextStyle(fontSize: 12, color: AppColors.clay500)),
                ),
              ],
            ),
          ),

          // Chat
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (_isTyping && i == _messages.length) return const _TypingBubble();
                return _ChatBubble(msg: _messages[i]);
              },
            ),
          ),

          // Suggested prompts
          if (_messages.length == 1)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  'Any symptoms to watch?',
                  'Review meds',
                  'Upcoming vaccines',
                ].map((p) => GestureDetector(
                  onTap: () => _send(p),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(p, style: const TextStyle(fontSize: 13)),
                  ),
                )).toList(),
              ),
            ),

          // Disclaimer
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Not a substitute for a vet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.stone)),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: 'Ask anything about Biscuit…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.clay500),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.mic_none_rounded, color: AppColors.stone),
                          onPressed: () {},
                        ),
                      ),
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _send(_ctrl.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.clay500,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward_rounded,
                          color: AppColors.bone, size: 20),
                    ),
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

class _Message {
  final String text;
  final bool isUser;
  final bool isWelcome;
  final _TriageCardData? triageCard;

  const _Message({
    required this.text,
    required this.isUser,
    this.isWelcome = false,
    this.triageCard,
  });
}

class _TriageCardData {
  final String title;
  final String action;
  final String severity;
  const _TriageCardData({required this.title, required this.action, required this.severity});
}

class _ChatBubble extends StatelessWidget {
  final _Message msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(
                color: AppColors.clay50, shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pets, size: 14, color: AppColors.clay500),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: msg.isUser ? AppColors.clay500 : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                      bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                    ),
                    border: msg.isUser ? null : Border.all(color: AppColors.border),
                  ),
                  child: Text(msg.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: msg.isUser ? AppColors.bone : AppColors.ink,
                        height: 1.4,
                      )),
                ),
                if (msg.triageCard != null) ...[
                  const SizedBox(height: 8),
                  _TriageCard(data: msg.triageCard!),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

class _TriageCard extends StatelessWidget {
  final _TriageCardData data;
  const _TriageCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.clay50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.clay500.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.title,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.clay500)),
          const SizedBox(height: 4),
          Text(data.action,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              _ActionChip(label: 'Book a vet', onTap: () {}),
              const SizedBox(width: 8),
              _ActionChip(label: 'Home care tips', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.clay500,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.bone)),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
                color: AppColors.clay50, shape: BoxShape.circle),
            child: const Icon(Icons.pets, size: 14, color: AppColors.clay500),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) =>
                Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                      color: AppColors.stone, shape: BoxShape.circle),
                ).animate(delay: (i * 150).ms, onPlay: (c) => c.repeat())
                  .fadeIn(duration: 300.ms)
                  .then(delay: 300.ms)
                  .fadeOut(duration: 300.ms),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
