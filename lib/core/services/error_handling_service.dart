import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../config/environment_config.dart';
import '../utils/api_key_helper.dart';

/// Service untuk menangani error dan fallback AI responses
/// Mengatasi masalah 401 Unauthorized dan API key issues
class ErrorHandlingService {
  static const String _tag = 'ErrorHandlingService';

  /// Handle API errors dengan graceful fallback
  static Map<String, dynamic> handleApiError(dynamic error, {String? context}) {
    if (kDebugMode) {
      print('$_tag: Handling error in context: $context');
      print('$_tag: Error type: ${error.runtimeType}');
      print('$_tag: Error details: $error');
    }

    if (error is DioException) {
      return _handleDioError(error, context: context);
    }

    if (error is Exception) {
      return _handleGeneralException(error, context: context);
    }

    return _getGenericErrorResponse(context: context);
  }

  /// Handle Dio-specific errors (API calls)
  static Map<String, dynamic> _handleDioError(DioException error, {String? context}) {
    switch (error.response?.statusCode) {
      case 401:
        return _handle401Unauthorized(error, context: context);
      case 429:
        return _handle429RateLimit(error, context: context);
      case 500:
      case 502:
      case 503:
        return _handleServerError(error, context: context);
      default:
        return _handleUnknownDioError(error, context: context);
    }
  }

  /// Handle 401 Unauthorized - API Key issues
  static Map<String, dynamic> _handle401Unauthorized(DioException error, {String? context}) {
    if (kDebugMode) {
      print('$_tag: 401 Unauthorized error detected');
    }

    // Check if API key is configured
    if (!EnvironmentConfig.isApiKeyConfigured) {
      ApiKeyHelper.logApiKeyError();
      
      return {
        'success': false,
        'error': 'API_KEY_NOT_CONFIGURED',
        'message': 'OpenRouter API key belum dikonfigurasi. Silakan periksa file .env Anda.',
        'fallback': _getOfflineFallback(context: context),
        'userMessage': 'Fitur AI sedang tidak tersedia. Menggunakan mode offline.',
        'showApiKeyDialog': true,
      };
    }

    // API key configured but invalid
    return {
      'success': false,
      'error': 'API_KEY_INVALID',
      'message': 'API key tidak valid atau sudah kedaluwarsa.',
      'fallback': _getOfflineFallback(context: context),
      'userMessage': 'Koneksi AI bermasalah. Menggunakan mode offline.',
      'showApiKeyDialog': true,
    };
  }

  /// Handle 429 Rate Limit
  static Map<String, dynamic> _handle429RateLimit(DioException error, {String? context}) {
    if (kDebugMode) {
      print('$_tag: 429 Rate limit exceeded');
    }

    return {
      'success': false,
      'error': 'RATE_LIMIT_EXCEEDED',
      'message': 'Terlalu banyak permintaan. Silakan coba lagi nanti.',
      'fallback': _getOfflineFallback(context: context),
      'userMessage': 'Server sedang sibuk. Menggunakan respons offline.',
      'retryAfter': error.response?.headers['retry-after']?.first,
    };
  }

  /// Handle server errors (5xx)
  static Map<String, dynamic> _handleServerError(DioException error, {String? context}) {
    if (kDebugMode) {
      print('$_tag: Server error ${error.response?.statusCode}');
    }

    return {
      'success': false,
      'error': 'SERVER_ERROR',
      'message': 'Server mengalami masalah teknis.',
      'fallback': _getOfflineFallback(context: context),
      'userMessage': 'Server bermasalah. Menggunakan mode offline.',
      'statusCode': error.response?.statusCode,
    };
  }

  /// Handle unknown Dio errors
  static Map<String, dynamic> _handleUnknownDioError(DioException error, {String? context}) {
    if (kDebugMode) {
      print('$_tag: Unknown Dio error: ${error.type}');
    }

    return {
      'success': false,
      'error': 'NETWORK_ERROR',
      'message': 'Terjadi kesalahan jaringan.',
      'fallback': _getOfflineFallback(context: context),
      'userMessage': 'Koneksi bermasalah. Menggunakan mode offline.',
      'errorType': error.type.toString(),
    };
  }

