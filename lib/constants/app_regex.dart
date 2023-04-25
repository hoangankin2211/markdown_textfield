class AppRegex {
  static const String checkMention = "(?:^|\\s)(@(?!\\@)(?:\\S|\$)+)";
  static const String checkHashTag = "(#[^#]*)";
  static const String checkSpaceLeading = "^\\s+";
  static const String checkSpaceTrailing = "\\s+\$";
}
