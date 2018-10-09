final RegExp _interfacePattern = new RegExp(
    r'(?:\/\*\*([\S\s]+?)\*\/)?\s*(?:export\s+)?interface\s+(\w+)(?:\s+extends\s+([\w, ]+?))?\s*\{\s*([^\}]*)\s*\}',
    multiLine: true);
final RegExp _namespacePattern = new RegExp(
    r'(?:\/\*\*([\S\s]+?)\*\/)?\s*(?:export\s+)?namespace\s+(\w+)\s*\{\s*([^\}]*)\s*\}',
    multiLine: true);
final RegExp _fieldPattern = new RegExp(
    r'(?:\/\*\*([^\/]+?)\*\/)?\s*(\w+\??)\s*:\s*([\w\[\]\s|]+)\s*;',
    multiLine: true);
final RegExp _constPattern = new RegExp(
    r'(?:\/\*\*([^\/]+?)\*\/)?\s*(?:export\s+)?const\s+(\w+)\s*=\s*([\w\[\]]+)\s*;',
    multiLine: true);
final RegExp _typeAliasPattern = new RegExp(
    r'(?:\/\*\*([\S\s]+?)\*\/)?\s*type\s+([\w]+)\s+=\s+([\w\[\]]+)\s*;',
    multiLine: true);

List<Type> parseSpec(String code) {
  return Type.extractFrom(code);
}

List<String> _parseTypes(String baseTypes, String sep) {
  return baseTypes?.split(sep)?.map((t) => t.trim())?.toList() ?? [];
}

final _commentLinePrefixes = new RegExp(r'$[\s*]*');
String _cleanComment(String comment) {
  return comment?.replaceAll(_commentLinePrefixes, '');
}

abstract class Type {
  final String name, comment;
  Type(this.name, comment) : this.comment = _cleanComment(comment);

  static List<Type> extractFrom(String code) {
    List<Type> types = [];
    types.addAll(Interface.extractFrom(code));
    types.addAll(Namespace.extractFrom(code));
    types.addAll(TypeAlias.extractFrom(code));
    return types;
  }
}

abstract class Member {
  static List<Member> extractFrom(String code) {
    List<Member> members = [];
    members.addAll(Field.extractFrom(code));
    members.addAll(Const.extractFrom(code));
    return members;
  }
}

class TypeAlias extends Type {
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

class Interface extends Type {
  final List<String> baseTypes;
  final List<Member> fields;
  Interface(String name, String comment, this.baseTypes, this.fields)
      : super(name, comment);

  @override
  String toString() {
    return 'type $name' +
        (baseTypes.isNotEmpty ? ' (extends ${baseTypes.join(', ')})' : '') +
        fields.map((f) => '\n    ' + f.toString()).join('');
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

class Namespace extends Type {
  final List<Member> members;
  Namespace(String name, String comment, this.members) : super(name, comment);

  @override
  String toString() {
    return 'namespace $name ' +
        members.map((f) => '\n    ' + f.toString()).join('');
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
  final String comment, name;
  final List<String> types;
  Field(this.comment, this.name, this.types);
  @override
  String toString() {
    return '$name (${types?.join(', ')})';
  }

  static List<Field> extractFrom(String code) {
    return _fieldPattern.allMatches(code).map((m) {
      final String comment = m.group(1);
      String name = m.group(2);
      final List<String> types = _parseTypes(m.group(3), '|');
      if (name.endsWith('?')) {
        name = name.substring(0, name.length - 1);
        types.add('undefined');
      }
      return new Field(comment, name, types);
    }).toList();
  }
}

class Const extends Member {
  final String comment, name, value;
  Const(this.comment, this.name, this.value);
  @override
  String toString() {
    return 'const $name = $value';
  }

  static List<Const> extractFrom(String code) {
    return _constPattern.allMatches(code).map((m) {
      final String comment = m.group(1);
      final String name = m.group(2);
      final String value = m.group(3);
      return new Const(comment, name, value);
    }).toList();
  }
}
