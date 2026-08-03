import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppNetworkImage extends StatelessWidget {
  final String url;

  /// 尺寸
  final double? width;
  final double? height;

  /// 圆角
  final double radius;
  final BorderRadius? borderRadius;

  /// 填充模式
  final BoxFit fit;

  /// 占位图
  final Widget? placeholder;

  /// 错误图
  final Widget? errorWidget;

  /// 是否省流量（加载低分辨率）
  final bool lowQuality;

  /// 自定义缓存 key
  final String? cacheKey;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = 0,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.lowQuality = false,
    this.cacheKey,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(radius);

    return ClipRRect(
      borderRadius: br,
      child: CachedNetworkImage(
        imageUrl: _buildUrl(url),
        width: width,
        height: height,
        fit: fit,
        cacheKey: cacheKey,

        /// 占位图
        placeholder: (context, url) =>
        placeholder ?? _defaultPlaceholder(),

        /// 错误图
        errorWidget: (context, url, error) =>
        errorWidget ?? _defaultErrorWidget(),

        /// 关键：降低内存占用
        memCacheWidth: _memCacheWidth(),
        memCacheHeight: _memCacheHeight(),

        /// 淡入效果
        fadeInDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  /// 构建低质量图片（可接 CDN 参数）
  String _buildUrl(String url) {
    if (!lowQuality) return url;

    /// 示例：如果你用阿里云 / 七牛 / CDN 可以加参数
    /// 比如：?imageView2/1/w/200
    return "$url?x-oss-process=image/resize,w_200";
  }

  /// 根据组件尺寸控制缓存大小（关键优化🔥）
  int? _memCacheWidth() {
    if (width == null) return null;
    return (width! * 2).toInt(); // 适配2x屏幕
  }

  int? _memCacheHeight() {
    if (height == null) return null;
    return (height! * 2).toInt();
  }

  Widget _defaultPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, size: 24),
    );
  }
}