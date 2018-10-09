import 'package:lsp_spec_parser/typescript.dart';

String generateDartForTypes(List<ApiItem> types) {
  final buffer = new IndentableStringBuffer();
  types.forEach((t) => _writeType(buffer, t));
  return buffer.toString();
}

void _writeType(IndentableStringBuffer buffer, ApiItem type) {
  if (type is Interface) {
    _writeInterface(buffer, type);
  } else if (type is TypeAlias) {
    _writeTypeAlias(buffer, type);
  } else if (type is Namespace) {
    _writeNamespace(buffer, type);
  } else {
    throw 'Unknown type';
  }
}

void _writeMember(IndentableStringBuffer buffer, Member member) {
  if (member is Field) {
    _writeField(buffer, member);
  } else if (member is Const) {
    _writeConst(buffer, member);
  } else {
    throw 'Unknown type';
  }
}

void _writeDocComment(IndentableStringBuffer buffer, String comment) {
  comment = comment?.trim();
  if (comment == null || comment.length == 0) {
    return;
  }
  Iterable<String> lines = comment.split('\n');
  // Wrap at 80 - 4 ('/// ') - indent characters.
  lines = wrapLines(lines, 80 - 4 - buffer.totalIndent);
  lines.forEach((l) => buffer.writeIndentedLn('/// ${l.trim()}'));
}

void _writeInterface(IndentableStringBuffer buffer, Interface interface) {
  _writeDocComment(buffer, interface.comment);
  buffer
    ..writeln('class ${interface.name} {')
    ..indent();
  // TODO(dantup): Generate constructors (inc. type checks for unions)
  interface.members.forEach((m) => _writeMember(buffer, m));
  // TODO(dantup): Generate toJson()
  // TODO(dantup): Generate fromJson()
  buffer
    ..outdent()
    ..writeln('}')
    ..writeln();
}

void _writeTypeAlias(IndentableStringBuffer buffer, TypeAlias typeAlias) {
  print('Skipping type alias ${typeAlias.name}');
}

void _writeNamespace(IndentableStringBuffer buffer, Namespace namespace) {
  _writeDocComment(buffer, namespace.comment);
  buffer
    ..writeln('abstract class ${namespace.name} {')
    ..indent();
  namespace.members.forEach((m) => _writeMember(buffer, m));
  buffer
    ..outdent()
    ..writeln('}')
    ..writeln();
}

void _writeField(IndentableStringBuffer buffer, Field field) {
  _writeDocComment(buffer, field.comment);
  if (field.types.length == 1) {
    buffer.writeIndented(_mapType(field.types.first));
  } else {
    buffer.writeIndented('Either<${field.types.map(_mapType).join(', ')}>');
  }
  buffer.writeln(' ${field.name};');
}

void _writeConst(IndentableStringBuffer buffer, Const cons) {
  _writeDocComment(buffer, cons.comment);
  buffer.writeIndentedLn('${cons.name} = ${cons.value}');
}

class IndentableStringBuffer extends StringBuffer {
  int _indentLevel = 0;
  int _indentSpaces = 2;

  void indent() => _indentLevel++;
  void outdent() => _indentLevel--;

  int get totalIndent => _indentLevel * _indentSpaces;
  String get _indentString => ' ' * totalIndent;

  void writeIndented(Object obj) {
    write(_indentString);
    write(obj);
  }

  void writeIndentedLn(Object obj) {
    write(_indentString);
    writeln(obj);
  }
}

String _mapType(String type) {
  const types = <String, String>{'boolean': 'bool'};
  return types[type] ?? type;
}

Iterable<String> wrapLines(List<String> lines, int maxLength) sync* {
  lines = lines.map((l) => l.trimRight()).toList();
  for (var line in lines) {
    while (true) {
      if (line.length <= maxLength) {
        yield line;
        break;
      } else {
        int lastSpace = line.lastIndexOf(' ', maxLength);
        // If there was no valid place to wrap, yield the whole string.
        if (lastSpace == -1) {
          yield line;
          break;
        } else {
          yield line.substring(0, lastSpace);
          line = line.substring(lastSpace + 1);
        }
      }
    }
  }
}
