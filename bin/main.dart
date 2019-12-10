import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:lsp_spec_parser/codegen_dart.dart';
import 'package:lsp_spec_parser/markdown.dart';
import 'package:lsp_spec_parser/typescript.dart';

final Uri specUri = Uri.parse(
    'https://raw.githubusercontent.com/Microsoft/language-server-protocol/gh-pages/specification.md');
final String outPath = 'out/protocol_generated.dart';

main() async {
  final String spec = await fetchSpec();
  final List<ApiItem> types =
      extractTypeScriptBlocks(spec).map(parseSpec).expand((l) => l).toList();
  final String output = generateDartForTypes(types);
  new File(outPath).writeAsStringSync(output);
}

Future<String> fetchSpec() async {
  final resp = await http.get(specUri);
  return resp.body;
}
