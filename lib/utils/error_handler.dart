import 'dart:developer' as developer;

class NetworkError implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;
  final StackTrace? stackTrace;

  NetworkError({
    this.message = 'A network error occurred',
    this.statusCode,
    this.originalError,
    this.stackTrace,
  });
  
  @override
  String toString() => 'NetworkError: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class ChatError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  ChatError(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'ChatError: $message${code != null ? ' (Code: $code)' : ''}';
}

class StorageError implements Exception {
  final String message;
  final dynamic originalError;

  StorageError(this.message, {this.originalError});

  @override
  String toString() => 'StorageError: $message';
}

class ValidationError implements Exception {
  final String message;
  final String? field;

  ValidationError(this.message, {this.field});

  @override
  String toString() => 'ValidationError: $message${field != null ? ' (Field: $field)' : ''}';
}

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    _logError(error);
    if (error is ChatError) {
      return error.message;
    } else if (error is NetworkError) {
      if (error.statusCode != null) {
        switch (error.statusCode) {
          case 401:
            return 'Authentication failed. Please log in again.';
          case 403:
            return 'You don\'t have permission to perform this action.';
          case 404:
            return 'The requested resource was not found.';
          case 500:
            return 'Server error. Please try again later.';
          default:
            return error.message;
        }
      }
      return 'Network connection error. Please check your internet connection.';
    } else if (error is StorageError) {
      return 'Failed to save or load data: ${error.message}';
    } else if (error is ValidationError) {
      return error.message;
    } else if (error is TypeError) {
      return 'An unexpected type error occurred. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again later.';
    }
  }

  static bool shouldRetry(dynamic error) {
    if (error is NetworkError) {
      // Retry on network errors except for auth/permission issues
      return error.statusCode == null || 
             (error.statusCode != 401 && error.statusCode != 403);
    }
    return error is StorageError; // Retry storage errors
  }

  static void _logError(dynamic error, [StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    final errorDetails = {
      'timestamp': timestamp,
      'error': error.toString(),
      'type': error.runtimeType.toString(),
      'stackTrace': stackTrace?.toString() ?? StackTrace.current.toString(),
    };

    if (error is ChatError) {
      errorDetails['code'] = error.code ?? 'UNKNOWN';
      errorDetails['originalError'] = error.originalError?.toString() ?? 'None';
    } else if (error is NetworkError) {
      errorDetails['statusCode'] = error.statusCode?.toString() ?? 'None';
      errorDetails['originalError'] = error.originalError?.toString() ?? 'None';
    }

    developer.log(
      'Error occurred',
      error: error,
      stackTrace: stackTrace ?? StackTrace.current,
      name: 'ErrorHandler',
      time: DateTime.now(),
    );
  }
}
