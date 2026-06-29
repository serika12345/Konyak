// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart'
    hide
        // ignore: undefined_hidden_name, Needed to support analyzer 8.
        LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

PluginBase createPlugin() => KonyakLintPlugin();

class KonyakLintPlugin extends PluginBase {
  KonyakLintPlugin();

  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => const [
    KonyakNoNullLiteralOutsideBoundary(),
    KonyakNoNullableTypeOutsideBoundary(),
    KonyakNoNullableAbsenceResult(),
    KonyakNoToNullable(),
    KonyakNoNullableBridgeOutsideBoundary(),
    KonyakNoNullableSentinelFlow(),
    KonyakNoResultFailureToOptionNone(),
    KonyakNoHandwrittenPart(),
    KonyakNoDomainIo(),
    KonyakNoDomainPartOfRoot(),
    KonyakNoDomainReassignment(),
    KonyakNoDomainVarDeclaration(),
    KonyakNoDomainIncrement(),
    KonyakNoDomainNestedConditional(),
    KonyakNoDomainParameterMutation(),
  ];
}

abstract class _KonyakAstRule extends DartLintRule {
  const _KonyakAstRule(LintCode code) : super(code: code);

  bool shouldRunOnPath(String normalizedPath);

  RecursiveAstVisitor<void> visitor(ErrorReporter reporter);

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final normalizedPath = _normalizePath(resolver.path);
    if (!shouldRunOnPath(normalizedPath)) {
      return;
    }

    context.registry.addCompilationUnit((node) {
      node.accept(visitor(reporter));
    });
  }
}

class KonyakNoNullLiteralOutsideBoundary extends _KonyakAstRule {
  const KonyakNoNullLiteralOutsideBoundary() : super(_code);

  static const _code = LintCode(
    name: 'konyak_no_null_literal_outside_boundary',
    problemMessage:
        'Use Option/Either/sealed results instead of a null literal outside an external boundary.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  bool shouldRunOnPath(String normalizedPath) =>
      _isStrictNullPolicyPath(normalizedPath);

  @override
  RecursiveAstVisitor<void> visitor(ErrorReporter reporter) =>
      _NullLiteralVisitor(reporter, _code);
}

class KonyakNoNullableTypeOutsideBoundary extends _KonyakAstRule {
  const KonyakNoNullableTypeOutsideBoundary() : super(_code);

  static const _code = LintCode(
    name: 'konyak_no_nullable_type_outside_boundary',
    problemMessage:
        'Use Option/Either/sealed results instead of a nullable type outside an external boundary.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  bool shouldRunOnPath(String normalizedPath) =>
      _isStrictNullPolicyPath(normalizedPath);

  @override
  RecursiveAstVisitor<void> visitor(ErrorReporter reporter) =>
      _NullableTypeVisitor(reporter, _code);
}

class KonyakNoNullableBridgeOutsideBoundary extends _KonyakAstRule {
  const KonyakNoNullableBridgeOutsideBoundary() : super(_code);

  static const _code = LintCode(
    name: 'konyak_no_nullable_bridge_outside_boundary',
    problemMessage:
        'Nullable bridge helpers are allowed only at direct external boundaries.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  bool shouldRunOnPath(String normalizedPath) =>
      _isStrictNullPolicyPath(normalizedPath);

  @override
  RecursiveAstVisitor<void> visitor(ErrorReporter reporter) =>
      _NullableBridgeVisitor(reporter, _code);
}

class KonyakNoNullableAbsenceResult extends _KonyakAstRule {
  const KonyakNoNullableAbsenceResult() : super(_code);

  static const _code = LintCode(
    name: 'konyak_no_nullable_absence_result',
    problemMessage:
        'Do not model absence with nullable Option/Future result shapes. Use Option, Either, or a sealed result.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  bool shouldRunOnPath(String normalizedPath) =>
      _isKonyakCliBackendSourcePath(normalizedPath);

  @override
  RecursiveAstVisitor<void> visitor(ErrorReporter reporter) =>
      _NullableAbsenceResultVisitor(reporter, _code);
}

class KonyakNoToNullable extends _KonyakAstRule {
  const KonyakNoToNullable() : super(_code);

