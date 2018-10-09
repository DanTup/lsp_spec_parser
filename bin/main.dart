import 'dart:async';
import 'package:http/http.dart' as http;

final Uri specUri = Uri.parse(
    'https://raw.githubusercontent.com/Microsoft/language-server-protocol/gh-pages/specification.md');

main() async {
  final String spec = await fetchSpec();
  final List<String> typescriptBlocks = extractTypeScriptBlocks(spec);
  List<Type> types =
      typescriptBlocks.map(parseTypeScriptInterface).expand((l) => l).toList();
  types.forEach(print);
}

Future<String> fetchSpec() async {
  final resp = await http.get(specUri);
  return resp.body;
}

List<String> extractTypeScriptBlocks(String text) {
  var typeScriptBlock =
      new RegExp(r'\n```typescript([\S\s]*?)\n```', multiLine: true);
  return typeScriptBlock
      .allMatches(text)
      .map((m) => m.group(1).trim())
      .toList();
}

final RegExp interfacePattern = new RegExp(
    r'(?:\/\*\*([\S\s]+?)\*\/)?\s*(?:export\s+)?interface\s+(\w+)(?:\s+extends\s+([\w, ]+?))?\s*\{\s*([^\}]*)\s*\}',
    multiLine: true);
final RegExp namespacePattern = new RegExp(
    r'(?:\/\*\*([\S\s]+?)\*\/)?\s*(?:export\s+)?namespace\s+(\w+)\s*\{\s*([^\}]*)\s*\}',
    multiLine: true);
final RegExp fieldPattern = new RegExp(
    r'(?:\/\*\*([^\/]+?)\*\/)?\s*(\w+\??)\s*:\s*([\w\[\]\s|]+)\s*;',
    multiLine: true);
final RegExp constPattern = new RegExp(
    r'(?:\/\*\*([^\/]+?)\*\/)?\s*(?:export\s+)?const\s+(\w+)\s*=\s*([\w\[\]]+)\s*;',
    multiLine: true);
final RegExp typeAliasPattern = new RegExp(
    r'(?:\/\*\*([\S\s]+?)\*\/)?\s*type\s+([\w]+)\s+=\s+([\w\[\]]+)\s*;',
    multiLine: true);

List<Type> parseTypeScriptInterface(String code) {
  List<Type> types = [];

  types.addAll(interfacePattern.allMatches(code).map((match) {
    final String comment = match.group(1);
    final String name = match.group(2);
    final String base = match.group(3);
    final String body = match.group(4);
    final List<Member> members = parseMembers(body);
    return new Interface(comment, name, base, members);
  }));
  types.addAll(namespacePattern.allMatches(code).map((match) {
    final String comment = match.group(1);
    final String name = match.group(2);
    final String body = match.group(3);
    final List<Member> members = parseMembers(body);
    return new Namespace(comment, name, members);
  }));
  types.addAll(typeAliasPattern.allMatches(code).map((match) {
    final String name = match.group(1);
    final String base = match.group(2);
    return new TypeAlias(name, base);
  }));

  return types;
}

List<Member> parseMembers(String body) {
  List<Member> members = [];

// TODO: Move parsing into classes, and handle ? = undefined
  members.addAll(fieldPattern.allMatches(body).map((m) {
    final String comment = m.group(1);
    final String name = m.group(2);
    final String typeString = m.group(3);
    return new Field(comment, name, typeString);
  }));
  members.addAll(constPattern.allMatches(body).map((m) {
    final String comment = m.group(1);
    final String name = m.group(2);
    final String value = m.group(3);
    return new Const(comment, name, value);
  }));
  return members;
}

abstract class Type {
  // TODO: Can it have comments?
  String name, baseTypes;
  Type(this.name, [this.baseTypes]);
}

abstract class Member {}

class TypeAlias extends Type {
  TypeAlias(name, baseType) : super(name, baseType);

  @override
  String toString() {
    return 'alias $name => $baseTypes';
  }
}

class Interface extends Type {
  String comment;
  List<Member> fields;
  Interface(this.comment, String name, baseTypes, this.fields)
      : super(name, baseTypes);

  @override
  String toString() {
    return 'type $name' +
        (baseTypes != null ? ' (extends $baseTypes)' : '') +
        fields.map((f) => '\n    ' + f.toString()).join('');
  }
}

class Namespace extends Type {
  String comment;
  List<Member> members;
  Namespace(this.comment, String name, this.members) : super(name);

  @override
  String toString() {
    return 'namespace $name ' +
        members.map((f) => '\n    ' + f.toString()).join('');
  }
}

class Field extends Member {
  String comment, name, typeString;
  Field(this.comment, this.name, this.typeString);
  @override
  String toString() {
    return '$name ($typeString)';
  }
}

class Const extends Member {
  String comment, name, value;
  Const(this.comment, this.name, this.value);
  @override
  String toString() {
    return 'const $name = $value';
  }
}