  /// Handle general exceptions
  static Map<String, dynamic> _handleGeneralException(Exception error, {String? context}) {
    if (kDebugMode) {
      print('$_tag: General exception: $error');
    }

    if (error.toString().contains('OpenRouter API Key')) {
      return _handle401Unauthorized(
        DioException(requestOptions: RequestOptions()), 
        context: context
      );
    }

    return {
      'success': false,
      'error': 'GENERAL_ERROR',
      'message': 'Terjadi kesalahan yang tidak diketahui.',
      'fallback': _getOfflineFallback(context: context),
      'userMessage': 'Terjadi kesalahan. Menggunakan mode offline.',
    };
  }

  /// Get generic error response
  static Map<String, dynamic> _getGenericErrorResponse({String? context}) {
    return {
      'success': false,
      'error': 'UNKNOWN_ERROR',
      'message': 'Terjadi kesalahan yang tidak diketahui.',
      'fallback': _getOfflineFallback(context: context),
      'userMessage': 'Terjadi kesalahan. Menggunakan mode offline.',
    };
  }

  /// Get offline fallback response based on context
  static Map<String, dynamic> _getOfflineFallback({String? context}) {
    switch (context) {
      case 'chat':
        return {
          'type': 'chat_fallback',
          'content': 'Maaf, saya sedang tidak dapat terhubung ke server AI. '
                    'Namun, Anda masih dapat menggunakan fitur lokal seperti '
                    'pelacakan mood, tes psikologi, dan melihat riwayat chat.',
        };
      
      case 'music_recommendation':
        return {
          'type': 'music_fallback',
          'content': 'Rekomendasi musik tidak tersedia saat ini. '
                    'Silakan periksa koneksi internet Anda atau coba lagi nanti.',
          'suggestions': [
            'Periksa pengaturan API key',
            'Pastikan koneksi internet stabil',
            'Coba restart aplikasi',
          ],
        };
      
      case 'article_generation':
        return {
          'type': 'article_fallback',
          'content': 'Artikel AI tidak dapat dibuat saat ini. '
                    'Anda masih dapat mengakses fitur psychology test dan mood tracking.',
          'localFeatures': [
            'Tes MBTI offline',
            'Tes BDI offline',
            'Mood tracking',
            'Lihat riwayat data',
          ],
        };
      
      case 'quote_generation':
        return {
          'type': 'quote_fallback',
          'content': '"Setiap hari adalah kesempatan baru untuk menjadi versi terbaik dari diri kita." - Persona AI',
          'note': 'Kutipan AI tidak tersedia, menggunakan kutipan offline.',
        };
      
      default:
        return {
          'type': 'general_fallback',
          'content': 'Fitur AI sedang tidak tersedia. '
                    'Anda masih dapat menggunakan semua fitur lokal aplikasi.',
          'availableFeatures': [
            'Mood tracking',
            'Psychology tests',
            'Local chat history',
            'Settings & preferences',
          ],
        };
    }
  }

  /// Check if error is recoverable
  static bool isRecoverableError(Map<String, dynamic> errorResponse) {
    final errorType = errorResponse['error'];
    
    return [
      'RATE_LIMIT_EXCEEDED',
      'SERVER_ERROR',
      'NETWORK_ERROR',
    ].contains(errorType);
  }

  /// Get retry delay for recoverable errors
  static Duration getRetryDelay(Map<String, dynamic> errorResponse) {
    final errorType = errorResponse['error'];
    
    switch (errorType) {
      case 'RATE_LIMIT_EXCEEDED':
        final retryAfter = errorResponse['retryAfter'];
        if (retryAfter != null) {
          return Duration(seconds: int.tryParse(retryAfter) ?? 60);
        }
        return const Duration(minutes: 1);
      
      case 'SERVER_ERROR':
        return const Duration(seconds: 30);
      
      case 'NETWORK_ERROR':
        return const Duration(seconds: 10);
      
      default:
        return const Duration(seconds: 5);
    }
  }
}