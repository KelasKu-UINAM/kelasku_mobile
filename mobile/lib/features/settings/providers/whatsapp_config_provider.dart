import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../models/whatsapp_config_model.dart';

@immutable
class WhatsappConfigState {
  final WhatsappConfigModel? config;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const WhatsappConfigState({
    this.config,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  WhatsappConfigState copyWith({
    WhatsappConfigModel? config,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return WhatsappConfigState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class WhatsappConfigNotifier extends StateNotifier<WhatsappConfigState> {
  WhatsappConfigNotifier(this._classId)
      : super(const WhatsappConfigState());

  final int _classId;
  bool _loaded = false;

  Future<void> fetchConfig({bool forceRefresh = false}) async {
    if (_loaded && !forceRefresh) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get(
        '${ApiConstants.classes}/$_classId/whatsapp-config',
      );
      final data = extractData(response) as Map<String, dynamic>;
      final config = WhatsappConfigModel.fromJson(data);
      state = state.copyWith(config: config, isLoading: false);
      _loaded = true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractErrorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan. Coba lagi.',
      );
    }
  }

  Future<void> saveConfig({
    String? adminPhone,
    String? treasurerPhone,
    required String notificationTemplate,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final response = await ApiClient.instance.put(
        '${ApiConstants.classes}/$_classId/whatsapp-config',
        data: {
          'admin_phone':
              (adminPhone?.trim().isEmpty ?? true) ? null : adminPhone!.trim(),
          'treasurer_phone': (treasurerPhone?.trim().isEmpty ?? true)
              ? null
              : treasurerPhone!.trim(),
          'notification_template': notificationTemplate.trim().isEmpty
              ? kDefaultWhatsappTemplate
              : notificationTemplate.trim(),
        },
      );
      final data = extractData(response) as Map<String, dynamic>;
      final updated = WhatsappConfigModel.fromJson(data);
      state = state.copyWith(config: updated, isSaving: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: extractErrorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Terjadi kesalahan. Coba lagi.',
      );
    }
  }
}

final whatsappConfigProvider = StateNotifierProvider.family<
    WhatsappConfigNotifier, WhatsappConfigState, int>(
  (ref, classId) => WhatsappConfigNotifier(classId),
);