  static const _code = LintCode(
    name: 'konyak_no_to_nullable',
    problemMessage:
        'Do not convert Option values to nullable values. Use match/map/flatMap or an explicit boundary projection.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  bool shouldRunOnPath(String normalizedPath) =>
      _isKonyakSourcePath(normalizedPath);

  @override
  RecursiveAstVisitor<void> visitor(ErrorReporter reporter) =>
      _ToNullableVisitor(reporter, _code);
}

class KonyakNoNullableSentinelFlow extends _KonyakAstRule {
  const KonyakNoNullableSentinelFlow() : super(_code);

  static const _code = LintCode(
    name: 'konyak_no_nullable_sentinel_flow',
    problemMessage:
        'Do not use nullable values or null-returning callbacks as success/failure sentinels.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  bool shouldRunOnPath(String normalizedPath) =>
      _isStrictNullPolicyPath(normalizedPath);

  @override
  RecursiveAstVisitor<void> visitor(ErrorReporter reporter) =>
      _NullableSentinelFlowVisitor(reporter, _code);
}

class KonyakNoResultFailureToOptionNone extends _KonyakAstRule {
  const KonyakNoResultFailureToOptionNone() : super(_code);

  static const _code = LintCode(
    name: 'konyak_no_result_failure_to_option_none',
    problemMessage:
        'Do not collapse Result/Either failure into Option.none(). Keep failure and absence separate.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  bool shouldRunOnPath(String normalizedPath) =>
      _isKonyakSourcePath(normalizedPath);

  @override
  RecursiveAstVisitor<void> visitor(ErrorReporter reporter) =>
      _ResultFailureToOptionNoneVisitor(reporter, _code);
}

class KonyakNoDomainIo extends _KonyakAstRule {
  const KonyakNoDomainIo() : super(_code);

  static const _code = LintCode(
    name: 'konyak_no_domain_io',
    problemMessage:
        'Domain logic must not reference external I/O or serialization boundary APIs.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  bool shouldRunOnPath(String normalizedPath) =>
      _isDomainSourcePath(normalizedPath);

  @override
  RecursiveAstVisitor<void> visitor(ErrorReporter reporter) =>
      _DomainIoVisitor(reporter, _code);
}

class KonyakNoHandwrittenPart extends DartLintRule {
  const KonyakNoHandwrittenPart() : super(code: _code);

  static const _code = LintCode(
    name: 'konyak_no_handwritten_part',
    problemMessage:
        'Hand-written Dart files must be standalone libraries. Use part only for generated Freezed/JSON code.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final normalizedPath = _normalizePath(resolver.path);
    if (!_isKonyakSourcePath(normalizedPath)) {
      return;
    }

    context.registry.addCompilationUnit((node) {
      node.accept(_HandwrittenPartVisitor(reporter, _code));
    });
  }
}

class KonyakNoDomainPartOfRoot extends DartLintRule {
  const KonyakNoDomainPartOfRoot() : super(code: _code);

  static const _code = LintCode(
    name: 'konyak_no_domain_part_of_root',
    problemMessage:
        'Domain files must be standalone libraries, not part of another library.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final normalizedPath = _normalizePath(resolver.path);
    if (!_isDomainSourcePath(normalizedPath)) {
      return;
    }

    context.registry.addCompilationUnit((node) {
      node.accept(_DomainPartOfRootVisitor(reporter, _code));
    });
  }
}

class KonyakNoDomainReassignment extends _KonyakAstRule {
  const KonyakNoDomainReassignment() : super(_code);

  static const _code = LintCode(
    name: 'konyak_no_domain_reassignment',
    problemMessage:
        'Domain logic must not reassign values. Use final values and expression branching.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  bool shouldRunOnPath(String normalizedPath) =>
      _isDomainSourcePath(normalizedPath);

  @override
  RecursiveAstVisitor<void> visitor(ErrorReporter reporter) =>
      _AssignmentVisitor(reporter, _code);
}

class KonyakNoDomainVarDeclaration extends _KonyakAstRule {
  const KonyakNoDomainVarDeclaration() : super(_code);

  static const _code = LintCode(
    name: 'konyak_no_domain_var_declaration',
    problemMessage: 'Domain local variables must be explicitly final or const.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  bool shouldRunOnPath(String normalizedPath) =>
      _isDomainSourcePath(normalizedPath);

  @override
  RecursiveAstVisitor<void> visitor(ErrorReporter reporter) =>
      _VarDeclarationVisitor(reporter, _code);
}

class KonyakNoDomainIncrement extends _KonyakAstRule {
  const KonyakNoDomainIncrement() : super(_code);

