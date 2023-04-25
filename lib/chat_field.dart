import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hbr_chat_field/constants/style_text_editing_controller.dart';

import 'constants/app_regex.dart';

enum OverlayBuilderType { mention, hashtag }

enum OverlayPosition { bottom, top }

class ChatTextField extends StatefulWidget {
  final Function(String? value)? onChanged;
  final Function()? onEditingComplete;
  final Function()? onTap;
  final StyleTextEditingController textEditingController;
  final FocusNode? focusNode;
  final ThemeMode? themeMode;
  final TextStyle? style;
  final InputDecoration? darkDecoration;
  final InputDecoration? decoration;
  final int maxLines;
  final int minLines;
  final BoxConstraints? overlayConstraints;
  final OverlayPosition overlayPosition;
  final Widget Function(BuildContext context, List<ReplacementInfo> mentions,
      Function(int index) selectItem)? mentionBuilder;
  final Widget Function(BuildContext context, List<ReplacementInfo> hashTags,
      Function(int index) selectItem)? hashtagBuilder;

  const ChatTextField({
    super.key,
    required this.textEditingController,
    this.focusNode,
    this.onChanged,
    this.onEditingComplete,
    this.onTap,
    this.themeMode,
    this.decoration,
    this.maxLines = 5,
    this.minLines = 1,
    this.darkDecoration,
    this.mentionBuilder,
    this.hashtagBuilder,
    this.overlayConstraints,
    this.overlayPosition = OverlayPosition.top,
    this.style,
  });

  @override
  State<ChatTextField> createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends State<ChatTextField>
    with WidgetsBindingObserver {
  OverlayEntry? overlayEntry;
  // late final OverlayPosition _overlayPosition = OverlayPosition(
  //   bottom: MediaQuery.of(context).size.height - _getOffset().dy + 5,
  //   left: 0,
  //   right: 0,
  //   // top: 10,
  // ).copyWith(widget.overlayPosition);

  late final _style = widget.style ??
      (_themeMode == ThemeMode.light
          ? const TextStyle(color: Colors.black)
          : const TextStyle(color: Colors.white));

  late final _themeMode = widget.themeMode ?? ThemeMode.light;

  late final _overlayConstraints =
      BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.25);

  Timer? _debounce;
  OverlayBuilderType? currentType;
  late final FocusNode _focusNode = (widget.focusNode ?? FocusNode())
    ..addListener(() {
      if (!_focusNode.hasFocus) {
        _removeOverlay();
      }
    });

  late final Map<String, Function(String, int, int)> combinedPattern = {
    AppRegex.checkHashTag: _handleHashTaggingAction,
    AppRegex.checkMention: _handleTaggingAction,
  };

  final ValueNotifier<List<ReplacementInfo>> _currentOverlayDisplay =
      ValueNotifier([]);

  final List<String> mentions = [];
  final List<String> hashtag = [];

  Future<bool> get keyboardHidden async {
    if (!(WidgetsBinding.instance.window.viewInsets.bottom <= 0)) return false;
    return await Future.delayed(
      const Duration(milliseconds: 100),
      () => WidgetsBinding.instance.window.viewInsets.bottom <= 0,
    );
  }

  void _onTapItemOverlay(ReplacementInfo replace) {
    widget.textEditingController
        .replaceTag(replace.content, replace.start, replace.end);
  }

