import 'package:dart_markdown/dart_markdown.dart';
import 'package:flutter/material.dart';

import '../constants/app_regex.dart';
import '../extensions/hashtag.dart';
import '../extensions/mention.dart';

class MarkdownUtils {
  static final MarkdownUtils instance = MarkdownUtils._();

  MarkdownUtils._();

  factory MarkdownUtils() => instance;

  // void initMentionAndHashtagPattern(
  //   List<String>? mentionPattern,
  //   List<String>? hashtagPattern,
  // ) {
  //   _hashtagPattern = hashtagPattern?.join("|") ?? "";
  //   _mentionPattern = mentionPattern?.join("|") ?? "";
  // }

  late final List<Syntax> extensions = [];

  late Markdown markdown = Markdown(
    enableCodeSpan: true,
    enableFencedCodeBlock: true,
    enableParagraph: true,
    enableAutolinkExtension: true,
    enableEmphasis: true,

    enableAtxHeading: false,
    enableBlankLine: false,
    enableBlockquote: false,
    enableIndentedCodeBlock: false,
    enableFencedBlockquote: false,
    enableList: false,
    enableSetextHeading: false,
    enableTable: false,
    enableHtmlBlock: false,
    enableLinkReferenceDefinition: false,
    enableThematicBreak: false,
    enableAutolink: false,
    enableBackslashEscape: false,
    enableEmoji: false,
    enableHardLineBreak: false,
    enableImage: false,
    enableLink: false,
    enableRawHtml: false,
    enableStrikethrough: false,
    enableSoftLineBreak: false,

    // The options with default value `false`.
    enableHeadingId: false,
    enableHighlight: false,
    enableFootnote: false,
    enableTaskList: false,
    enableSubscript: false,
    enableSuperscript: false,
    enableKbd: false,
    forceTightList: false,
    extensions: extensions,
  );

  void _initMarkdownWithNewExtension(
      List<String> mentionData, List<String> hashtagData) {
    markdown = Markdown(
      enableCodeSpan: true,
      enableFencedCodeBlock: true,
      enableParagraph: true,
      enableAutolinkExtension: true,
      enableEmphasis: true,

      enableAtxHeading: false,
      enableBlankLine: false,
      enableBlockquote: false,
      enableIndentedCodeBlock: false,
      enableFencedBlockquote: false,
      enableList: false,
      enableSetextHeading: false,
      enableTable: false,
      enableHtmlBlock: false,
      enableLinkReferenceDefinition: false,
      enableThematicBreak: false,
      enableAutolink: false,
      enableBackslashEscape: false,
      enableEmoji: false,
      enableHardLineBreak: false,
      enableImage: false,
      enableLink: false,
      enableRawHtml: false,
      enableStrikethrough: false,
      enableSoftLineBreak: false,

      // The options with default value `false`.
      enableHeadingId: false,
      enableHighlight: false,
      enableFootnote: false,
      enableTaskList: false,
      enableSubscript: false,
      enableSuperscript: false,
      enableKbd: false,
      forceTightList: false,
      extensions: [
        HashtagSyntax(hashtagPattern: hashtagData.join("|")),
        MentionSyntax(pattern: mentionData.join("|")),
        ...extensions,
      ],
    );
  }

  void addExtension(InlineSyntax inlineSyntax) {
    extensions.add(inlineSyntax);
  }

  MarkdownTextParser parseText(
    String text, {
    bool isRaw = true,
    List<String>? mentionsData,
    List<String>? hashtagData,
  }) {
    if ((mentionsData?.isNotEmpty ?? false) ||
        (hashtagData?.isNotEmpty ?? false)) {
      _initMarkdownWithNewExtension(mentionsData!, hashtagData!);
    }

    final Set<String> mentions = {};
    final Set<String> hashtag = {};
    String prefixSpace = "";
    String suffixSpace = "";
    //extract space from the raw text if have
    RegExp(AppRegex.checkSpaceLeading).allMatches(text).forEach((element) {
      prefixSpace += element.group(0) ?? "";
    });
    text = text.replaceAll(RegExp(AppRegex.checkSpaceLeading), "");

    RegExp(AppRegex.checkSpaceTrailing).allMatches(text).forEach((element) {
      suffixSpace += element.group(0) ?? "";
    });
    text = text.replaceAll(RegExp(AppRegex.checkSpaceTrailing), "");

    List<InlineSpan> result = [];
    List<Node> nodes = markdown.parse(text);
    for (int index = 0; index < nodes.length; index++) {
      final map = nodes[index].toMap();
      InlineSpan inlineSpan = _extractTextSpan(
        map,
        mentions,
        hashtag,
        isRaw: isRaw,
      );

      //if there are more than one block we have to manually
      //add the line break to the list inline span
      if (index != 0) {
        result.add(const TextSpan(text: "\n"));
      }

      result.add(inlineSpan);
    }

    //Add space to the start and the end of the result if need
    result.insert(0, TextSpan(text: prefixSpace));
    result.insert(result.length, TextSpan(text: suffixSpace));
    return MarkdownTextParser(
      textSpans: result,
      mentions: mentions.toList(),
      hashtag: hashtag.toList(),
    );
  }

