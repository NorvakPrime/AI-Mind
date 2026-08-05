import 'package:flutter/material.dart';

import '../models/ai_model.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../widgets/settings_panel.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.settings,
    required this.modelId,
    required this.models,
    required this.apiToken,
    required this.temperature,
    required this.topP,
    required this.maxTokens,
    required this.streaming,
    required this.onModelChanged,
    required this.onModelsUpdated,
    required this.onSettingsChanged,
  });

  final SettingsService settings;
  final String modelId;
  final List<AiModel> models;
  final String apiToken;
  final double temperature;
  final double topP;
  final double maxTokens;
  final bool streaming;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<List<AiModel>> onModelsUpdated;
  final VoidCallback onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Настройки',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textSecondary,
        ),
      ),
      body: SafeArea(
        child: SettingsPanel(
          showSideBorder: false,
          settings: settings,
          modelId: modelId,
          models: models,
          apiToken: apiToken,
          temperature: temperature,
          topP: topP,
          maxTokens: maxTokens,
          streaming: streaming,
          onModelChanged: onModelChanged,
          onModelsUpdated: onModelsUpdated,
          onSettingsChanged: onSettingsChanged,
        ),
      ),
    );
  }
}
