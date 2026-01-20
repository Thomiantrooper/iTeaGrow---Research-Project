import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../design_system/design_system.dart';
import '../feedback/tea_feedback.dart';

/// 3D Model Viewer for Tea Plantation assets
/// Wraps model_viewer_plus with Tea-themed styling
class Tea3DViewer extends StatefulWidget {
  /// Path to GLB/GLTF model file
  final String modelPath;

  /// Auto-rotate the model
  final bool autoRotate;

  /// Rotation speed (degrees per second)
  final double rotationSpeed;

  /// Allow user to zoom
  final bool enableZoom;

  /// Allow user to pan
  final bool enablePan;

  /// Background color (null for transparent)
  final Color? backgroundColor;

  /// Placeholder widget while loading
  final Widget? placeholder;

  /// Custom loading widget
  final Widget? loadingWidget;

  /// Camera orbit (theta, phi, radius)
  final String? cameraOrbit;

  /// Field of view
  final String? fieldOfView;

  /// Min/max camera orbit
  final String? minCameraOrbit;
  final String? maxCameraOrbit;

  /// Exposure value
  final double? exposure;

  /// Shadow intensity
  final double? shadowIntensity;

  /// Shadow softness
  final double? shadowSoftness;

  /// Environment image for lighting
  final String? environmentImage;

  /// Callback when model is loaded
  final VoidCallback? onModelLoaded;

  /// Callback on error
  final Function(String)? onError;

  const Tea3DViewer({
    super.key,
    required this.modelPath,
    this.autoRotate = true,
    this.rotationSpeed = 30,
    this.enableZoom = true,
    this.enablePan = false,
    this.backgroundColor,
    this.placeholder,
    this.loadingWidget,
    this.cameraOrbit,
    this.fieldOfView,
    this.minCameraOrbit,
    this.maxCameraOrbit,
    this.exposure,
    this.shadowIntensity,
    this.shadowSoftness,
    this.environmentImage,
    this.onModelLoaded,
    this.onError,
  });

  /// Create a viewer for tea leaf models
  factory Tea3DViewer.leaf({
    Key? key,
    required String modelPath,
    bool autoRotate = true,
    VoidCallback? onModelLoaded,
  }) {
    return Tea3DViewer(
      key: key,
      modelPath: modelPath,
      autoRotate: autoRotate,
      cameraOrbit: '0deg 75deg 2m',
      fieldOfView: '30deg',
      shadowIntensity: 0.5,
      shadowSoftness: 1,
      exposure: 1.2,
      onModelLoaded: onModelLoaded,
    );
  }

  /// Create a viewer for tea bush models
  factory Tea3DViewer.bush({
    Key? key,
    required String modelPath,
    bool autoRotate = true,
    VoidCallback? onModelLoaded,
  }) {
    return Tea3DViewer(
      key: key,
      modelPath: modelPath,
      autoRotate: autoRotate,
      rotationSpeed: 15,
      cameraOrbit: '45deg 55deg 4m',
      fieldOfView: '45deg',
      shadowIntensity: 0.7,
      shadowSoftness: 1,
      exposure: 1.0,
      enableZoom: true,
      enablePan: true,
      onModelLoaded: onModelLoaded,
    );
  }

  /// Create a viewer for container/batch models
  factory Tea3DViewer.container({
    Key? key,
    required String modelPath,
    bool autoRotate = false,
    VoidCallback? onModelLoaded,
  }) {
    return Tea3DViewer(
      key: key,
      modelPath: modelPath,
      autoRotate: autoRotate,
      cameraOrbit: '30deg 70deg 2.5m',
      fieldOfView: '35deg',
      shadowIntensity: 0.6,
      shadowSoftness: 0.8,
      exposure: 1.1,
      enableZoom: true,
      onModelLoaded: onModelLoaded,
    );
  }

  @override
  State<Tea3DViewer> createState() => _Tea3DViewerState();
}

