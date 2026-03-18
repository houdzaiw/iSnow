
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final double? size;
  final BoxFit? fit;
  final Alignment alignment;
  final LoadingErrorWidgetBuilder? errorWidget;
  final PlaceholderWidgetBuilder? placeholder;
  final Color? color;
  final BlendMode? colorBlendMode;
  final bool ossScaling;
  final String format;
  final Duration fadeInDuration;
  final Duration? fadeOutDuration;
  final bool matchTextDirection;

  const NetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.size,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.alignment = Alignment.center,
    this.format = 'webp',
    this.color,
    this.colorBlendMode,
    this.ossScaling = true,
    this.matchTextDirection = false,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.fadeOutDuration = const Duration(milliseconds: 1000),
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder(context);
    }

    final dpr = MediaQuery.of(context).devicePixelRatio;
    final displayWidth = (size ?? width ?? 0) * dpr;
    final displayHeight = (size ?? height ?? 0) * dpr;

    // 通过 OSS 裁剪服务缩小下载图（可选但非常推荐）
    // final dealUrl = NadyImageUtils.getImageUrl(imageUrl, displayWidth.toInt());

    return SizedBox(
      width: size ?? width,
      height: size ?? height,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        memCacheWidth: displayWidth.toInt(),
        memCacheHeight: displayHeight.toInt(),
        fadeInDuration: fadeInDuration,
        fadeOutDuration: fadeOutDuration,
        placeholder: placeholder ?? (_, __) => _defaultPlaceholder(),
        errorWidget: (context, url, error) {
          // Logger.infoWrite("image load failed: $url - $error");
          return errorWidget?.call(context, url, error) ??
              _errorWidget(context, url, error);
        },
        cacheKey: imageUrl,  // 如果你 url 本身就唯一，直接写这行就行
      ),
    );
  }


  SizedBox _buildPlaceholder(BuildContext context) {
    return SizedBox(
        width: size ?? width,
        height: size ?? height,
        child: errorWidget?.call(context, imageUrl, "url isEmpty") ??
            placeholder?.call(context, imageUrl) ??
            _defaultPlaceholder());
  }

  Widget _errorWidget(BuildContext context, String url, Object error) {
    return _defaultPlaceholder();
  }

  Widget _defaultPlaceholder() {
    return SizedBox(
        width: size ?? width,
        height: size ?? height,
        child: Icon(
        Icons.person,
        size: 50,
        color: Colors.white,
    ));
    // return BlurHash(
    //     hash: "K2RMe@%M00?cayWB00ay~p", imageFit: fit ?? BoxFit.cover);
  }
}

class NetworkImageClipWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final double? size;
  final BoxFit? fit;
  final Alignment alignment;
  final LoadingErrorWidgetBuilder? errorWidget;
  final PlaceholderWidgetBuilder? placeholder;
  final Color? color;
  final BlendMode? colorBlendMode;
  final BorderRadius? borderRadius;
  final Clip clipBehavior;
  final EdgeInsetsGeometry? padding;
  final bool ossScaling;
  final String format;
  final Duration fadeInDuration;
  final Duration? fadeOutDuration;
  final bool matchTextDirection;

  const NetworkImageClipWidget({
    super.key,
    required this.imageUrl,
    this.size,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.alignment = Alignment.center,
    this.format = 'webp',
    this.color,
    this.colorBlendMode,
    this.borderRadius,
    this.clipBehavior = Clip.none,
    this.padding,
    this.ossScaling = true,
    this.matchTextDirection = false,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.fadeOutDuration = const Duration(milliseconds: 1000),
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      // Logger.infoWrite("图片为空 StackTrace:${StackTrace.current}");
      return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          clipBehavior: clipBehavior,
          child: errorWidget?.call(context, imageUrl, "url isEmpty") ??
              placeholder?.call(context, imageUrl) ??
              _defaultPlaceholder());
    }
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      clipBehavior: clipBehavior,
      child: CachedNetworkImage(
        imageUrl: imageUrl,//imageUrl,
        width: size ?? width,
        height: size ?? height,
        fit: fit,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: fadeOutDuration,
        memCacheHeight: 0,
        memCacheWidth: 0,
        maxHeightDiskCache: 300,
        maxWidthDiskCache: 300,
        imageBuilder: (context, provider) {
          final dpr = MediaQuery.of(context).devicePixelRatio;
          final decodeWidth = ((size ?? width ?? 0) * dpr).toInt();
          return Image(
            image: ResizeImage(
              provider,
              width: decodeWidth, // 最关键
            ),
            fit: BoxFit.cover,
          );
        },
        placeholder: placeholder ?? (context, url) => _defaultPlaceholder(),
        errorWidget: (BuildContext context, String url, Object error) {
          // Logger.infoWrite("图片加载失败： ${url} - ${error} - StackTrace:${StackTrace.current}" );
          // Uri uri = Uri.parse(url);
          // NadyPingUtils().pingWithHost(host: uri.host);

          if (errorWidget != null) {
            return errorWidget!(context, url, error);
          } else {
            return _errorWidget(context, url, error);
          }
        },
        alignment: alignment,
        color: color,
        colorBlendMode: colorBlendMode,
        matchTextDirection: matchTextDirection,

      ),
    );
  }

  Widget _errorWidget(BuildContext context, String url, Object error) {
    return _defaultPlaceholder();
  }

  Widget _defaultPlaceholder() {
    return SizedBox(
        width: size ?? width,
        height: size ?? height,
        child: Icon(
          Icons.person,
          size: 50,
          color: Colors.white,
        ));
    // return BlurHash(
    //     hash: "K2RMe@%M00?cayWB00ay~p", imageFit: fit ?? BoxFit.cover);
  }
}