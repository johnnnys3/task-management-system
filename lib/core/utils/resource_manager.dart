import 'dart:async';
import 'package:flutter/material.dart';
import 'package:task_management/core/utils/logger.dart';

/// Resource management utility for proper disposal of resources
class ResourceManager {
  ResourceManager._();

  static final Set<DisposableResource> _resources = {};
  static final Set<StreamSubscription> _subscriptions = {};
  static final Set<AnimationController> _animationControllers = {};
  static final Set<ScrollController> _scrollControllers = {};
  static final Set<TextEditingController> _textEditingControllers = {};

  /// Registers a disposable resource
  static void registerResource(DisposableResource resource) {
    _resources.add(resource);
    AppLogger.debug('Registered resource');
  }

  /// Registers a stream subscription
  static void registerSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
    AppLogger.debug('Registered subscription');
  }

  /// Registers an animation controller
  static void registerAnimationController(AnimationController controller) {
    _animationControllers.add(controller);
    AppLogger.debug('Registered animation controller');
  }

  /// Registers a scroll controller
  static void registerScrollController(ScrollController controller) {
    _scrollControllers.add(controller);
    AppLogger.debug('Registered scroll controller');
  }

  /// Registers a text editing controller
  static void registerTextEditingController(TextEditingController controller) {
    _textEditingControllers.add(controller);
    AppLogger.debug('Registered text editing controller');
  }

  /// Disposes a specific resource
  static Future<void> disposeResource(DisposableResource resource) async {
    try {
      await resource.dispose();
      _resources.remove(resource);
      AppLogger.debug('Disposed resource');
    } catch (e) {
      AppLogger.warning('Failed to dispose resource: ${e.toString()}');
    }
  }

  /// Disposes a specific subscription
  static Future<void> disposeSubscription(StreamSubscription subscription) async {
    try {
      await subscription.cancel();
      _subscriptions.remove(subscription);
      AppLogger.debug('Disposed subscription');
    } catch (e) {
      AppLogger.warning('Failed to dispose subscription: ${e.toString()}');
    }
  }

  /// Disposes an animation controller
  static void disposeAnimationController(AnimationController controller) {
    try {
      controller.dispose();
      _animationControllers.remove(controller);
      AppLogger.debug('Disposed animation controller');
    } catch (e) {
      AppLogger.warning('Failed to dispose animation controller: ${e.toString()}');
    }
  }

  /// Disposes a scroll controller
  static void disposeScrollController(ScrollController controller) {
    try {
      controller.dispose();
      _scrollControllers.remove(controller);
      AppLogger.debug('Disposed scroll controller');
    } catch (e) {
      AppLogger.warning('Failed to dispose scroll controller: ${e.toString()}');
    }
  }

  /// Disposes a text editing controller
  static void disposeTextEditingController(TextEditingController controller) {
    try {
      controller.dispose();
      _textEditingControllers.remove(controller);
      AppLogger.debug('Disposed text editing controller');
    } catch (e) {
      AppLogger.warning('Failed to dispose text editing controller: ${e.toString()}');
    }
  }

  /// Disposes all registered resources
  static Future<void> disposeAll() async {
    AppLogger.info('Disposing all resources...');
    
    // Dispose subscriptions first
    for (final subscription in _subscriptions) {
      try {
        await subscription.cancel();
      } catch (e) {
        AppLogger.warning('Failed to cancel subscription: ${e.toString()}');
      }
    }
    _subscriptions.clear();

    // Dispose animation controllers
    for (final controller in _animationControllers) {
      try {
        controller.dispose();
      } catch (e) {
        AppLogger.warning('Failed to dispose animation controller: ${e.toString()}');
      }
    }
    _animationControllers.clear();

    // Dispose scroll controllers
    for (final controller in _scrollControllers) {
      try {
        controller.dispose();
      } catch (e) {
        AppLogger.warning('Failed to dispose scroll controller: ${e.toString()}');
      }
    }
    _scrollControllers.clear();

    // Dispose text editing controllers
    for (final controller in _textEditingControllers) {
      try {
        controller.dispose();
      } catch (e) {
        AppLogger.warning('Failed to dispose text editing controller: ${e.toString()}');
      }
    }
    _textEditingControllers.clear();

    // Dispose custom resources
    for (final resource in _resources) {
      try {
        await resource.dispose();
      } catch (e) {
        AppLogger.warning('Failed to dispose resource: ${e.toString()}');
      }
    }
    _resources.clear();

    AppLogger.info('All resources disposed');
  }

  /// Gets resource statistics
  static Map<String, int> getResourceStats() {
    return {
      'resources': _resources.length,
      'subscriptions': _subscriptions.length,
      'animationControllers': _animationControllers.length,
      'scrollControllers': _scrollControllers.length,
      'textEditingControllers': _textEditingControllers.length,
    };
  }

  /// Checks for memory leaks by monitoring resource counts
  static void checkForLeaks() {
    final stats = getResourceStats();
    final totalResources = stats.values.fold(0, (sum, count) => sum + count);
    
    if (totalResources > 50) {
      AppLogger.warning('Potential memory leak detected: $totalResources active resources');
      AppLogger.warning('Resource stats: $stats');
    }
  }
}

