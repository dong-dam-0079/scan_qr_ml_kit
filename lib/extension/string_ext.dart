extension TextProcessing on String {
  String separateNumbersAndLetters() {
    return replaceAllMapped(
            RegExp(r'(\d)([A-Za-z])'), (match) => '${match[1]} ${match[2]}')
        .replaceAllMapped(
            RegExp(r'([A-Za-z])(\d)'), (match) => '${match[1]} ${match[2]}');
  }

  String splitStickyText() {
    return replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (match) => ' ');
  }

  bool isAddress() {
    RegExp hasLetterAndNumber = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$');
    if (hasLetterAndNumber.hasMatch(this)) {
      return true;
    }
    return false;
  }

  bool isName() {
    RegExp onlyLetters = RegExp(r'^[A-Za-z\s]+$');
    if (onlyLetters.hasMatch(this)) {
      return true;
    }
    return false;
  }
}