class _Tea3DViewerState extends State<Tea3DViewer> {
  bool _isLoaded = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorState();
    }

    return Stack(
      children: [
        // 3D Model Viewer
        ModelViewer(
          src: widget.modelPath,
          alt: 'Tea 3D Model',
          autoRotate: widget.autoRotate,
          autoRotateDelay: 0,
          rotationPerSecond: '${widget.rotationSpeed}deg',
          cameraControls: true,
          disableZoom: !widget.enableZoom,
          disablePan: !widget.enablePan,
          backgroundColor: widget.backgroundColor ?? Colors.transparent,
          loading: Loading.eager,
          reveal: Reveal.auto,
          cameraOrbit: widget.cameraOrbit,
          fieldOfView: widget.fieldOfView,
          minCameraOrbit: widget.minCameraOrbit,
          maxCameraOrbit: widget.maxCameraOrbit,
          exposure: widget.exposure,
          shadowIntensity: widget.shadowIntensity,
          shadowSoftness: widget.shadowSoftness,
          environmentImage: widget.environmentImage,
          onWebViewCreated: (controller) {
            // Model viewer created
          },
          relatedJs: '''
            const modelViewer = document.querySelector('model-viewer');
            modelViewer.addEventListener('load', () => {
              window.flutter_inappwebview.callHandler('onLoad');
            });
            modelViewer.addEventListener('error', (event) => {
              window.flutter_inappwebview.callHandler('onError', event.detail);
            });
          ''',
        ),

        // Loading overlay
        if (!_isLoaded)
          Positioned.fill(
            child: widget.loadingWidget ?? _buildLoadingState(),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? TeaColors.mistGreen,
        borderRadius: TeaRadius.radiusLg,
      ),
      child: Center(
        child: widget.placeholder ??
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TeaLoading.leaf(size: 48),
                const SizedBox(height: TeaSpacing.md),
                Text(
                  'Loading 3D model...',
                  style: TeaTypography.labelMedium,
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        color: TeaColors.alertRust.withOpacity(0.1),
        borderRadius: TeaRadius.radiusLg,
        border: Border.all(
          color: TeaColors.alertRust.withOpacity(0.3),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: TeaColors.alertRust,
            ),
            const SizedBox(height: TeaSpacing.md),
            Text(
              'Failed to load 3D model',
              style: TeaTypography.titleSmall.copyWith(
                color: TeaColors.alertRust,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: TeaSpacing.xs),
              Text(
                _errorMessage!,
                style: TeaTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onModelLoaded() {
    if (mounted) {
      setState(() => _isLoaded = true);
      widget.onModelLoaded?.call();
    }
  }

  void _onError(String error) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = error;
      });
      widget.onError?.call(error);
    }
  }
}

/// 3D Model Carousel for displaying multiple models
class Tea3DCarousel extends StatefulWidget {
  final List<Tea3DModelItem> items;
  final double height;
  final ValueChanged<int>? onIndexChanged;
  final int initialIndex;

  const Tea3DCarousel({
    super.key,
    required this.items,
    this.height = 250,
    this.onIndexChanged,
    this.initialIndex = 0,
  });

  @override
  State<Tea3DCarousel> createState() => _Tea3DCarouselState();
}

class _Tea3DCarouselState extends State<Tea3DCarousel> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.85,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              widget.onIndexChanged?.call(index);
            },
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final isActive = index == _currentIndex;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(
                  horizontal: TeaSpacing.sm,
                  vertical: isActive ? 0 : TeaSpacing.md,
                ),
                decoration: BoxDecoration(
                  borderRadius: TeaRadius.radiusLg,
                  boxShadow: isActive ? TeaShadows.cardShadowMedium : TeaShadows.cardShadow,
                ),
                child: ClipRRect(
                  borderRadius: TeaRadius.radiusLg,
                  child: Stack(
                    children: [
                      Tea3DViewer(
                        modelPath: item.modelPath,
                        autoRotate: item.autoRotate,
                        backgroundColor: item.backgroundColor,
                      ),
                      if (item.label != null)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: TeaSpacing.cardPaddingSm,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: Text(
                              item.label!,
                              style: TeaTypography.titleSmall.copyWith(
                                color: TeaColors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: TeaSpacing.md),
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.items.length, (index) {
            final isActive = index == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? TeaColors.freshLeaf : TeaColors.lightGray,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Model item for carousel
class Tea3DModelItem {
  final String modelPath;
  final String? label;
  final bool autoRotate;
  final Color? backgroundColor;

  const Tea3DModelItem({
    required this.modelPath,
    this.label,
    this.autoRotate = true,
    this.backgroundColor,
  });
}

/// Placeholder for 3D model (when model is not available)
class Tea3DPlaceholder extends StatelessWidget {
  final String? label;
  final IconData icon;
  final double size;

  const Tea3DPlaceholder({
    super.key,
    this.label,
    this.icon = Icons.view_in_ar,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: TeaColors.leafPale,
        borderRadius: TeaRadius.radiusLg,
        border: Border.all(
          color: TeaColors.freshLeaf.withOpacity(0.3),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: size * 0.3,
            color: TeaColors.freshLeaf.withOpacity(0.5),
          ),
          if (label != null) ...[
            const SizedBox(height: TeaSpacing.sm),
            Text(
              label!,
              style: TeaTypography.labelMedium.copyWith(
                color: TeaColors.freshLeaf,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
