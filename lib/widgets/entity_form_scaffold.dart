import 'package:flutter/material.dart';
import 'package:task_management/theme/app_colors.dart';

/// Common Scaffold shell for entity create/update forms: app bar with a save
/// action, a dismissible error banner, and a loading overlay shown while saving.
class EntityFormScaffold extends StatelessWidget {
  final String title;
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final String loadingMessage;
  final String errorMessage;
  final VoidCallback onDismissError;
  final VoidCallback? onSave;
  final String saveTooltip;
  final List<Widget> children;
  final Widget? bottomNavigationBar;

  const EntityFormScaffold({
    super.key,
    required this.title,
    required this.formKey,
    required this.isLoading,
    required this.loadingMessage,
    required this.errorMessage,
    required this.onDismissError,
    required this.onSave,
    required this.saveTooltip,
    required this.children,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!isLoading)
            IconButton(
              onPressed: onSave,
              icon: const Icon(Icons.save),
              tooltip: saveTooltip,
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (errorMessage.isNotEmpty)
                    _ErrorBanner(message: errorMessage, onDismiss: onDismissError),
                  ...children,
                ],
              ),
            ),
          ),
          if (isLoading) _LoadingOverlay(message: loadingMessage),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.blush,
        border: Border.all(color: AppColors.rust.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.rust),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: AppColors.rust)),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onDismiss),
        ],
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  final String message;

  const _LoadingOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
