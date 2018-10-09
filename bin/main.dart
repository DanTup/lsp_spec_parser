import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:lsp_spec_parser/markdown.dart';
import 'package:lsp_spec_parser/typescript.dart';

final Uri specUri = Uri.parse(
    'https://raw.githubusercontent.com/Microsoft/language-server-protocol/gh-pages/specification.md');

main() async {
  final String spec = await fetchSpec();
  final List<Type> types =
      extractTypeScriptBlocks(spec).map(parseSpec).expand((l) => l).toList();
  types.forEach(print);
}

Future<String> fetchSpec() async {
  final resp = await http.get(specUri);
  return resp.body;
}