  static const _code = LintCode(
    name: 'konyak_no_domain_increment',
    problemMessage:
        'Domain logic must not mutate counters with increment or decrement operators.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  bool shouldRunOnPath(String normalizedPath) =>
      _isDomainSourcePath(normalizedPath);

  @override
  RecursiveAstVisitor<void> visitor(ErrorReporter reporter) =>
      _IncrementVisitor(reporter, _code);
}

class KonyakNoDomainNestedConditional extends _KonyakAstRule {
  const KonyakNoDomainNestedConditional() : super(_code);

  static const _code = LintCode(
    name: 'konyak_no_domain_nested_conditional',
    problemMessage:
        'Nested conditional expressions are not allowed in domain logic. Use switch or an IIFE.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  bool shouldRunOnPath(String normalizedPath) =>
      _isDomainSourcePath(normalizedPath);

  @override
  RecursiveAstVisitor<void> visitor(ErrorReporter reporter) =>
      _NestedConditionalVisitor(reporter, _code);
}

class KonyakNoDomainParameterMutation extends _KonyakAstRule {
  const KonyakNoDomainParameterMutation() : super(_code);

  static const _code = LintCode(
    name: 'konyak_no_domain_parameter_mutation',
    problemMessage:
        'Domain function parameters must not be mutated. Create a new immutable value instead.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  bool shouldRunOnPath(String normalizedPath) =>
      _isDomainSourcePath(normalizedPath);

  @override
  RecursiveAstVisitor<void> visitor(ErrorReporter reporter) =>
      _ParameterMutationVisitor(reporter, _code);
}

class _NullLiteralVisitor extends RecursiveAstVisitor<void> {
  const _NullLiteralVisitor(this.reporter, this.code);

  final ErrorReporter reporter;
  final LintCode code;

  @override
  void visitNullLiteral(NullLiteral node) {
    reporter.atNode(node, code);
    super.visitNullLiteral(node);
  }
}

class _NullableTypeVisitor extends RecursiveAstVisitor<void> {
  const _NullableTypeVisitor(this.reporter, this.code);

  final ErrorReporter reporter;
  final LintCode code;

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    _reportQuestion(node);
    super.visitGenericFunctionType(node);
  }

  @override
  void visitNamedType(NamedType node) {
    _reportQuestion(node);
    super.visitNamedType(node);
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    _reportQuestion(node);
    super.visitRecordTypeAnnotation(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    final question = node.question;
    if (question != null) {
      reporter.atToken(question, code);
    }
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    final question = node.question;
    if (question != null) {
      reporter.atToken(question, code);
    }
    super.visitFunctionTypedFormalParameter(node);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    final question = node.question;
    if (question != null) {
      reporter.atToken(question, code);
    }
    super.visitSuperFormalParameter(node);
  }

  void _reportQuestion(TypeAnnotation node) {
    final question = node.question;
    if (question != null) {
      reporter.atToken(question, code);
    }
  }
}

class _NullableBridgeVisitor extends RecursiveAstVisitor<void> {
  const _NullableBridgeVisitor(this.reporter, this.code);

  final ErrorReporter reporter;
  final LintCode code;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (methodName == 'fromNullable') {
      reporter.atNode(node.methodName, code);
    }
    super.visitMethodInvocation(node);
  }
}

class _NullableAbsenceResultVisitor extends RecursiveAstVisitor<void> {
  const _NullableAbsenceResultVisitor(this.reporter, this.code);

  final ErrorReporter reporter;
  final LintCode code;

  @override
  void visitNamedType(NamedType node) {
    if (_isNullableOption(node) || _isNullableAsyncAbsence(node)) {
      reporter.atNode(node, code);
    }
    super.visitNamedType(node);
  }

  bool _isNullableOption(NamedType node) {
    return _typeName(node) == 'Option' && node.question != null;
  }

  bool _isNullableAsyncAbsence(NamedType node) {
    final name = _typeName(node);
    if (name != 'Future' && name != 'FutureOr') {
      return false;
    }
    if (node.question != null) {
      return true;
    }

    final arguments = node.typeArguments?.arguments;
    return arguments != null &&
        arguments.isNotEmpty &&
        _hasOuterNullable(arguments.first);
  }

  bool _hasOuterNullable(TypeAnnotation annotation) {
    return switch (annotation) {
      NamedType(:final question) => question != null,
      GenericFunctionType(:final question) => question != null,
      RecordTypeAnnotation(:final question) => question != null,
    };
  }

