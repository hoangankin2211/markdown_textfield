import 'package:flutter/material.dart';
import 'package:hbr_chat_field/utils/markdown_utils.dart';

class StyleTextEditingController extends TextEditingController {
  final List<String> _mentions = [];
  final List<String> _hashtag = [];
  final List<String>? mentionData;
  final List<String>? hashtagData;

  StyleTextEditingController({
    this.mentionData,
    this.hashtagData,
  });

  void replaceTag(String content, int start, int end) {
    String newText = "${text.replaceRange(start, end, content)} ";

    value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  List<String> getMentions() {
    return _mentions.toList();
  }

  List<String> getHashtag() {
    return _hashtag.toList();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    MarkdownTextParser textSpan = MarkdownUtils.instance.parseText(
      text,
      mentionsData: mentionData,
      hashtagData: hashtagData,
    );
    (_mentions..clear()).addAll(textSpan.mentions);
    (_hashtag..clear()).addAll(textSpan.hashtag);
    return TextSpan(children: textSpan.textSpans, style: style);
  }
}
