part of 'player.dart';

class _SVGAPainter extends CustomPainter {
  final BoxFit fit;
  final SVGAAnimationController controller;
  final FilterQuality filterQuality;

  // 各绘制类型独立复用 Paint，避免跨 sprite 分配对象或遗留状态串扰。
  late final Paint _bitmapPaint = Paint()
    ..filterQuality = filterQuality
    ..isAntiAlias = true;
  final Paint _fillPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Float64List _transform = Float64List.fromList(<double>[
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
  ]);

  /// Guaranteed to draw within the canvas bounds
  final bool clipRect;
  _SVGAPainter(
    this.controller, {
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.low,
    this.clipRect = true,
  })  : assert(
            controller.videoItem != null, 'Invalid SVGAAnimationController!'),
        super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    if (controller._canvasNeedsClear) {
      // mark cleared
      controller._canvasNeedsClear = false;
      return;
    }
    final videoItem = controller.videoItem;
    if (size.isEmpty || videoItem == null) return;
    final params = videoItem.params;
    final Size viewBoxSize = Size(params.viewBoxWidth, params.viewBoxHeight);
    if (viewBoxSize.isEmpty) return;
    final frameIndex = controller.currentFrame;
    final dynamicItem = videoItem.dynamicItem;
    canvas.save();
    try {
      final canvasRect = Offset.zero & size;
      if (clipRect) canvas.clipRect(canvasRect);
      scaleCanvasToViewBox(canvas, canvasRect, Offset.zero & viewBoxSize);
      drawSprites(canvas, videoItem, dynamicItem, frameIndex);
    } finally {
      canvas.restore();
    }
  }

  void scaleCanvasToViewBox(Canvas canvas, Rect canvasRect, Rect viewBoxRect) {
    final fittedSizes = applyBoxFit(fit, viewBoxRect.size, canvasRect.size);

    // scale viewbox size (source) to canvas size (destination)
    var sx = fittedSizes.destination.width / fittedSizes.source.width;
    var sy = fittedSizes.destination.height / fittedSizes.source.height;
    final Size scaledHalfViewBoxSize =
        Size(viewBoxRect.size.width * sx, viewBoxRect.size.height * sy) / 2.0;
    final Size halfCanvasSize = canvasRect.size / 2.0;
    // center align
    final Offset shift = Offset(
      halfCanvasSize.width - scaledHalfViewBoxSize.width,
      halfCanvasSize.height - scaledHalfViewBoxSize.height,
    );
    if (shift != Offset.zero) canvas.translate(shift.dx, shift.dy);
    if (sx != 1.0 && sy != 1.0) canvas.scale(sx, sy);
  }

  void drawSprites(
    Canvas canvas,
    MovieEntity videoItem,
    SVGADynamicEntity dynamicItem,
    int frameIndex,
  ) {
    final dynamicHidden = dynamicItem.dynamicHidden;
    final dynamicImages = dynamicItem.dynamicImages;
    final dynamicText = dynamicItem.dynamicText;
    final dynamicDrawer = dynamicItem.dynamicDrawer;
    // 仅固定本次 paint 的 Map 引用，Map 内容仍允许业务在后续帧动态更新。
    final bitmapCache = videoItem.bitmapCache;
    final sprites = videoItem.sprites;
    for (final sprite in sprites) {
      final imageKey = sprite.imageKey;
      // var matteKey = sprite.matteKey;
      if (imageKey.isEmpty || dynamicHidden[imageKey] == true) {
        continue;
      }
      final frameItem = sprite.frames[frameIndex];
      final needTransform = frameItem.hasTransform();
      final needClip = frameItem.hasClipPath();
      if (needTransform) {
        canvas.save();
        _applyTransform(canvas, frameItem.transform);
      }
      if (needClip) {
        canvas.save();
        canvas.clipPath(buildDPath(frameItem.clipPath, videoItem));
      }
      final layout = frameItem.layout;
      final frameRect = Rect.fromLTRB(0, 0, layout.width, layout.height);
      final frameAlpha =
          frameItem.hasAlpha() ? (frameItem.alpha * 255).toInt() : 255;
      drawBitmap(
        canvas,
        imageKey,
        frameRect,
        frameAlpha,
        dynamicImages,
        dynamicText,
        bitmapCache,
      );
      drawShape(canvas, frameItem.shapes, frameAlpha, videoItem);
      // draw dynamic
      final drawer = dynamicDrawer[imageKey];
      if (drawer != null) {
        drawer(canvas, frameIndex);
      }
      if (needClip) {
        canvas.restore();
      }
      if (needTransform) {
        canvas.restore();
      }
    }
  }

  void _applyTransform(Canvas canvas, svga.Transform transform) {
    _transform[0] = transform.a;
    _transform[1] = transform.b;
    _transform[4] = transform.c;
    _transform[5] = transform.d;
    _transform[12] = transform.tx;
    _transform[13] = transform.ty;
    // Canvas 会同步读取矩阵，复用缓冲区不会改变已经应用的画布状态。
    canvas.transform(_transform);
  }

  void drawBitmap(
    Canvas canvas,
    String imageKey,
    Rect frameRect,
    int alpha,
    Map<String, ui.Image> dynamicImages,
    Map<String, TextPainter> dynamicText,
    Map<String, ui.Image> bitmapCache,
  ) {
    final bitmap = dynamicImages[imageKey] ?? bitmapCache[imageKey];
    if (bitmap == null) return;

    _bitmapPaint.color = Color.fromARGB(alpha, 0, 0, 0);

    final srcRect =
        Rect.fromLTRB(0, 0, bitmap.width.toDouble(), bitmap.height.toDouble());
    canvas.drawImageRect(bitmap, srcRect, frameRect, _bitmapPaint);
    drawTextOnBitmap(canvas, imageKey, frameRect, dynamicText);
  }

  void drawShape(
    Canvas canvas,
    List<ShapeEntity> shapes,
    int frameAlpha,
    MovieEntity videoItem,
  ) {
    if (shapes.isEmpty) return;
    for (var shape in shapes) {
      final path = buildPath(shape, videoItem);
      final hasTransform = shape.hasTransform();
      if (hasTransform) {
        canvas.save();
        _applyTransform(canvas, shape.transform);
      }

      final styles = shape.styles;
      final fill = styles.fill;
      if (fill.isInitialized()) {
        _fillPaint
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..color = Color.fromARGB(
            (fill.a * frameAlpha).toInt(),
            (fill.r * 255).toInt(),
            (fill.g * 255).toInt(),
            (fill.b * 255).toInt(),
          );
        canvas.drawPath(path, _fillPaint);
      }
      final strokeWidth = styles.strokeWidth;
      if (strokeWidth > 0) {
        final stroke = styles.stroke;
        _strokePaint
          ..isAntiAlias = false
          ..style = PaintingStyle.stroke
          ..color = stroke.isInitialized()
              ? Color.fromARGB(
                  (stroke.a * frameAlpha).toInt(),
                  (stroke.r * 255).toInt(),
                  (stroke.g * 255).toInt(),
                  (stroke.b * 255).toInt(),
                )
              : const Color(0xFF000000)
          ..strokeWidth = strokeWidth
          ..strokeCap = _strokeCap(styles.lineCap)
          ..strokeJoin = _strokeJoin(styles.lineJoin)
          ..strokeMiterLimit = styles.miterLimit;
        final lineDashI = styles.lineDashI;
        final lineDashII = styles.lineDashII;
        final lineDashIII = styles.lineDashIII;
        if (lineDashI > 0 || lineDashII > 0) {
          canvas.drawPath(
              dashPath(
                path,
                dashArray: CircularIntervalList([
                  lineDashI < 1.0 ? 1.0 : lineDashI,
                  lineDashII < 0.1 ? 0.1 : lineDashII,
                ]),
                dashOffset: DashOffset.absolute(lineDashIII),
              ),
              _strokePaint);
        } else {
          canvas.drawPath(path, _strokePaint);
        }
      }
      if (hasTransform) {
        canvas.restore();
      }
    }
  }

  StrokeCap _strokeCap(ShapeEntity_ShapeStyle_LineCap lineCap) {
    switch (lineCap) {
      case ShapeEntity_ShapeStyle_LineCap.LineCap_ROUND:
        return StrokeCap.round;
      case ShapeEntity_ShapeStyle_LineCap.LineCap_SQUARE:
        return StrokeCap.square;
      case ShapeEntity_ShapeStyle_LineCap.LineCap_BUTT:
      default:
        return StrokeCap.butt;
    }
  }

  StrokeJoin _strokeJoin(ShapeEntity_ShapeStyle_LineJoin lineJoin) {
    switch (lineJoin) {
      case ShapeEntity_ShapeStyle_LineJoin.LineJoin_ROUND:
        return StrokeJoin.round;
      case ShapeEntity_ShapeStyle_LineJoin.LineJoin_BEVEL:
        return StrokeJoin.bevel;
      case ShapeEntity_ShapeStyle_LineJoin.LineJoin_MITER:
      default:
        return StrokeJoin.miter;
    }
  }

  static const _validMethods = 'MLHVCSQRZmlhvcsqrz';

  Path buildPath(ShapeEntity shape, MovieEntity videoItem) {
    final path = Path();
    if (shape.type == ShapeEntity_ShapeType.SHAPE) {
      final args = shape.shape;
      final argD = args.d;
      return buildDPath(argD, videoItem, path: path);
    } else if (shape.type == ShapeEntity_ShapeType.ELLIPSE) {
      final args = shape.ellipse;
      final xv = args.x;
      final yv = args.y;
      final rxv = args.radiusX;
      final ryv = args.radiusY;
      final rect = Rect.fromLTWH(xv - rxv, yv - ryv, rxv * 2, ryv * 2);
      if (!rect.isEmpty) path.addOval(rect);
    } else if (shape.type == ShapeEntity_ShapeType.RECT) {
      final args = shape.rect;
      final xv = args.x;
      final yv = args.y;
      final wv = args.width;
      final hv = args.height;
      final crv = args.cornerRadius;
      final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(xv, yv, wv, hv), Radius.circular(crv));
      if (!rrect.isEmpty) path.addRRect(rrect);
    }
    return path;
  }

  Path buildDPath(String argD, MovieEntity videoItem, {Path? path}) {
    final pathCache = videoItem.pathCache;
    final cachedPath = pathCache[argD];
    if (cachedPath != null) return cachedPath;
    path ??= Path();
    final d = argD.replaceAllMapped(RegExp('([a-df-zA-Z])'), (match) {
      return "|||${match.group(1)} ";
    }).replaceAll(RegExp(","), " ");
    var currentPointX = 0.0;
    var currentPointY = 0.0;
    double? currentPointX1;
    double? currentPointY1;
    double? currentPointX2;
    double? currentPointY2;
    d.split("|||").forEach((segment) {
      if (segment.isEmpty) {
        return;
      }
      final firstLetter = segment.substring(0, 1);
      if (_validMethods.contains(firstLetter)) {
        final args = segment.substring(1).trim().split(" ");
        if (firstLetter == "M") {
          currentPointX = double.parse(args[0]);
          currentPointY = double.parse(args[1]);
          path!.moveTo(currentPointX, currentPointY);
        } else if (firstLetter == "m") {
          currentPointX += double.parse(args[0]);
          currentPointY += double.parse(args[1]);
          path!.moveTo(currentPointX, currentPointY);
        } else if (firstLetter == "L") {
          currentPointX = double.parse(args[0]);
          currentPointY = double.parse(args[1]);
          path!.lineTo(currentPointX, currentPointY);
        } else if (firstLetter == "l") {
          currentPointX += double.parse(args[0]);
          currentPointY += double.parse(args[1]);
          path!.lineTo(currentPointX, currentPointY);
        } else if (firstLetter == "H") {
          currentPointX = double.parse(args[0]);
          path!.lineTo(currentPointX, currentPointY);
        } else if (firstLetter == "h") {
          currentPointX += double.parse(args[0]);
          path!.lineTo(currentPointX, currentPointY);
        } else if (firstLetter == "V") {
          currentPointY = double.parse(args[0]);
          path!.lineTo(currentPointX, currentPointY);
        } else if (firstLetter == "v") {
          currentPointY += double.parse(args[0]);
          path!.lineTo(currentPointX, currentPointY);
        } else if (firstLetter == "C") {
          currentPointX1 = double.parse(args[0]);
          currentPointY1 = double.parse(args[1]);
          currentPointX2 = double.parse(args[2]);
          currentPointY2 = double.parse(args[3]);
          currentPointX = double.parse(args[4]);
          currentPointY = double.parse(args[5]);
          path!.cubicTo(
            currentPointX1!,
            currentPointY1!,
            currentPointX2!,
            currentPointY2!,
            currentPointX,
            currentPointY,
          );
        } else if (firstLetter == "c") {
          currentPointX1 = currentPointX + double.parse(args[0]);
          currentPointY1 = currentPointY + double.parse(args[1]);
          currentPointX2 = currentPointX + double.parse(args[2]);
          currentPointY2 = currentPointY + double.parse(args[3]);
          currentPointX += double.parse(args[4]);
          currentPointY += double.parse(args[5]);
          path!.cubicTo(
            currentPointX1!,
            currentPointY1!,
            currentPointX2!,
            currentPointY2!,
            currentPointX,
            currentPointY,
          );
        } else if (firstLetter == "S") {
          if (currentPointX1 != null &&
              currentPointY1 != null &&
              currentPointX2 != null &&
              currentPointY2 != null) {
            currentPointX1 = currentPointX - currentPointX2! + currentPointX;
            currentPointY1 = currentPointY - currentPointY2! + currentPointY;
            currentPointX2 = double.parse(args[0]);
            currentPointY2 = double.parse(args[1]);
            currentPointX = double.parse(args[2]);
            currentPointY = double.parse(args[3]);
            path!.cubicTo(
              currentPointX1!,
              currentPointY1!,
              currentPointX2!,
              currentPointY2!,
              currentPointX,
              currentPointY,
            );
          } else {
            currentPointX1 = double.parse(args[0]);
            currentPointY1 = double.parse(args[1]);
            currentPointX = double.parse(args[2]);
            currentPointY = double.parse(args[3]);
            path!.quadraticBezierTo(
                currentPointX1!, currentPointY1!, currentPointX, currentPointY);
          }
        } else if (firstLetter == "s") {
          if (currentPointX1 != null &&
              currentPointY1 != null &&
              currentPointX2 != null &&
              currentPointY2 != null) {
            currentPointX1 = currentPointX - currentPointX2! + currentPointX;
            currentPointY1 = currentPointY - currentPointY2! + currentPointY;
            currentPointX2 = currentPointX + double.parse(args[0]);
            currentPointY2 = currentPointY + double.parse(args[1]);
            currentPointX += double.parse(args[2]);
            currentPointY += double.parse(args[3]);
            path!.cubicTo(
              currentPointX1!,
              currentPointY1!,
              currentPointX2!,
              currentPointY2!,
              currentPointX,
              currentPointY,
            );
          } else {
            currentPointX1 = currentPointX + double.parse(args[0]);
            currentPointY1 = currentPointY + double.parse(args[1]);
            currentPointX += double.parse(args[2]);
            currentPointY += double.parse(args[3]);
            path!.quadraticBezierTo(
              currentPointX1!,
              currentPointY1!,
              currentPointX,
              currentPointY,
            );
          }
        } else if (firstLetter == "Q") {
          currentPointX1 = double.parse(args[0]);
          currentPointY1 = double.parse(args[1]);
          currentPointX = double.parse(args[2]);
          currentPointY = double.parse(args[3]);
          path!.quadraticBezierTo(
              currentPointX1!, currentPointY1!, currentPointX, currentPointY);
        } else if (firstLetter == "q") {
          currentPointX1 = currentPointX + double.parse(args[0]);
          currentPointY1 = currentPointY + double.parse(args[1]);
          currentPointX += double.parse(args[2]);
          currentPointY += double.parse(args[3]);
          path!.quadraticBezierTo(
            currentPointX1!,
            currentPointY1!,
            currentPointX,
            currentPointY,
          );
        } else if (firstLetter == "Z" || firstLetter == "z") {
          path!.close();
        }
      }
      pathCache[argD] = path!;
    });
    return path;
  }

  void drawTextOnBitmap(Canvas canvas, String imageKey, Rect frameRect,
      Map<String, TextPainter> dynamicText) {
    final textPainter = dynamicText[imageKey];
    if (textPainter == null) return;

    textPainter.paint(
      canvas,
      Offset(
        (frameRect.width - textPainter.width) / 2.0,
        (frameRect.height - textPainter.height) / 2.0,
      ),
    );
  }

  @override
  bool shouldRepaint(_SVGAPainter oldDelegate) {
    if (controller._canvasNeedsClear == true) {
      return true;
    }

    return !(oldDelegate.controller == controller &&
        oldDelegate.controller.videoItem == controller.videoItem &&
        oldDelegate.fit == fit &&
        oldDelegate.filterQuality == filterQuality &&
        oldDelegate.clipRect == clipRect);
  }
}