  String _typeName(NamedType node) => node.name.lexeme;
}

class _ToNullableVisitor extends RecursiveAstVisitor<void> {
  const _ToNullableVisitor(this.reporter, this.code);

  final ErrorReporter reporter;
  final LintCode code;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'toNullable') {
      reporter.atNode(node.methodName, code);
    }
    super.visitMethodInvocation(node);
  }
}

class _ResultFailureToOptionNoneVisitor extends RecursiveAstVisitor<void> {
  const _ResultFailureToOptionNoneVisitor(this.reporter, this.code);

  final ErrorReporter reporter;
  final LintCode code;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'getOrElse' &&
        node.argumentList.arguments.any(_returnsOptionNone)) {
      reporter.atNode(node.methodName, code);
    }
    super.visitMethodInvocation(node);
  }

  bool _returnsOptionNone(Expression argument) {
    if (argument is FunctionExpression) {
      final body = argument.body;
      return body is ExpressionFunctionBody && _isOptionNone(body.expression);
    }
    return false;
  }

  bool _isOptionNone(Expression expression) {
    if (expression is ParenthesizedExpression) {
      return _isOptionNone(expression.expression);
    }
    if (expression is InstanceCreationExpression) {
      final constructorName = expression.constructorName;
      return constructorName.type.name.lexeme == 'Option' &&
          constructorName.name?.name == 'none';
    }
    if (expression is MethodInvocation) {
      final target = expression.target;
      return target is SimpleIdentifier &&
          target.name == 'Option' &&
          expression.methodName.name == 'none';
    }
    return false;
  }
}

class _NullableSentinelFlowVisitor extends RecursiveAstVisitor<void> {
  const _NullableSentinelFlowVisitor(this.reporter, this.code);

  final ErrorReporter reporter;
  final LintCode code;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (_isNullEqualityOperator(node.operator) &&
        (_isNullLiteral(node.leftOperand) &&
                _isFailureSentinelExpression(node.rightOperand) ||
            _isNullLiteral(node.rightOperand) &&
                _isFailureSentinelExpression(node.leftOperand))) {
      reporter.atToken(node.operator, code);
    }
    super.visitBinaryExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (_hasOnlyWildcardParameters(node.parameters) &&
        _functionBodyReturnsNull(node.body)) {
      reporter.atNode(node, code);
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'fold' &&
        (node.typeArguments?.arguments.any(_typeAnnotationIsNullable) ??
            false)) {
      reporter.atNode(node.methodName, code);
    }
    if (node.methodName.name == 'match' &&
        node.argumentList.arguments.isNotEmpty &&
        _functionArgumentReturnsNull(node.argumentList.arguments.first) &&
        _looksLikeOptionMatch(node)) {
      reporter.atNode(node.methodName, code);
    }
    super.visitMethodInvocation(node);
  }

  bool _functionArgumentReturnsNull(Expression argument) {
    return argument is FunctionExpression &&
        _functionBodyReturnsNull(argument.body);
  }

  bool _functionBodyReturnsNull(FunctionBody body) {
    if (body is ExpressionFunctionBody) {
      return _isNullLiteral(body.expression);
    }
    if (body is BlockFunctionBody) {
      final statements = body.block.statements;
      return statements.length == 1 &&
          statements.single is ReturnStatement &&
          _isNullLiteral((statements.single as ReturnStatement).expression);
    }
    return false;
  }

  bool _hasOnlyWildcardParameters(FormalParameterList? parameters) {
    if (parameters == null || parameters.parameters.isEmpty) {
      return false;
    }
    return parameters.parameters.every(
      (parameter) => parameter.name?.lexeme == '_',
    );
  }

  bool _looksLikeOptionMatch(MethodInvocation node) {
    final targetType = node.realTarget?.staticType;
    if (targetType == null) {
      return true;
    }
    final displayString = targetType.getDisplayString(withNullability: false);
    return displayString == 'Option' || displayString.startsWith('Option<');
  }

  bool _typeAnnotationIsNullable(TypeAnnotation annotation) {
    return annotation.question != null;
  }

  bool _isFailureSentinelExpression(Expression expression) {
    final unwrapped = _unparenthesized(expression);
    if (unwrapped is SimpleIdentifier) {
      return unwrapped.name.toLowerCase().contains('failure');
    }
    if (unwrapped is PrefixedIdentifier) {
      return unwrapped.identifier.name.toLowerCase().contains('failure');
    }
    if (unwrapped is PropertyAccess) {
      return unwrapped.propertyName.name.toLowerCase().contains('failure');
    }
    return false;
  }

