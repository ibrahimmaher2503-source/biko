import 'package:app_core/app_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/features/orders/order_models.dart';

final mapGatewayProvider = Provider<MapGateway>(
  (_) => MapGateway(Supabase.instance.client),
);

class PlaceSuggestion {
  const PlaceSuggestion({required this.id, required this.label});
  final String id;
  final String label;
}

class MapGateway {
  MapGateway(this._client);
  final SupabaseClient _client;

  Future<List<PlaceSuggestion>> search(
    String input,
    String sessionToken,
  ) async {
    final response = await _client.functions
        .invoke(
          'places',
          body: {
            'action': 'autocomplete',
            'input': input,
            'session_token': sessionToken,
          },
        )
        .timeout(transportTimeout);
    if (response.status != 200 || response.data is! Map) {
      throw const BusinessFailure('تعذر البحث عن الأماكن الآن.');
    }
    final rows = (response.data as Map)['suggestions'] as List? ?? const [];
    return rows
        .map(
          (row) => PlaceSuggestion(
            id: (row as Map)['place_id'] as String,
            label: row['label'] as String,
          ),
        )
        .toList(growable: false);
  }

  Future<LocationSelection> resolve(
    PlaceSuggestion suggestion,
    String sessionToken,
  ) async {
    final response = await _client.functions
        .invoke(
          'places',
          body: {
            'action': 'details',
            'place_id': suggestion.id,
            'session_token': sessionToken,
          },
        )
        .timeout(transportTimeout);
    if (response.status != 200 || response.data is! Map) {
      throw const BusinessFailure('تعذر تحميل المكان المحدد.');
    }
    final row = Map<String, dynamic>.from(response.data as Map);
    return LocationSelection(
      displayAddress: row['label'] as String? ?? suggestion.label,
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
    );
  }
}
