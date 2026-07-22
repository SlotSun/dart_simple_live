import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';

class NetImage extends StatelessWidget {
  final String picUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final double borderRadius;

  const NetImage(
    this.picUrl, {
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    if (picUrl.isEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          'assets/images/logo.png',
          width: width,
          height: height,
        ),
      );
    }

    var pic = picUrl;
    if (pic.startsWith('//')) {
      pic = 'https:$pic';
    }

    return ClipRRect(
      borderRadius: radius,
      child: ExtendedImage.network(
        pic,
        fit: fit,
        height: height,
        width: width,
        shape: BoxShape.rectangle,
        borderRadius: radius,
        loadStateChanged: (state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              return _ImageState(
                width: width,
                height: height,
                icon: Icons.image_outlined,
                semanticLabel: '图片加载中',
              );
            case LoadState.failed:
              return _ImageState(
                width: width,
                height: height,
                icon: Icons.broken_image_outlined,
                semanticLabel: '图片加载失败',
              );
            case LoadState.completed:
              return null;
          }
        },
      ),
    );
  }
}

class _ImageState extends StatelessWidget {
  const _ImageState({
    required this.width,
    required this.height,
    required this.icon,
    required this.semanticLabel,
  });

  final double? width;
  final double? height;
  final IconData icon;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final semantic = context.appTheme;
    return Container(
      width: width,
      height: height,
      color: semantic.secondarySurface,
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: semantic.textTertiary,
        size: 24,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