  InlineSpan _extractTextSpan(
      Map<String, dynamic> sourceData, Set<String> mention, Set<String> hashtag,
      {TextStyle? parentStyle, bool isRaw = true}) {
    if (sourceData.containsKey("type")) {
      List<InlineSpan> children = [];
      TextStyle? style = MarkdownTextSpanAdapter.getTextStyle(
        parentStyle,
        sourceData["type"],
      );

      for (var element
          in (sourceData["children"] as List<Map<String, dynamic>>?) ?? []) {
        children.add(
          _extractTextSpan(
            element,
            mention,
            hashtag,
            parentStyle: style,
            isRaw: isRaw,
          ),
        );
      }
      // mention
      if (isRaw ||
          sourceData["type"] == "mention" ||
          sourceData["type"] == "hashtag") {
        if (sourceData["type"] == "mention") {
          mention.add(children.map((e) => e.toPlainText()).join());
        }
        if (sourceData["type"] == "hashtag") {
          hashtag.add(children.map((e) => e.toPlainText()).join());
        }

        List<Map<String, dynamic>> markers = sourceData["markers"] ?? [];
        int countPrefix = 0;
        for (var marker in markers) {
          if (marker["start"]!["offset"] == sourceData["start"]!["offset"]) {
            children.insert(
                countPrefix++, TextSpan(text: marker["text"], style: style));
          } else {
            children.insert(
                children.length, TextSpan(text: marker["text"], style: style));
          }
        }

        if (sourceData["type"] == MarkdownType.fencedCodeBlock.name) {
          if (sourceData["children"] != null) {
            children.insert(countPrefix, const TextSpan(text: "\n"));
          } else {
            if (markers.length >= 2) {
              children.insert(children.length - 1, const TextSpan(text: "\n"));
            }
          }
        }
      }
      return TextSpan(children: children, style: parentStyle);
    }

    return TextSpan(text: sourceData["text"] ?? "", style: parentStyle);
  }
}

class MarkdownTextParser {
  final List<String> mentions;
  final List<String> hashtag;
  final List<InlineSpan> textSpans;

  MarkdownTextParser({
    required this.mentions,
    required this.hashtag,
    required this.textSpans,
  });
}

enum MarkdownType {
  strongEmphasis,
  emphasis,
  fencedCodeBlock,
  autolinkExtension,
  mention,
  hashtag,
  codeSpan
}

class MarkdownTextSpanAdapter {
  static final Map<String, TextStyle> textStyleMap = {
    MarkdownType.strongEmphasis.name:
        const TextStyle(fontWeight: FontWeight.bold),
    MarkdownType.emphasis.name: const TextStyle(fontStyle: FontStyle.italic),
    MarkdownType.fencedCodeBlock.name: const TextStyle(
      color: Colors.white,
      fontFamily: 'FiraCode',
      fontSize: 14,
      fontStyle: FontStyle.italic,
    ),
    MarkdownType.autolinkExtension.name: const TextStyle(
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      color: Colors.blue,
    ),
    MarkdownType.mention.name: const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.blue,
    ),
    MarkdownType.hashtag.name: const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.blue,
    ),
    MarkdownType.codeSpan.name: const TextStyle(
      fontFamily: 'FiraCode',
      fontSize: 14,
      fontStyle: FontStyle.italic,
    ),
  };
  static TextStyle? getTextStyle(TextStyle? style, String? type) {
    return textStyleMap[type]?.merge(style);
  }
}