  Widget _defaultOverlayBuilder(
    BuildContext context,
    List<ReplacementInfo> value,
  ) {
    return ColoredBox(
      color: Colors.black38,
      child: ListView.builder(
        padding: const EdgeInsets.all(0),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return ListTile(
            onTap: () {
              _onTapItemOverlay(value.elementAt(index));
            },
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(value.elementAt(index).content),
          );
        },
        itemCount: value.length,
      ),
    );
  }

  late final _decoration = widget.decoration ??
      InputDecoration(
        fillColor: Colors.white,
        filled: true,
        hintStyle:
            const TextStyle(fontWeight: FontWeight.w500, color: Colors.black38),
        hintText: "Enter Something",
        contentPadding: const EdgeInsets.all(10),
        border: OutlineInputBorder(
          gapPadding: 0,
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      );

  late final _darkDecoration = widget.darkDecoration ??
      InputDecoration(
        fillColor: Colors.black54,
        filled: true,
        hintStyle:
            const TextStyle(fontWeight: FontWeight.w500, color: Colors.white54),
        hintText: "Enter Something",
        contentPadding: const EdgeInsets.all(10),
        border: OutlineInputBorder(
          gapPadding: 0,
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      );

  Offset _getOffset() {
    RenderBox? box = context.findRenderObject() as RenderBox?;
    Offset? position = box?.localToGlobal(Offset.zero);
    if (position != null) {
      return position;
    }

    return Offset.zero;
  }

  Size _getSize() {
    RenderBox? box = context.findRenderObject() as RenderBox?;
    Size? size = box?.size;
    if (size != null) {
      return size;
    }

    return const Size(0, 0);
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    widget.textEditingController.addListener(_mentionAndHashtagListener);
    super.initState();
  }

  @override
  void didChangeMetrics() {
    keyboardHidden.then((value) {
      if (value) {
        _focusNode.unfocus();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _mentionAndHashtagListener() {
    if (widget.textEditingController.text.isEmpty) {
      _removeOverlay();
    } else {
      // if (_debounce?.isActive ?? false) _debounce?.cancel();
      // _debounce = Timer(const Duration(milliseconds: 50), () {
      // });

      bool isMatched = false;
      String text = widget.textEditingController.text
          .substring(0, widget.textEditingController.selection.end);

      combinedPattern.forEach((pattern, action) {
        List<RegExpMatch> matches =
            RegExp(pattern, caseSensitive: false, multiLine: true)
                .allMatches(text)
                .toList();

        if (matches.isNotEmpty) {
          Match match = matches.last;
          String? textPart = match.group(0);

          if (textPart == null) return;
          isMatched = true;
          textPart += text.substring(match.end);

          action(
            //Delete the space before that matched before the string
            textPart.trimLeft(),
            //Check whether the first character of the matched string is space
            match.start == 0 ? match.start : match.start + 1,
            match.start + textPart.length,
          );
          // }
        }
      });

      if (!isMatched) {
        _removeOverlay();
      }
    }
  }

  Widget _getOverlayBody(OverlayBuilderType type, List<ReplacementInfo> value) {
    return ((widget.mentionBuilder == null &&
                type == OverlayBuilderType.mention) ||
            (widget.hashtagBuilder == null &&
                type == OverlayBuilderType.hashtag))
        ? _defaultOverlayBuilder(context, value)
        : (type == OverlayBuilderType.mention)
            ? widget.mentionBuilder!(
                context,
                value,
                (index) {
                  _onTapItemOverlay(value.elementAt(index));
                },
              )
            : widget.hashtagBuilder!(
                context,
                value,
                (index) {
                  _onTapItemOverlay(value.elementAt(index));
                },
              );
  }

  void _createOverlay(OverlayBuilderType type) {
    _removeOverlay();

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          bottom: widget.overlayPosition == OverlayPosition.top
              ? MediaQuery.of(context).size.height - _getOffset().dy + 5
              : null,
          left: 0,
          right: 0,
          top: widget.overlayPosition == OverlayPosition.bottom
              ? _getOffset().dy + _getSize().height + 5
              : null,
          child: ValueListenableBuilder<List<ReplacementInfo>>(
            valueListenable: _currentOverlayDisplay,
            builder: (context, value, _) => ConstrainedBox(
              constraints: widget.overlayConstraints ?? _overlayConstraints,
              child: Material(child: _getOverlayBody(type, value)),
            ),
          ),
        );
      },
    );

    Overlay.of(context, debugRequiredFor: widget).insert(overlayEntry!);
  }

  void _removeOverlay() {
    _currentOverlayDisplay.value.clear();
    overlayEntry?.remove();
    overlayEntry = null;
  }

  void _handleTaggingAction(String value, int start, int end) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      List<ReplacementInfo> result = [];

      for (var element
          in widget.textEditingController.mentionData ?? [] as List<String>) {
        final matches = value
            .replaceFirst("@", "")
            .toLowerCase()
            .allMatches(element.toLowerCase());

        if (matches.isNotEmpty) {
          if (element.isNotEmpty) {
            result
                .add(ReplacementInfo(content: element, start: start, end: end));
          }
        }
      }

      if (_currentOverlayDisplay.value.isEmpty) {
        _createOverlay(OverlayBuilderType.mention);
      }
      if (result.isEmpty) {
        _removeOverlay();
      }
      _currentOverlayDisplay.value = result;
    });
  }

  void _handleHashTaggingAction(String value, int start, int end) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      List<ReplacementInfo> result = [];

      for (var element
          in widget.textEditingController.hashtagData ?? [] as List<String>) {
        final matches = value
            .replaceFirst("#", "")
            .toLowerCase()
            .allMatches(element.toLowerCase());

        if (matches.isNotEmpty) {
          if (element.isNotEmpty) {
            result
                .add(ReplacementInfo(content: element, start: start, end: end));
          }
        }
      }

      if (_currentOverlayDisplay.value.isEmpty) {
        _createOverlay(OverlayBuilderType.hashtag);
      }
      if (result.isEmpty) {
        _removeOverlay();
      }
      _currentOverlayDisplay.value = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      cursorColor: _style.color ?? Colors.black,
      focusNode: _focusNode,
      controller: widget.textEditingController,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onTap: widget.onTap,
      maxLines: widget.maxLines,
      style: _style,
      minLines: widget.minLines,
      decoration:
          widget.themeMode == ThemeMode.dark ? _darkDecoration : _decoration,
    );
  }
}

class ReplacementInfo {
  final int start;
  final int end;
  final String content;
  const ReplacementInfo({
    required this.content,
    required this.start,
    required this.end,
  });
}
