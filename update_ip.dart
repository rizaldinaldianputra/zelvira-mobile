import 'dart:io';

void main() async {
  String? localIp;
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );

    for (var interface in interfaces) {
      // Prioritaskan koneksi Wi-Fi atau Ethernet
      final name = interface.name.toLowerCase();
      if (name.contains('wi-fi') ||
          name.contains('wlan') ||
          name.contains('ethernet') ||
          name.contains('eth')) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            localIp = addr.address;
            break;
          }
        }
      }
      if (localIp != null) break;
    }

    // Jika tidak ketemu Wi-Fi/Ethernet, ambil IP pertama yang bukan loopback
    if (localIp == null && interfaces.isNotEmpty) {
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            localIp = addr.address;
            break;
          }
        }
        if (localIp != null) break;
      }
    }

    if (localIp != null) {
      final file = File('lib/config/api_url.dart');
      final content =
          '''
import 'package:flutter/foundation.dart';

const String baseUrl = kReleaseMode
    ? 'https://api.zelvira.co.id'
    : 'http://$localIp:8081';
const String storageUrl = kReleaseMode
    ? 'https://s3.zelvira.co.id'
    : 'http://$localIp:9000';
''';
      await file.writeAsString(content);
    }
    // ignore: empty_catches
  } catch (e) {}
}
