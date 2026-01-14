import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/settings_model.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<SettingsModel> {
  SettingsNotifier() : super(SettingsModel.load());

  Future<void> save() async {
    await state.save();
    state = SettingsModel.load();
  }
}
