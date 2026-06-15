import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    state = state.copyWith(isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 350));

    // class 1 has a seeded config; other classes start from default object.
    final config = _classId == 1
        ? const WhatsappConfigModel(
            id: 1,
            classId: 1,
            adminPhone: '6281111111111',
            treasurerPhone: '6281222222222',
            notificationTemplate: kDefaultWhatsappTemplate,
          )
        : WhatsappConfigModel(classId: _classId);

    state = state.copyWith(config: config, isLoading: false);
    _loaded = true;
  }

  Future<void> saveConfig({
    String? adminPhone,
    String? treasurerPhone,
    required String notificationTemplate,
  }) async {
    state = state.copyWith(isSaving: true);
    await Future<void>.delayed(const Duration(milliseconds: 450));

    final current = state.config ?? WhatsappConfigModel(classId: _classId);
    final updated = WhatsappConfigModel(
      id: current.id ?? 1,
      classId: _classId,
      adminPhone: (adminPhone?.trim().isEmpty ?? true) ? null : adminPhone!.trim(),
      treasurerPhone:
          (treasurerPhone?.trim().isEmpty ?? true) ? null : treasurerPhone!.trim(),
      notificationTemplate: notificationTemplate.trim().isEmpty
          ? kDefaultWhatsappTemplate
          : notificationTemplate.trim(),
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(config: updated, isSaving: false);
  }
}

final whatsappConfigProvider = StateNotifierProvider.family<
    WhatsappConfigNotifier, WhatsappConfigState, int>(
  (ref, classId) => WhatsappConfigNotifier(classId),
);
