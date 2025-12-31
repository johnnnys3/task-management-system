import 'package:logging/logging.dart';

/// App-wide logger utility
class AppLogger {
  static final Map<String, Logger> _loggers = {};
  
  /// Gets or creates a logger for a specific name
  static Logger getLogger(String name) {
    return _loggers.putIfAbsent(name, () => Logger(name));
  }
  
  /// Initializes the logging system
  static void init() {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      // In production, you might want to send logs to a service
      // For now, we'll just print them
      print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
      
      if (record.error != null) {
        print('Error: ${record.error}');
      }
      
      if (record.stackTrace != null) {
        print('Stack trace: ${record.stackTrace}');
      }
    });
  }
  
  /// Sets log level for a specific logger
  static void setLevel(String name, Level level) {
    final logger = getLogger(name);
    logger.level = level;
  }
  
  /// Convenience methods for common logging operations
  static void debug(String message, [String? loggerName]) {
    final logger = loggerName != null ? getLogger(loggerName) : Logger.root;
    logger.fine(message);
  }
  
  static void info(String message, [String? loggerName]) {
    final logger = loggerName != null ? getLogger(loggerName) : Logger.root;
    logger.info(message);
  }
  
  static void warning(String message, [String? loggerName]) {
    final logger = loggerName != null ? getLogger(loggerName) : Logger.root;
    logger.warning(message);
  }
  
  static void severe(String message, [String? loggerName, Object? error, StackTrace? stackTrace]) {
    final logger = loggerName != null ? getLogger(loggerName) : Logger.root;
    logger.severe(message, error, stackTrace);
  }
  
  static void shout(String message, [String? loggerName]) {
    final logger = loggerName != null ? getLogger(loggerName) : Logger.root;
    logger.shout(message);
  }
}