  Expression _unparenthesized(Expression expression) {
    return expression is ParenthesizedExpression
        ? _unparenthesized(expression.expression)
        : expression;
  }

  bool _isNullLiteral(Expression? expression) {
    if (expression == null) {
      return false;
    }
    final unwrapped = _unparenthesized(expression);
    return unwrapped is NullLiteral;
  }

  bool _isNullEqualityOperator(Token token) {
    return token.type == TokenType.EQ_EQ || token.type == TokenType.BANG_EQ;
  }
}

class _DomainIoVisitor extends RecursiveAstVisitor<void> {
  const _DomainIoVisitor(this.reporter, this.code);

  static const _ioTypeNames = {
    'Directory',
    'File',
    'FileSystemEntity',
    'FileSystemException',
    'HttpClient',
    'IOException',
    'Platform',
    'Process',
    'ProcessException',
    'RandomAccessFile',
    'SocketException',
    'StringSink',
  };

  static const _ioInstanceMethodNames = {
    'create',
    'createSync',
    'delete',
    'deleteSync',
    'exists',
    'existsSync',
    'open',
    'openRead',
    'openSync',
    'openWrite',
    'readAsBytes',
    'readAsBytesSync',
    'readAsLines',
    'readAsLinesSync',
    'readAsString',
    'readAsStringSync',
    'rename',
    'renameSync',
    'writeAsBytes',
    'writeAsBytesSync',
    'writeAsString',
    'writeAsStringSync',
  };

  static const _ioStaticMethodNames = {
    'identical',
    'identicalSync',
    'isDirectory',
    'isDirectorySync',
    'isFile',
    'isFileSync',
    'isLink',
    'isLinkSync',
    'run',
    'runSync',
    'start',
    'type',
    'typeSync',
  };

  static const _ioStaticPropertyNames = {
    'environment',
    'executable',
    'isAndroid',
    'isFuchsia',
    'isIOS',
    'isLinux',
    'isMacOS',
    'isWindows',
    'localeName',
    'localHostname',
    'numberOfProcessors',
    'operatingSystem',
    'operatingSystemVersion',
    'packageConfig',
    'pathSeparator',
    'resolvedExecutable',
    'script',
    'version',
  };

  static const _ioTopLevelFunctionNames = {'jsonDecode', 'jsonEncode'};

  final ErrorReporter reporter;
  final LintCode code;

