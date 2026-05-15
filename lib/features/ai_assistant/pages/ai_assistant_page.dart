import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/repositories/ai_chat_repository.dart';
import '../../../data/models/pet_model.dart';
import '../../../shared/widgets/pet_avatar_widget.dart';
import '../../pets/cubit/active_pet_cubit.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _repo = AiChatRepository();
  final _scrollCtrl = ScrollController();
  final _inputCtrl = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _sending = false;

  static const _suggestions = [
    "How often should I bathe my dog?",
    "Is chocolate really bad for cats?",
    "How do I trim my rabbit's nails?",
    "When are puppy boosters due?",
  ];

  bool get _hasKey => AppConstants.openAiApiKey.isNotEmpty;

  Future<void> _send(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _sending) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: clean));
      _inputCtrl.clear();
      _sending = true;
    });
    _scrollDown();

    try {
      final pet = context.read<ActivePetCubit>().state.active;
      final reply = await _repo.reply(_messages, pet: pet);
      if (!mounted) return;
      setState(() => _messages.add(ChatMessage(role: 'assistant', content: reply)));
      _scrollDown();
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.add(ChatMessage(
        role: 'assistant',
        content: '⚠️ ${friendlyError(e)}',
      )));
      _scrollDown();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ActivePetCubit, ActivePetState>(
      listenWhen: (a, b) => a.active?.id != b.active?.id,
      listener: (_, __) {
        // Pet changed — clear chat so context doesn't bleed across pets.
        setState(() => _messages.clear());
      },
      child: Scaffold(
      backgroundColor: AppColors.bone,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(messageCount: _messages.length, onClear: () => setState(() => _messages.clear())),
            const _PetContextBar(),
            Expanded(
              child: _messages.isEmpty
                  ? _EmptyState(suggestions: _suggestions, onTap: _send, hasKey: _hasKey)
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      itemCount: _messages.length + (_sending ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _messages.length && _sending) return const _TypingBubble();
                        return _Bubble(message: _messages[i], index: i);
                      },
                    ),
            ),
            _Composer(
              controller: _inputCtrl,
              onSend: _send,
              disabled: _sending,
              hasKey: _hasKey,
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int messageCount;
  final VoidCallback onClear;
  const _Header({required this.messageCount, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.ink, AppColors.ink2],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: AppColors.ink.withValues(alpha: 0.18),
                    blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(LucideIcons.sparkles, color: AppColors.bone, size: 20),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.98, 0.98), end: const Offset(1.02, 1.02), duration: 1600.ms),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Vet Assistant',
                    style: GoogleFonts.bricolageGrotesque(
                        fontSize: 20, fontWeight: FontWeight.w600,
                        color: AppColors.ink, letterSpacing: -0.5)),
                Text('Ask anything about pet care',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.stone)),
              ],
            ),
          ),
          if (messageCount > 0)
            GestureDetector(
              onTap: onClear,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border)),
                child: const Icon(LucideIcons.rotateCcw, size: 16, color: AppColors.ink),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final int index;
  const _Bubble({required this.message, required this.index});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.clay50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.sparkles, size: 14, color: AppColors.clay600),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.ink : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isUser ? 18 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 18),
                ),
                border: isUser ? null : Border.all(color: AppColors.border),
              ),
              child: Text(message.content,
                  style: GoogleFonts.inter(
                      fontSize: 14, height: 1.45,
                      color: isUser ? AppColors.bone : AppColors.ink)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0);
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.clay50, borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.sparkles, size: 14, color: AppColors.clay600),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                child: Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.stone2, shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (c) => c.repeat())
                  .fade(begin: 0.3, end: 1.0, duration: 600.ms, delay: (i * 150).ms)
                  .then(delay: 600.ms)
                  .fade(begin: 1.0, end: 0.3, duration: 0.ms),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onTap;
  final bool hasKey;
  const _EmptyState({required this.suggestions, required this.onTap, required this.hasKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.clay50, AppColors.ochre50],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(LucideIcons.sparkles, size: 36, color: AppColors.clay500),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 2400.ms),
          const SizedBox(height: 24),
          Text("Hi! I'm your AI vet.",
              style: GoogleFonts.bricolageGrotesque(
                  fontSize: 30, fontWeight: FontWeight.w600,
                  color: AppColors.ink, letterSpacing: -0.9)),
          const SizedBox(height: 6),
          Text('Ask anything about your pet\'s care — vaccines, food, behaviour, grooming. '
              "I'm not a real vet, so for anything serious or urgent please call your clinic.",
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.stone, height: 1.55)),

          if (!hasKey) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.rose50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.rose100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.key, size: 16, color: AppColors.rose600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Add your OpenAI key to lib/core/constants/app_constants.dart "
                      "(openAiApiKey) to start chatting.",
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.rose600, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          Text('TRY ASKING',
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1.2, color: AppColors.stone2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: suggestions.map((s) => GestureDetector(
              onTap: () => onTap(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.sparkles, size: 12, color: AppColors.clay500),
                    const SizedBox(width: 6),
                    Text(s,
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final bool disabled;
  final bool hasKey;
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.disabled,
    required this.hasKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bone,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: controller,
                    enabled: hasKey && !disabled,
                    minLines: 1, maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: onSend,
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: hasKey ? "Ask me anything…" : "Add OpenAI key to chat",
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.stone2),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: disabled ? null : () => onSend(controller.text),
                child: AnimatedContainer(
                  duration: 180.ms,
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: hasKey ? AppColors.ink : AppColors.ink.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(LucideIcons.arrowUp, color: AppColors.bone, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sticky pet context bar — shows "Talking about <name>" with a Change button.
class _PetContextBar extends StatelessWidget {
  const _PetContextBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivePetCubit, ActivePetState>(
      builder: (context, ap) {
        if (ap.pets.isEmpty || ap.active == null) return const SizedBox.shrink();
        final p = ap.active!;
        final subtitle = [
          if (p.breed.isNotEmpty) p.breed,
          p.ageLabel,
          if (p.weightKg != null) '${(p.weightKg! * 2.205).toStringAsFixed(0)} lbs',
        ].join(' · ');

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36, height: 36,
                  child: ClipOval(child: PetAvatarWidget(pet: p, size: 36, showMoodRing: false)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Talking about ${p.name}',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle,
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.stone)),
                    ],
                  ),
                ),
                if (ap.pets.length > 1)
                  GestureDetector(
                    onTap: () => _openPetPicker(context, ap),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('Change',
                          style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPetPicker(BuildContext context, ActivePetState ap) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bone,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line, borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Text('Switch pet',
                  style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20, fontWeight: FontWeight.w600,
                      color: AppColors.ink, letterSpacing: -0.4)),
              const SizedBox(height: 4),
              Text('Chat resets when you change pets.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.stone)),
              const SizedBox(height: 12),
              ...ap.pets.map((Pet p) {
                final active = p.id == ap.activeId;
                return GestureDetector(
                  onTap: () {
                    context.read<ActivePetCubit>().setActive(p.id);
                    Navigator.pop(sheet);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: active ? AppColors.ink : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: active ? AppColors.ink : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40, height: 40,
                          child: ClipOval(child: PetAvatarWidget(pet: p, size: 40, showMoodRing: false)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: GoogleFonts.inter(
                                      fontSize: 14, fontWeight: FontWeight.w600,
                                      color: active ? AppColors.bone : AppColors.ink)),
                              Text(p.breed.isNotEmpty ? p.breed : p.species.name,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: active ? AppColors.bone.withValues(alpha: 0.7) : AppColors.stone)),
                            ],
                          ),
                        ),
                        if (active)
                          const Icon(LucideIcons.check, size: 16, color: AppColors.bone),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
