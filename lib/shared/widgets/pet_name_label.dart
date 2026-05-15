import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/pet_repository.dart';

/// In-memory cache of pet names so widgets that need them don't refetch.
/// Populated lazily by [PetNameLabel].
class PetNameCache {
  static final Map<String, String> _cache = {};
  static void put(String petId, String name) => _cache[petId] = name;
  static String? get(String petId) => _cache[petId];
  static void clear() => _cache.clear();
}

/// Shows a pet's name (upper-cased by default) for the given pet id.
/// Fetches once and caches across the session — no refetch on rebuild.
class PetNameLabel extends StatefulWidget {
  final String petId;
  final TextStyle? style;
  final bool upperCase;
  final String fallback;

  const PetNameLabel({
    super.key,
    required this.petId,
    this.style,
    this.upperCase = true,
    this.fallback = 'Your buddy',
  });

  @override
  State<PetNameLabel> createState() => _PetNameLabelState();
}

class _PetNameLabelState extends State<PetNameLabel> {
  String? _name;

  @override
  void initState() {
    super.initState();
    final cached = PetNameCache.get(widget.petId);
    if (cached != null) {
      _name = cached;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final pet = await PetRepository(Supabase.instance.client).getPetById(widget.petId);
      if (pet != null) {
        PetNameCache.put(widget.petId, pet.name);
        if (mounted) setState(() => _name = pet.name);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final raw = _name ?? widget.fallback;
    final out = widget.upperCase ? raw.toUpperCase() : raw;
    return Text(out, style: widget.style);
  }
}