  @override
  void visitImportDirective(ImportDirective node) {
    if (node.uri.stringValue == 'dart:convert' ||
        node.uri.stringValue == 'dart:io') {
      reporter.atNode(node.uri, code);
    }
    super.visitImportDirective(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (_isDartIoBoundaryName(node.name.lexeme)) {
      reporter.atToken(node.name, code);
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_isIoTypeName(node.constructorName.type.name.lexeme) ||
        _isIoDartType(node.constructorName.type.type)) {
      reporter.atNode(node.constructorName.type, code);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isIoMethodInvocation(node)) {
      reporter.atNode(node.methodName, code);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitNamedType(NamedType node) {
    if (_isIoTypeName(node.name.lexeme) || _isIoDartType(node.type)) {
      reporter.atNode(node, code);
    }
    super.visitNamedType(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_isPlatformStaticProperty(node.prefix, node.identifier.name)) {
      reporter.atNode(node, code);
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_isPlatformStaticProperty(node.realTarget, node.propertyName.name)) {
      reporter.atNode(node.propertyName, code);
    }
    super.visitPropertyAccess(node);
  }

  bool _isIoMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (_ioTopLevelFunctionNames.contains(methodName) &&
        node.realTarget == null) {
      return true;
    }
    if (_ioInstanceMethodNames.contains(methodName) &&
        _isIoDartType(node.realTarget?.staticType)) {
      return true;
    }
    if (_ioStaticMethodNames.contains(methodName) &&
        _isIoStaticTarget(node.realTarget)) {
      return true;
    }
    return false;
  }

  bool _isIoStaticTarget(Expression? target) {
    if (target is SimpleIdentifier) {
      return _isIoTypeName(target.name);
    }
    if (target is PrefixedIdentifier) {
      return _isIoTypeName(target.identifier.name);
    }
    if (target is PropertyAccess) {
      return _isIoTypeName(target.propertyName.name);
    }
    return false;
  }

  bool _isPlatformStaticProperty(Expression? target, String propertyName) {
    return _ioStaticPropertyNames.contains(propertyName) &&
        _isIoStaticTarget(target) &&
        _targetName(target) == 'Platform';
  }

  String _targetName(Expression? target) {
    if (target is SimpleIdentifier) {
      return target.name;
    }
    if (target is PrefixedIdentifier) {
      return target.identifier.name;
    }
    if (target is PropertyAccess) {
      return target.propertyName.name;
    }
    return '';
  }

  bool _isIoDartType(DartType? type) {
    if (type == null) {
      return false;
    }
    final displayString = type.getDisplayString(withNullability: false);
    return _isIoTypeName(displayString) ||
        _ioTypeNames.any((name) => displayString.startsWith('$name<'));
  }

  bool _isIoTypeName(String name) =>
      _ioTypeNames.contains(name) || _isDartIoBoundaryName(name);

  bool _isDartIoBoundaryName(String name) => name.startsWith('DartIo');
}

class _HandwrittenPartVisitor extends RecursiveAstVisitor<void> {
  const _HandwrittenPartVisitor(this.reporter, this.code);

  final ErrorReporter reporter;
  final LintCode code;

  @override
  void visitPartDirective(PartDirective node) {
    if (!_isGeneratedPartUri(node.uri.stringValue)) {
      reporter.atNode(node, code);
    }
    super.visitPartDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    reporter.atNode(node, code);
    super.visitPartOfDirective(node);
  }

  bool _isGeneratedPartUri(String? uri) {
    if (uri == null) {
      return false;
    }
    return uri.endsWith('.freezed.dart') || uri.endsWith('.g.dart');
  }
}

class _DomainPartOfRootVisitor extends RecursiveAstVisitor<void> {
  const _DomainPartOfRootVisitor(this.reporter, this.code);

  final ErrorReporter reporter;
  final LintCode code;

  @override
  void visitPartOfDirective(PartOfDirective node) {
    reporter.atNode(node, code);
    super.visitPartOfDirective(node);
  }
}

class _AssignmentVisitor extends RecursiveAstVisitor<void> {
  const _AssignmentVisitor(this.reporter, this.code);

  final ErrorReporter reporter;
  final LintCode code;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    reporter.atToken(node.operator, code);
    super.visitAssignmentExpression(node);
  }
}

class _VarDeclarationVisitor extends RecursiveAstVisitor<void> {
  const _VarDeclarationVisitor(this.reporter, this.code);

  final ErrorReporter reporter;
  final LintCode code;

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    final keyword = node.keyword;
    if (keyword != null && keyword.keyword == Keyword.VAR) {
      reporter.atToken(keyword, code);
    }
    super.visitVariableDeclarationList(node);
  }
}

class _IncrementVisitor extends RecursiveAstVisitor<void> {
  const _IncrementVisitor(this.reporter, this.code);

  final ErrorReporter reporter;
  final LintCode code;

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (_isIncrementOperator(node.operator)) {
      reporter.atToken(node.operator, code);
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (_isIncrementOperator(node.operator)) {
      reporter.atToken(node.operator, code);
    }
    super.visitPrefixExpression(node);
  }
}

class _NestedConditionalVisitor extends RecursiveAstVisitor<void> {
  _NestedConditionalVisitor(this.reporter, this.code);

  final ErrorReporter reporter;
  final LintCode code;
  int _conditionalDepth = 0;

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    if (_conditionalDepth > 0) {
      reporter.atNode(node, code);
    }

    _conditionalDepth += 1;
    super.visitConditionalExpression(node);
    _conditionalDepth -= 1;
  }
}

class _ParameterMutationVisitor extends RecursiveAstVisitor<void> {
  _ParameterMutationVisitor(this.reporter, this.code);

  static const _mutatingMethods = {
    'add',
    'addAll',
    'addEntries',
    'clear',
    'fillRange',
    'insert',
    'insertAll',
    'remove',
    'removeAt',
    'removeLast',
    'removeRange',
    'removeWhere',
    'replaceRange',
    'retainWhere',
    'setAll',
    'setRange',
    'shuffle',
    'sort',
    'update',
    'updateAll',
  };

  final ErrorReporter reporter;
  final LintCode code;
  final List<Set<String>> _parameterScopes = [];

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _withParameterScope(
      node.parameters,
      () => super.visitConstructorDeclaration(node),
    );
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _withParameterScope(
      node.parameters,
      () => super.visitFunctionExpression(node),
    );
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _withParameterScope(
      node.parameters,
      () => super.visitMethodDeclaration(node),
    );
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_mutatingMethods.contains(node.methodName.name) &&
        _targetsParameter(node.realTarget) &&
        _isKnownMutableReceiver(node.realTarget?.staticType)) {
      reporter.atNode(node.methodName, code);
    }
    super.visitMethodInvocation(node);
  }

