import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

/// Returns an [ImageProvider] for various string sources.
///
/// Supports HTTP URLs, base64 data URIs and local file paths.
ImageProvider getImageProvider(String path, {ImageProvider? placeholder}) {
  try {
    if (path.startsWith('data:image/')) {
      final base64Data = path.split(',').last;
      final bytes = base64Decode(base64Data);
      return MemoryImage(bytes);
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }

    if (File(path).existsSync()) {
      return FileImage(File(path));
    }
  } catch (_) {
    // ignore errors and fall through to placeholder
  }

  return placeholder ?? const AssetImage('assets/images/default_avatar.jpg');
}