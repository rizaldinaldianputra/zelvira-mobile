class AppVersionModel {
  final String latestVersion;
  final String minVersion;
  final String title;
  final String message;
  final String downloadUrl;
  final bool forceUpdate;

  AppVersionModel({
    required this.latestVersion,
    required this.minVersion,
    required this.title,
    required this.message,
    required this.downloadUrl,
    required this.forceUpdate,
  });

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      latestVersion: json['latestVersion']?.toString() ?? '1.0.0',
      minVersion: json['minVersion']?.toString() ?? '1.0.0',
      title: json['title']?.toString() ?? 'Pembaruan Aplikasi Tersedia',
      message:
          json['message']?.toString() ??
          'Versi terbaru aplikasi Zelvira telah tersedia dengan fitur baru dan peningkatan performa.',
      downloadUrl:
          json['downloadUrl']?.toString() ??
          'https://play.google.com/store/apps/details?id=com.zelvira.ecommerce',
      forceUpdate: json['forceUpdate'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latestVersion': latestVersion,
      'minVersion': minVersion,
      'title': title,
      'message': message,
      'downloadUrl': downloadUrl,
      'forceUpdate': forceUpdate,
    };
  }
}