  void _withParameterScope(
    FormalParameterList? parameters,
    void Function() visitBody,
  ) {
    if (parameters == null) {
      visitBody();
      return;
    }

    final parameterNames = parameters.parameters
        .map((parameter) => parameter.name?.lexeme)
        .whereType<String>()
        .toSet();
    _parameterScopes.add(parameterNames);
    visitBody();
    _parameterScopes.removeLast();
  }

  bool _targetsParameter(Expression? expression) {
    if (expression == null) {
      return false;
    }
    if (expression is SimpleIdentifier) {
      return _isVisibleParameter(expression.name);
    }
    if (expression is ParenthesizedExpression) {
      return _targetsParameter(expression.expression);
    }
    if (expression is PropertyAccess) {
      return _targetsParameter(expression.realTarget);
    }
    if (expression is PrefixedIdentifier) {
      return _targetsParameter(expression.prefix);
    }
    if (expression is IndexExpression) {
      return _targetsParameter(expression.realTarget);
    }
    return false;
  }

  bool _isVisibleParameter(String name) =>
      _parameterScopes.reversed.any((scope) => scope.contains(name));

  bool _isKnownMutableReceiver(DartType? type) {
    if (type == null) {
      return false;
    }

    final displayString = type.getDisplayString(withNullability: false);
    const mutablePrefixes = [
      'HashMap<',
      'HashSet<',
      'LinkedHashMap<',
      'LinkedHashSet<',
      'List<',
      'ListQueue<',
      'Map<',
      'Queue<',
      'Set<',
      'SplayTreeMap<',
      'SplayTreeSet<',
    ];
    const mutableExactTypes = {'BytesBuilder', 'StringBuffer'};

    return mutableExactTypes.contains(displayString) ||
        mutablePrefixes.any(displayString.startsWith);
  }
}

bool _isIncrementOperator(Token token) =>
    token.type == TokenType.PLUS_PLUS || token.type == TokenType.MINUS_MINUS;

bool _isDomainSourcePath(String normalizedPath) =>
    _isSourceDartPath(normalizedPath) &&
    normalizedPath.contains('/packages/konyak_cli/lib/src/domain/');

bool _isStrictNullPolicyPath(String normalizedPath) =>
    _isSourceDartPath(normalizedPath) &&
    _isKonyakDartPath(normalizedPath) &&
    !_isExternalNullBoundaryPath(normalizedPath);

bool _isKonyakSourcePath(String normalizedPath) =>
    _isSourceDartPath(normalizedPath) && _isKonyakDartPath(normalizedPath);

bool _isKonyakCliBackendSourcePath(String normalizedPath) =>
    _isSourceDartPath(normalizedPath) &&
    (normalizedPath.contains('/packages/konyak_cli/lib/') ||
        normalizedPath.contains('/packages/konyak_cli/bin/'));

bool _isSourceDartPath(String normalizedPath) =>
    normalizedPath.endsWith('.dart') &&
    !normalizedPath.endsWith('.freezed.dart') &&
    !normalizedPath.endsWith('.g.dart') &&
    !normalizedPath.contains('/build/') &&
    !normalizedPath.contains('/.dart_tool/');

bool _isKonyakDartPath(String normalizedPath) =>
    normalizedPath.contains('/packages/konyak_cli/lib/') ||
    normalizedPath.contains('/packages/konyak_cli/bin/') ||
    normalizedPath.contains('/apps/konyak/lib/');

bool _isExternalNullBoundaryPath(String normalizedPath) {
  final relativePath = _relativeKonyakPath(normalizedPath);
  const boundaryPrefixes = [
    'packages/konyak_cli/bin/',
    'packages/konyak_cli/lib/src/cli/',
    'packages/konyak_cli/lib/src/io/',
    'packages/konyak_cli/lib/src/platform/',
    'apps/konyak/lib/src/home_loader/',
    'apps/konyak/lib/src/home_loader_parts/',
    'apps/konyak/lib/src/icons/',
  ];
  if (boundaryPrefixes.any(relativePath.startsWith)) {
    return true;
  }
  if (relativePath.startsWith('apps/konyak/lib/src/app/') &&
      relativePath !=
          'apps/konyak/lib/src/app/dialogs/app_settings_runtime_view_model.dart') {
    return true;
  }
  const appBoundaryPrefixes = [
    'apps/konyak/lib/src/bottles/',
    'apps/konyak/lib/src/files/',
    'apps/konyak/lib/src/l10n/',
    'apps/konyak/lib/src/runtimes/',
    'apps/konyak/lib/src/runs/',
    'apps/konyak/lib/src/settings/',
    'apps/konyak/lib/src/updates/',
  ];
  if (appBoundaryPrefixes.any(relativePath.startsWith)) {
    return true;
  }

  const boundaryPaths = {
    'packages/konyak_cli/lib/konyak_cli.dart',
    // JSON contract rendering currently lives on these domain models.
    'packages/konyak_cli/lib/src/domain/app/app_settings_models.dart',
    'packages/konyak_cli/lib/src/domain/bottle/bottle_models.dart',
    'packages/konyak_cli/lib/src/domain/bottle/bottle_mutation_models.dart',
    'packages/konyak_cli/lib/src/domain/bottle/bottle_runtime_settings_models.dart',
    'packages/konyak_cli/lib/src/domain/program/program_catalog_models.dart',
    'packages/konyak_cli/lib/src/domain/program/program_graphics_backend_hints.dart',
    'packages/konyak_cli/lib/src/domain/program/program_mutation_models.dart',
    'packages/konyak_cli/lib/src/domain/program/program_run_models.dart',
    'packages/konyak_cli/lib/src/domain/program/program_settings_models.dart',
    'packages/konyak_cli/lib/src/domain/runtime/runtime_models.dart',
    'packages/konyak_cli/lib/src/domain/runtime/runtime_package_installation.dart',
    'packages/konyak_cli/lib/src/domain/runtime/runtime_validation_models.dart',
    'packages/konyak_cli/lib/src/domain/update/app_update_checker.dart',
    'packages/konyak_cli/lib/src/domain/update/update_records.dart',
    // Flutter CLI JSON parsing/result projection and process environment
    // adapters are the remaining nullable boundaries under lib/src/cli.
    'apps/konyak/lib/src/cli/bottle_create_contract.dart',
    'apps/konyak/lib/src/cli/bottle_detail_contract.dart',
    'apps/konyak/lib/src/cli/bottle_list_contract.dart',
    'apps/konyak/lib/src/cli/bottle_record_contract.dart',
    'apps/konyak/lib/src/cli/konyak_cli_bottle_payload_parsers.dart',
    'apps/konyak/lib/src/cli/konyak_cli_failure_messages.dart',
    'apps/konyak/lib/src/cli/konyak_cli_process_runner.dart',
    'apps/konyak/lib/src/cli/konyak_cli_program_payload_parsers.dart',
    'apps/konyak/lib/src/cli/konyak_cli_program_result_types.dart',
    'apps/konyak/lib/src/cli/konyak_cli_result_helpers.dart',
    'apps/konyak/lib/src/cli/konyak_cli_settings_payload_parsers.dart',
    'apps/konyak/lib/src/cli/konyak_cli_update_payload_parsers.dart',
    'apps/konyak/lib/src/cli/konyak_cli_wine_process_payload_parsers.dart',
    'apps/konyak/lib/src/cli/konyak_cli_wine_process_result_types.dart',
    'apps/konyak/lib/src/cli/konyak_cli_winetricks_payload_parsers.dart',
    'apps/konyak/lib/src/cli/program_run_contract.dart',
    'apps/konyak/lib/src/cli/runtime_install_contract.dart',
    'apps/konyak/lib/src/cli/runtime_list_contract.dart',
    // Flutter widget files use nullable framework parameters at the final UI
    // adapter line. View-model files are intentionally not listed here.
    'apps/konyak/lib/main.dart',
    'apps/konyak/lib/src/app/dialogs/app_settings_runtime_section.dart',
  };
  return boundaryPaths.contains(relativePath);
}

String _relativeKonyakPath(String normalizedPath) {
  const packagePathMarkers = ['packages/konyak_cli/', 'apps/konyak/'];
  for (final marker in packagePathMarkers) {
    final markerIndex = normalizedPath.indexOf(marker);
    if (markerIndex != -1) {
      return normalizedPath.substring(markerIndex);
    }
  }
  return normalizedPath;
}

String _normalizePath(String path) => path.replaceAll('\\', '/');
