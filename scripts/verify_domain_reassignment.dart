import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

void main(List<String> args) {
  final root = Directory(args.isEmpty ? Directory.current.path : args.first);
  final domainRoot = Directory(
    '${root.path}/packages/konyak_cli/lib/src/domain',
  );
  if (!domainRoot.existsSync()) {
    return;
  }

  final violations = <String>[];
  final files =
      domainRoot
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('.dart') &&
                !file.path.endsWith('.freezed.dart') &&
                !file.path.contains('/.dart_tool/') &&
                !file.path.contains('/build/'),
          )
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));

  for (final file in files) {
    final parsed = parseString(
      path: file.path,
      content: file.readAsStringSync(),
    );
    parsed.unit.accept(
      _DomainReassignmentVisitor(
        relativePath: file.path.substring(root.path.length + 1),
        lineInfo: parsed.lineInfo,
        violations: violations,
      ),
    );
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      'Domain logic must not use reassignment, ++/--, or var declarations.',
    );
    for (final violation in violations) {
      stderr.writeln(violation);
    }
    exitCode = 1;
  }
}

final class _DomainReassignmentVisitor extends RecursiveAstVisitor<void> {
  _DomainReassignmentVisitor({
    required this.relativePath,
    required this.lineInfo,
    required this.violations,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> violations;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _record('assignment ${node.operator.lexeme}', node);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    final operator = node.operator.lexeme;
    if (operator == '++' || operator == '--') {
      _record('postfix $operator', node);
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    final operator = node.operator.lexeme;
    if (operator == '++' || operator == '--') {
      _record('prefix $operator', node);
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.keyword?.lexeme == 'var') {
      _record('var declaration', node);
    }
    super.visitVariableDeclarationList(node);
  }

  void _record(String kind, AstNode node) {
    final location = lineInfo.getLocation(node.offset);
    final source = node.toSource().replaceAll(RegExp(r'\s+'), ' ').trim();
    violations.add(
      '$relativePath:${location.lineNumber}:${location.columnNumber}: '
      '$kind: $source',
    );
  }
}
