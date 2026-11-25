import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/url_utils.dart';

class CustomNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment alignment;
  final Color? color;
  final BlendMode? colorBlendMode;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;

  const CustomNetworkImage(
    this.imageUrl, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.color,
    this.colorBlendMode,
    this.errorBuilder,
    this.loadingBuilder,
  });

  Widget _buildNoImageFallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey.shade400,
              size: (width != null && width! < 50) ? 18 : 28,
            ),
            if (width == null || width! > 70)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'No Image',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedUrl = UrlUtils.formatImageUrl(imageUrl);
    if (formattedUrl.isEmpty) {
      return _buildNoImageFallback(context);
    }

    return CachedNetworkImage(
      imageUrl: formattedUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      alignment: alignment,
      color: color,
      colorBlendMode: colorBlendMode,
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade100,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        if (errorBuilder != null) {
          return errorBuilder!(context, error, null);
        }
        return _buildNoImageFallback(context);
      },
    );
  }
}
