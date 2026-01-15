import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../design_system/design_system.dart';

/// Tea Text Field with premium styling and validation
class TeaTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final AutovalidateMode? autovalidateMode;

  const TeaTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.focusNode,
    this.autovalidateMode,
  });

  /// Password field with toggle visibility
  factory TeaTextField.password({
    Key? key,
    String? label,
    String? hint,
    TextEditingController? controller,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    FocusNode? focusNode,
    AutovalidateMode? autovalidateMode,
  }) {
    return _TeaPasswordField(
      key: key,
      label: label,
      hint: hint,
      controller: controller,
      validator: validator,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      autovalidateMode: autovalidateMode,
    );
  }

  /// Search field
  factory TeaTextField.search({
    Key? key,
    String? hint,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
    ValueChanged<String>? onSubmitted,
  }) {
    return _TeaSearchField(
      key: key,
      hint: hint ?? 'Search...',
      controller: controller,
      onChanged: onChanged,
      onClear: onClear,
      onSubmitted: onSubmitted,
    );
  }

  /// Multiline text area
  factory TeaTextField.multiline({
    Key? key,
    String? label,
    String? hint,
    TextEditingController? controller,
    String? Function(String?)? validator,
    int maxLines = 4,
    int? minLines,
    int? maxLength,
    ValueChanged<String>? onChanged,
    AutovalidateMode? autovalidateMode,
  }) {
    return TeaTextField(
      key: key,
      label: label,
      hint: hint,
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onChanged: onChanged,
      autovalidateMode: autovalidateMode,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }

  @override
  State<TeaTextField> createState() => _TeaTextFieldState();
}

class _TeaTextFieldState extends State<TeaTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasError = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _validate(String? value) {
    if (widget.validator != null) {
      final error = widget.validator!(value);
      // Schedule state update to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasError = error != null;
            _errorText = error;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TeaTypography.labelLarge.copyWith(
              color: _hasError
                  ? TeaColors.alertRust
                  : _isFocused
                      ? TeaColors.freshLeaf
                      : TeaColors.darkGray,
            ),
          ),
          const SizedBox(height: TeaSpacing.xs),
        ],

        // Input Field
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: TeaRadius.radiusMd,
            boxShadow: _isFocused && !_hasError
                ? [
                    BoxShadow(
                      color: TeaColors.freshLeaf.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            autovalidateMode: widget.autovalidateMode,
            style: TeaTypography.bodyLarge.copyWith(
              color: widget.enabled ? TeaColors.nearBlack : TeaColors.darkGray,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              helperText: widget.helperText,
              errorText: _errorText,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              prefixText: widget.prefixText,
              suffixText: widget.suffixText,
              filled: true,
              fillColor: widget.enabled ? TeaColors.white : TeaColors.lightGray,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: TeaSpacing.md,
                vertical: TeaSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: TeaRadius.radiusMd,
                borderSide: const BorderSide(color: TeaColors.lightGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: TeaRadius.radiusMd,
                borderSide: const BorderSide(color: TeaColors.lightGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: TeaRadius.radiusMd,
                borderSide: const BorderSide(
                  color: TeaColors.freshLeaf,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: TeaRadius.radiusMd,
                borderSide: const BorderSide(color: TeaColors.alertRust),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: TeaRadius.radiusMd,
                borderSide: const BorderSide(
                  color: TeaColors.alertRust,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: TeaRadius.radiusMd,
                borderSide: const BorderSide(color: TeaColors.lightGray),
              ),
              errorStyle: TeaTypography.labelSmall.copyWith(
                color: TeaColors.alertRust,
              ),
              helperStyle: TeaTypography.labelSmall.copyWith(
                color: TeaColors.darkGray,
              ),
              counterStyle: TeaTypography.labelSmall.copyWith(
                color: TeaColors.darkGray,
              ),
            ),
            validator: (value) {
              _validate(value);
              return widget.validator?.call(value);
            },
            onChanged: (value) {
              if (widget.autovalidateMode ==
                  AutovalidateMode.onUserInteraction) {
                _validate(value);
              }
              widget.onChanged?.call(value);
            },
            onTap: widget.onTap,
            onFieldSubmitted: widget.onSubmitted,
          ),
        ),
      ],
    );
  }
}

/// Password field with visibility toggle
class _TeaPasswordField extends TeaTextField {
  const _TeaPasswordField({
    super.key,
    super.label,
    super.hint,
    super.controller,
    super.validator,
    super.textInputAction,
    super.onChanged,
    super.onSubmitted,
    super.focusNode,
    super.autovalidateMode,
  });

  @override
  State<TeaTextField> createState() => _TeaPasswordFieldState();
}

class _TeaPasswordFieldState extends _TeaTextFieldState {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TeaTypography.labelLarge.copyWith(
              color: _hasError
                  ? TeaColors.alertRust
                  : _isFocused
                      ? TeaColors.freshLeaf
                      : TeaColors.darkGray,
            ),
          ),
          const SizedBox(height: TeaSpacing.xs),
        ],

        // Input Field
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: TeaRadius.radiusMd,
            boxShadow: _isFocused && !_hasError
                ? [
                    BoxShadow(
                      color: TeaColors.freshLeaf.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: widget.textInputAction,
            obscureText: _obscureText,
            autovalidateMode: widget.autovalidateMode,
            style: TeaTypography.bodyLarge,
            decoration: InputDecoration(
              hintText: widget.hint ?? 'Enter password',
              errorText: _errorText,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    key: ValueKey(_obscureText),
                  ),
                ),
                onPressed: _toggleVisibility,
              ),
              filled: true,
              fillColor: TeaColors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: TeaSpacing.md,
                vertical: TeaSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: TeaRadius.radiusMd,
                borderSide: const BorderSide(color: TeaColors.lightGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: TeaRadius.radiusMd,
                borderSide: const BorderSide(color: TeaColors.lightGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: TeaRadius.radiusMd,
                borderSide: const BorderSide(
                  color: TeaColors.freshLeaf,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: TeaRadius.radiusMd,
                borderSide: const BorderSide(color: TeaColors.alertRust),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: TeaRadius.radiusMd,
                borderSide: const BorderSide(
                  color: TeaColors.alertRust,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              _validate(value);
              return widget.validator?.call(value);
            },
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
          ),
        ),
      ],
    );
  }
}

/// Search field
class _TeaSearchField extends TeaTextField {
  final VoidCallback? onClear;

  const _TeaSearchField({
    super.key,
    super.hint,
    super.controller,
    super.onChanged,
    super.onSubmitted,
    this.onClear,
  });

  @override
  State<TeaTextField> createState() => _TeaSearchFieldState();
}

class _TeaSearchFieldState extends _TeaTextFieldState {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController =
        widget.controller ?? TextEditingController();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _textController.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _clearText() {
    _textController.clear();
    (widget as _TeaSearchField).onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TeaColors.white,
        borderRadius: TeaRadius.radiusRound,
        boxShadow: TeaShadows.cardShadow,
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        style: TeaTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(
            Icons.search,
            color: TeaColors.darkGray,
          ),
          suffixIcon: _textController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  color: TeaColors.darkGray,
                  onPressed: _clearText,
                ).animate().fadeIn(duration: 150.ms)
              : null,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: TeaSpacing.md,
            vertical: TeaSpacing.sm,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintStyle: TeaTypography.bodyMedium.copyWith(
            color: TeaColors.mediumGray,
          ),
        ),
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        textInputAction: TextInputAction.search,
      ),
    );
  }
}
