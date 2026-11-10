import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:exe_matching/config/app_config.dart';
import 'package:exe_matching/services/group_service.dart';
import 'package:http/http.dart' as http;

/// Upload file len Cloudinary bang unsigned upload preset.
/// App khong chua API secret; preset gioi han dinh dang PDF va kich thuoc file.
class FileStorageService {
  final String _cloudName;
  final String _uploadPreset;
  final http.Client _client;

  FileStorageService({String? cloudName, String? uploadPreset, http.Client? client})
    : _cloudName = cloudName ?? AppConfig.cloudinaryCloudName,
      _uploadPreset = uploadPreset ?? AppConfig.cloudinaryUploadPreset,
      _client = client ?? http.Client();

  bool get isConfigured => _cloudName.isNotEmpty && _uploadPreset.isNotEmpty;

  /// Tra ve URL HTTPS cua file da upload.
  Future<String> uploadPdf({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async {
    if (!isConfigured) {
      throw const BusinessException(
        'Chưa cấu hình Cloudinary. Hãy chạy app với --dart-define-from-file=cloudinary.json.',
      );
    }
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/auto/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(const Duration(seconds: 60));
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw const BusinessException('Không có kết nối mạng, chưa upload được báo cáo.');
    } on TimeoutException {
      throw const BusinessException('Upload quá lâu. Hãy kiểm tra mạng rồi thử lại.');
    } on http.ClientException {
      throw const BusinessException('Không có kết nối mạng, chưa upload được báo cáo.');
    }

    if (response.statusCode != 200) {
      throw BusinessException('Upload thất bại: ${_errorMessage(response)}');
    }
    final url = (jsonDecode(response.body) as Map<String, dynamic>)['secure_url'] as String?;
    if (url == null) throw const BusinessException('Upload thất bại: không nhận được đường dẫn.');
    return url;
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = (body['error'] as Map<String, dynamic>?)?['message'] as String?;
      if (message != null) return message;
    } on FormatException {
      // Phan hoi khong phai JSON: dung ma HTTP ben duoi.
    }
    return 'mã lỗi ${response.statusCode}';
  }
}
