const String typeScriptCommentRegex =
    r'(?:\/\*\*((?:[\S\s](?!\*\/))+?)\s\*\/)?\s*';
const String typeScriptBlockBodyRegex = r'\s*([\s\S]*?)\s*\n\s*';
final RegExp _interfacePattern = new RegExp(
    typeScriptCommentRegex +
        r'(?:export\s+)?interface\s+(\w+)(?:\s+extends\s+([\w, ]+?))?\s*\{' +
        typeScriptBlockBodyRegex +
        '\}',
    multiLine: true);
final RegExp _namespacePattern = new RegExp(
    typeScriptCommentRegex +
        r'(?:export\s+)?namespace\s+(\w+)\s*\{' +
        typeScriptBlockBodyRegex +
        '\}',
    multiLine: true);
final RegExp _fieldPattern = new RegExp(
    typeScriptCommentRegex + r'(\w+\??)\s*:\s*([\w\[\]\s|]+)\s*;',
    multiLine: true);
final RegExp _constPattern = new RegExp(
    typeScriptCommentRegex +
        r'(?:export\s+)?const\s+(\w+)\s*=\s*([\w\[\]]+)\s*;',
    multiLine: true);
final RegExp _typeAliasPattern = new RegExp(
    typeScriptCommentRegex + r'type\s+([\w]+)\s+=\s+([\w\[\]]+)\s*;',
    multiLine: true);

List<ApiItem> parseSpec(String code) {
  return ApiItem.extractFrom(code);
}

List<String> _parseTypes(String baseTypes, String sep) {
  return baseTypes?.split(sep)?.map((t) => t.trim())?.toList() ?? [];
}

final _commentLinePrefixes = new RegExp(r'$[\s*]*', multiLine: true);
String _cleanComment(String comment) {
  return comment?.replaceAll(_commentLinePrefixes, '');
}

abstract class ApiItem {
  String name, comment;
  ApiItem(this.name, String comment) : comment = _cleanComment(comment);

  static List<ApiItem> extractFrom(String code) {
    List<ApiItem> types = [];
    types.addAll(Interface.extractFrom(code));
    types.addAll(Namespace.extractFrom(code));
    types.addAll(TypeAlias.extractFrom(code));
    return types;
  }
}

abstract class Member extends ApiItem {
  Member(String name, String comment) : super(name, comment);

  static List<Member> extractFrom(String code) {
    List<Member> members = [];
    members.addAll(Field.extractFrom(code));
    members.addAll(Const.extractFrom(code));
    return members;
  }
}

class TypeAlias extends ApiItem {
  final List<String> baseTypes;
  TypeAlias(name, comment, this.baseTypes) : super(name, comment);

  @override
  String toString() {
    return 'alias $name => $baseTypes';
  }

  static List<TypeAlias> extractFrom(String code) {
    return _typeAliasPattern.allMatches(code).map((match) {
      final String comment = match.group(1);
      final String name = match.group(2);
      final List<String> baseTypes = _parseTypes(match.group(3), ',');
      return new TypeAlias(name, comment, baseTypes);
    }).toList();
  }
}

class Interface extends ApiItem {
  final List<String> baseTypes;
  final List<Member> members;
  Interface(String name, String comment, this.baseTypes, this.members)
      : super(name, comment);

  @override
  String toString() {
    return 'type $name' +
        (baseTypes.isNotEmpty ? ' (extends ${baseTypes.join(', ')})' : '') +
        members.map((f) => '\n    ' + f.toString()).join();
  }

  static List<Interface> extractFrom(String code) {
    return _interfacePattern.allMatches(code).map((match) {
      final String comment = match.group(1);
      final String name = match.group(2);
      final List<String> baseTypes = _parseTypes(match.group(3), ',');
      final String body = match.group(4);
      final List<Member> members = Member.extractFrom(body);
      return new Interface(name, comment, baseTypes, members);
    }).toList();
  }
}

class Namespace extends ApiItem {
  final List<Member> members;
  Namespace(String name, String comment, this.members) : super(name, comment);

  @override
  String toString() {
    return 'namespace $name ' +
        members.map((f) => '\n    ' + f.toString()).join();
  }

  static List<Namespace> extractFrom(String code) {
    return _namespacePattern.allMatches(code).map((match) {
      final String comment = match.group(1);
      final String name = match.group(2);
      final String body = match.group(3);
      final List<Member> members = Member.extractFrom(body);
      return new Namespace(name, comment, members);
    }).toList();
  }
}

class Field extends Member {
  final List<String> types;
  final bool allowsNull, allowsUndefined;
  Field(String name, String comment, this.types, this.allowsNull,
      this.allowsUndefined)
      : super(name, comment);
  @override
  String toString() {
    return '$name (${types?.join(' | ')}${allowsNull ? ' | null' : ''}${allowsUndefined ? ' | undefined' : ''})';
  }

  static List<Field> extractFrom(String code) {
    return _fieldPattern.allMatches(code).map((m) {
      final String comment = m.group(1);
      String name = m.group(2);
      final List<String> types = _parseTypes(m.group(3), '|');
      final bool allowsNull = types.contains('null');
      if (allowsNull) {
        types.remove('null');
      }
      final bool allowsUndefined = name.endsWith('?');
      if (allowsUndefined) {
        name = name.substring(0, name.length - 1);
      }
      return new Field(name, comment, types, allowsNull, allowsUndefined);
    }).toList();
  }
}

class Const extends Member {
  final value;
  Const(String name, String comment, this.value) : super(name, comment);
  @override
  String toString() {
    return 'const $name = $value';
  }

  static List<Const> extractFrom(String code) {
    return _constPattern.allMatches(code).map((m) {
      final String comment = m.group(1);
      final String name = m.group(2);
      final String value = m.group(3);
      return new Const(name, comment, value);
    }).toList();
  }
}
