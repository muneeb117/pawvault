import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/document_model.dart';

/// Calls OpenAI's vision-capable model with an image (typically a photo of a
/// vet receipt, vaccine card, lab report, prescription, or insurance card)
/// and asks for a strict JSON extraction of relevant health info.
class AiExtractionRepository {
  static const _systemPrompt = '''
You are a veterinary records extractor. Given an image of a pet document
(vet receipt, vaccine card, lab report, prescription, insurance card),
extract any health information present and return a single JSON object.

Return STRICT JSON matching this schema exactly. Use null for unknown
fields. Dates MUST be in ISO 8601 format (YYYY-MM-DD). Do not include
any prose outside the JSON.

{
  "pet_name": string|null,
  "clinic": string|null,
  "vet": string|null,
  "visit_date": "YYYY-MM-DD"|null,
  "next_visit": "YYYY-MM-DD"|null,
  "diagnosis": string|null,
  "cost": number|null,
  "vaccines": [
    { "name": string, "given_on": "YYYY-MM-DD"|null, "next_due": "YYYY-MM-DD"|null }
  ],
  "medications": [
    { "name": string, "dosage": string|null, "frequency": string|null }
  ]
}

If the image is not a pet/vet document, return an object with all
fields null and empty arrays.
''';

  /// Sends [bytes] (PNG/JPEG/HEIC) to the OpenAI Vision endpoint and parses
  /// the JSON reply into an [ExtractedHealth] object.
  Future<ExtractedHealth> extract({
    required Uint8List bytes,
    required String mimeType,
    DocType? hintType,
  }) async {
    final key = AppConstants.openAiApiKey;
    if (key.isEmpty) {
      throw 'AI extraction needs an OpenAI key. Add it in app_constants.dart.';
    }

    final b64 = base64Encode(bytes);
    final hint = hintType == null
        ? ''
        : 'The user labelled this document as: ${hintType.label}.';

    final res = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        // gpt-4o-mini supports vision and is the cheapest vision model.
        'model': 'gpt-4o-mini',
        'temperature': 0,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {
            'role': 'user',
            'content': [
              if (hint.isNotEmpty) {'type': 'text', 'text': hint},
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$mimeType;base64,$b64',
                  'detail': 'high',
                },
              },
            ],
          },
        ],
      }),
    );

    if (res.statusCode >= 400) {
      final body = jsonDecode(res.body);
      throw body['error']?['message'] ?? 'OpenAI error (${res.statusCode})';
    }

    final data = jsonDecode(res.body);
    final raw = data['choices']?[0]?['message']?['content'] as String?;
    if (raw == null || raw.isEmpty) {
      return const ExtractedHealth();
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return ExtractedHealth.fromJson(json);
    } catch (_) {
      return const ExtractedHealth();
    }
  }
}