/// Interface for disposable resources
abstract class DisposableResource {
  Future<void> dispose();
}

/// Mixin for automatic resource management in widgets
mixin ResourceManagementMixin<T extends StatefulWidget> on State<T> {
  final List<DisposableResource> _resources = [];
  final List<StreamSubscription> _subscriptions = [];
  final List<AnimationController> _animationControllers = [];
  final List<ScrollController> _scrollControllers = [];
  final List<TextEditingController> _textEditingControllers = [];

  /// Registers a resource for automatic disposal
  void registerResource(DisposableResource resource) {
    _resources.add(resource);
    ResourceManager.registerResource(resource);
  }

  /// Registers a subscription for automatic disposal
  void registerSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
    ResourceManager.registerSubscription(subscription);
  }

  /// Registers an animation controller for automatic disposal
  void registerAnimationController(AnimationController controller) {
    _animationControllers.add(controller);
    ResourceManager.registerAnimationController(controller);
  }

  /// Registers a scroll controller for automatic disposal
  void registerScrollController(ScrollController controller) {
    _scrollControllers.add(controller);
    ResourceManager.registerScrollController(controller);
  }

  /// Registers a text editing controller for automatic disposal
  void registerTextEditingController(TextEditingController controller) {
    _textEditingControllers.add(controller);
    ResourceManager.registerTextEditingController(controller);
  }

  @override
  void dispose() {
    // Dispose all registered resources
    for (final resource in _resources) {
      ResourceManager.disposeResource(resource);
    }
    _resources.clear();

    for (final subscription in _subscriptions) {
      ResourceManager.disposeSubscription(subscription);
    }
    _subscriptions.clear();

    for (final controller in _animationControllers) {
      ResourceManager.disposeAnimationController(controller);
    }
    _animationControllers.clear();

    for (final controller in _scrollControllers) {
      ResourceManager.disposeScrollController(controller);
    }
    _scrollControllers.clear();

    for (final controller in _textEditingControllers) {
      ResourceManager.disposeTextEditingController(controller);
    }
    _textEditingControllers.clear();

    super.dispose();
  }
}

/// Widget that automatically manages resources
class ResourceManagedWidget extends StatefulWidget {

  const ResourceManagedWidget({
    super.key,
    required this.child,
    this.resources,
    this.subscriptions,
    this.animationControllers,
    this.scrollControllers,
    this.textEditingControllers,
  });
  final Widget child;
  final List<DisposableResource>? resources;
  final List<StreamSubscription>? subscriptions;
  final List<AnimationController>? animationControllers;
  final List<ScrollController>? scrollControllers;
  final List<TextEditingController>? textEditingControllers;

  @override
  State<ResourceManagedWidget> createState() => _ResourceManagedWidgetState();
}

class _ResourceManagedWidgetState extends State<ResourceManagedWidget> {
  @override
  void initState() {
    super.initState();
    
    // Register all provided resources
    widget.resources?.forEach(ResourceManager.registerResource);
    widget.subscriptions?.forEach(ResourceManager.registerSubscription);
    widget.animationControllers?.forEach(ResourceManager.registerAnimationController);
    widget.scrollControllers?.forEach(ResourceManager.registerScrollController);
    widget.textEditingControllers?.forEach(ResourceManager.registerTextEditingController);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    // Dispose all provided resources
    widget.resources?.forEach(ResourceManager.disposeResource);
    widget.subscriptions?.forEach(ResourceManager.disposeSubscription);
    widget.animationControllers?.forEach(ResourceManager.disposeAnimationController);
    widget.scrollControllers?.forEach(ResourceManager.disposeScrollController);
    widget.textEditingControllers?.forEach(ResourceManager.disposeTextEditingController);
    
    super.dispose();
  }
}

/// Memory leak detector for debugging
class MemoryLeakDetector {
  MemoryLeakDetector._();

  static final Map<String, int> _resourceCounts = {};
  static Timer? _monitoringTimer;

  /// Starts monitoring for memory leaks
  static void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(interval, (_) {
      _checkResourceLeaks();
    });
    AppLogger.info('Started memory leak monitoring');
  }

  /// Stops monitoring for memory leaks
  static void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    AppLogger.info('Stopped memory leak monitoring');
  }

  /// Checks for resource leaks
  static void _checkResourceLeaks() {
    final stats = ResourceManager.getResourceStats();
    
    for (final entry in stats.entries) {
      final resourceType = entry.key;
      final count = entry.value;
      final previousCount = _resourceCounts[resourceType] ?? 0;
      
      if (count > previousCount) {
        final increase = count - previousCount;
        AppLogger.warning('Resource leak detected: $resourceType increased by $increase');
      }
      
      _resourceCounts[resourceType] = count;
    }
  }

  /// Gets resource count history
  static Map<String, int> getResourceCountHistory() {
    return Map.from(_resourceCounts);
  }

  /// Resets resource count history
  static void resetHistory() {
    _resourceCounts.clear();
    AppLogger.info('Reset resource count history');
  }
}
