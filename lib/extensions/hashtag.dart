
import 'package:dart_markdown/dart_markdown.dart';

class HashtagSyntax extends InlineSyntax {
  final String? hashtagPattern;
  HashtagSyntax({this.hashtagPattern})
      : super(RegExp(
          hashtagPattern ?? "",
          multiLine: false,
          caseSensitive: false,
        ));

  @override
  InlineObject? parse(InlineParser parser, Match match) {
    final markers = [parser.consume()];
    final content = parser.consumeBy(match[0]!.length - 1);

    return InlineElement(
      'hashtag',
      markers: markers,
      children: content.map((e) => Text.fromSpan(e)).toList(),
      start: markers.first.start,
      end: content.last.end,
    );
  }
}
