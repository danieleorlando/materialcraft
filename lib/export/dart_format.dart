// Loaded lazily (see export_format.dart): dart_style and the analyzer parser
// add about a megabyte to the web build and are only needed to export.
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';

/// Cleans up and formats the exported code so that it passes strict lint
/// sets (very_good_analysis) and `dart format` leaves it unchanged.
///
/// The rewrites only touch the shape of the code, never its meaning:
/// named constants (`Offset.zero`), arguments equal to the constructor
/// default, redundant parentheses, `if` elements instead of conditional
/// list elements, braces around multi-line `if` bodies.
///
/// [languageVersion] is the Dart version the code is written for, as
/// `(major, minor)`.
String formatDart(String code, {(int, int) languageVersion = (3, 13)}) {
  var src = code;
  for (var i = 0; i < 12; i++) {
    final next = _rewrite(src, _Cleanup.new);
    if (next == src) break;
    src = next;
  }
  final formatter = DartFormatter(
    languageVersion: Version(languageVersion.$1, languageVersion.$2, 0),
  );
  src = formatter.format(src);
  final braced = _rewrite(src, _Braces.new);
  return braced == src ? src : formatter.format(braced);
}

typedef _Edit = ({int start, int end, String text});

String _rewrite(String src, _Rewriter Function(String) visitor) {
  final unit = parseString(
    content: src,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;
  final v = visitor(src);
  unit.accept(v);
  if (v.edits.isEmpty) return src;
  // Apply from the end; edits never overlap (a node inside an edited one is
  // left for the next round).
  final edits = v.edits.toList()..sort((a, b) => b.start.compareTo(a.start));
  var out = src;
  var limit = src.length + 1;
  for (final e in edits) {
    if (e.end > limit) continue;
    out = out.replaceRange(e.start, e.end, e.text);
    limit = e.start;
  }
  return out;
}

abstract class _Rewriter extends RecursiveAstVisitor<void> {
  _Rewriter(this.src);

  final String src;
  final edits = <_Edit>[];

  String text(AstNode n) => src.substring(n.offset, n.end);

  void replace(AstNode n, String text) =>
      edits.add((start: n.offset, end: n.end, text: text));
}

/// Expression without `const` and whitespace, to compare values.
String _norm(String s) =>
    s.replaceAll(RegExp(r'\bconst\s+'), '').replaceAll(RegExp(r'\s+'), '');

bool _sameValue(String a, String b) {
  final x = double.tryParse(a);
  final y = double.tryParse(b);
  if (x != null && y != null) return x == y;
  return a == b;
}

/// Constructor defaults (Flutter and the materialcraft package) used to drop
/// arguments that repeat them.
const _defaults = <String, Map<String, String>>{
  'BorderSide': {
    'color': 'Color(0xFF000000)',
    'width': '1',
    'style': 'BorderStyle.solid',
    'strokeAlign': 'BorderSide.strokeAlignInside',
  },
  'Border.all': {
    'color': 'Color(0xFF000000)',
    'width': '1',
    'style': 'BorderStyle.solid',
  },
  'RoundedRectangleBorder': {
    'side': 'BorderSide.none',
    'borderRadius': 'BorderRadius.zero',
  },
  'HardShadowBorder': {
    'side': 'BorderSide.none',
    'radius': '0',
    'shadowOffset': 'Offset.zero',
    'shadowColor': 'Color(0xFF000000)',
    'shadowSpread': '0',
    'shadows': '[]',
  },
  'HardShadowInputBorder': {
    'borderRadius': 'BorderRadius.zero',
    'shadowOffset': 'Offset.zero',
    'shadowColor': 'Color(0xFF000000)',
    'shadowSpread': '0',
    'shadows': '[]',
  },
  'SoftSliderThumbShape': {
    'radius': '10',
    'borderWidth': '1',
    'shadows': '[]',
    'pressedScale': '1.1',
  },
  'SoftRangeSliderThumbShape': {
    'radius': '10',
    'borderWidth': '1',
    'shadows': '[]',
    'pressedScale': '1.1',
  },
  'AppSwitchStyle': {
    'width': '52',
    'height': '32',
    'thumbSize': '24',
    'thumbBorder': 'false',
    'thumbShadows': '[]',
  },
  'ButtonSkin': {
    'radius': '20',
    'borderWidth': '0',
    'pressScale': '1',
    'focusRingWidth': '2',
    'focusRingOffset': '2',
  },
};

/// Constructors that are `const` (besides the `*ThemeData` classes).
const _constConstructors = {
  'AppSwitchStyle',
  'BorderRadius.all',
  'BorderRadius.horizontal',
  'BorderRadius.only',
  'BorderRadius.vertical',
  'BorderSide',
  'BoxConstraints',
  'BoxShadow',
  'ButtonSkin',
  'ButtonSkinState',
  'CircleBorder',
  'Color',
  'Duration',
  'EdgeInsets.all',
  'EdgeInsets.fromLTRB',
  'EdgeInsets.only',
  'EdgeInsets.symmetric',
  'HardShadowBorder',
  'HardShadowInputBorder',
  'Offset',
  'OutlineInputBorder',
  'Radius.circular',
  'Radius.elliptical',
  'RoundedRectangleBorder',
  'Size',
  'SoftRangeSliderThumbShape',
  'SoftSliderThumbShape',
  'StadiumBorder',
  'TextStyle',
  'TextTheme',
  'UnderlineInputBorder',
  'VisualDensity',
  'WidgetStatePropertyAll',
};

/// Named constants for zero values (use_named_constants).
String? _namedConstant(String name, List<String> args) {
  bool zero(String a) => a == 'Radius.zero' || _sameValue(a, '0');
  switch (name) {
    case 'Radius.circular' when args.length == 1 && zero(args[0]):
    case 'Radius.elliptical' when args.every(zero):
      return 'Radius.zero';
    case 'Offset' when args.length == 2 && args.every(zero):
      return 'Offset.zero';
    case 'Size' when args.length == 2 && args.every(zero):
      return 'Size.zero';
    case 'EdgeInsets.all' when args.length == 1 && zero(args[0]):
      return 'EdgeInsets.zero';
    case 'BorderRadius.circular' when args.length == 1 && zero(args[0]):
    case 'BorderRadius.all' when args.length == 1 && zero(args[0]):
      return 'BorderRadius.zero';
    case 'BorderRadius.vertical' ||
            'BorderRadius.horizontal' ||
            'BorderRadius.only'
        when args.every((a) => zero(a.substring(a.indexOf(':') + 1))):
      return 'BorderRadius.zero';
  }
  return null;
}

class _Cleanup extends _Rewriter {
  _Cleanup(super.src);

  /// Calls written without `new`/`const` parse as method invocations.
  (String, ArgumentList)? _call(Expression e) {
    if (e is InstanceCreationExpression) {
      final c = e.constructorName;
      // Without resolution `A.b` parses as the type `b` with the prefix `A`.
      final prefix = c.type.importPrefix?.name.lexeme;
      final type = [?prefix, c.type.name.lexeme].join('.');
      final name = c.name == null ? type : '$type.${c.name!.name}';
      return (name, e.argumentList);
    }
    if (e is MethodInvocation && e.operator?.lexeme != '?.') {
      final t = e.target;
      if (t == null) return (e.methodName.name, e.argumentList);
      if (t is SimpleIdentifier) {
        return ('${t.name}.${e.methodName.name}', e.argumentList);
      }
    }
    return null;
  }

  bool _handleCall(Expression node) {
    final call = _call(node);
    if (call == null) return false;
    final (name, list) = call;
    final args = [for (final a in list.arguments) _norm(text(a))];
    final constant = _namedConstant(name, args);
    if (constant != null) {
      replace(node, constant);
      return true;
    }
    if (_canBeConst(node, name, list)) {
      replace(
        node,
        'const ${text(node).replaceAll(RegExp(r'\bconst\s+'), '')}',
      );
      return true;
    }
    final defaults = _defaults[name];
    if (defaults == null) return false;
    final drop = <NamedArgument>[
      for (final a in list.arguments)
        if (a is NamedArgument &&
            _sameValue(
              _norm(text(a.argumentExpression)),
              defaults[a.name.lexeme] ?? '\u0000',
            ))
          a,
    ];
    if (drop.isEmpty) return false;
    final keep = [
      for (final a in list.arguments)
        if (!drop.contains(a)) text(a),
    ];
    final head = src.substring(node.offset, list.offset);
    replace(node, '$head(${keep.join(', ')}${keep.isEmpty ? '' : ','})');
    return true;
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!_handleCall(node)) super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_handleCall(node)) super.visitMethodInvocation(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    final p = node.parent;
    final inner = node.expression;
    final simpleInner =
        inner is! CascadeExpression &&
        inner is! AssignmentExpression &&
        inner is! FunctionExpression &&
        inner is! ThrowExpression;
    final slot =
        p is NamedArgument ||
        p is ArgumentList ||
        p is ListLiteral ||
        p is ReturnStatement ||
        p is ExpressionFunctionBody ||
        p is VariableDeclaration ||
        (p is ConditionalExpression &&
            node != p.condition &&
            inner is! ConditionalExpression);
    if (slot && simpleInner) {
      replace(node, text(inner));
      return;
    }
    // `(a?.b())?.c()` → `a?.b().c()`: inside the chain, null-shorting already
    // skips `.c()` (a `?.` there would be an invalid null-aware operator).
    final op = switch (p) {
      MethodInvocation(:final target?, :final operator?) when target == node =>
        operator,
      PropertyAccess(:final target?, :final operator) when target == node =>
        operator,
      _ => null,
    };
    if (op != null &&
        (inner is MethodInvocation || inner is PropertyAccess) &&
        _nullShorting(inner)) {
      final dot = op.lexeme == '?.' ? '.' : op.lexeme;
      replace(p!, '${text(inner)}$dot${src.substring(op.end, p.end)}');
      return;
    }
    super.visitParenthesizedExpression(node);
  }

  /// A call to a const constructor whose arguments are all constant, not
  /// already in a const context (prefer_const_constructors).
  bool _canBeConst(Expression node, String name, ArgumentList list) {
    if (node is InstanceCreationExpression && node.keyword != null) {
      return false;
    }
    final constCapable =
        _constConstructors.contains(name) ||
        (RegExp(r'^[A-Z]\w*ThemeData$').hasMatch(name) &&
            !name.startsWith('Cupertino') &&
            !name.startsWith('MaterialBased'));
    if (!constCapable) return false;
    for (AstNode? a = node.parent; a != null; a = a.parent) {
      if (a is InstanceCreationExpression && a.keyword?.lexeme == 'const' ||
          a is TypedLiteral && a.constKeyword != null ||
          a is VariableDeclarationList && a.keyword?.lexeme == 'const') {
        return false;
      }
    }
    return list.arguments.every(
      (a) =>
          _isConst(a is NamedArgument ? a.argumentExpression : a as Expression),
    );
  }

  bool _isConst(Expression e) => switch (e) {
    InstanceCreationExpression(:final keyword?) => keyword.lexeme == 'const',
    TypedLiteral(:final constKeyword?) => constKeyword.lexeme == 'const',
    IntegerLiteral() || DoubleLiteral() || BooleanLiteral() => true,
    SimpleStringLiteral() || NullLiteral() => true,
    PrefixExpression(:final operator, :final operand) =>
      operator.lexeme == '-' && _isConst(operand),
    // BorderSide.none, Offset.zero, FontWeight.w700, Colors.transparent, …
    PrefixedIdentifier(:final prefix, :final identifier) =>
      RegExp(r'^[A-Z]').hasMatch(prefix.name) &&
          RegExp(r'^[a-z]').hasMatch(identifier.name),
    _ => false,
  };

  /// Whether [e] is a chain with a `?.` (null-shorting covers what follows).
  bool _nullShorting(Expression e) => switch (e) {
    MethodInvocation(:final operator, :final target) =>
      operator?.lexeme == '?.' || (target != null && _nullShorting(target)),
    PropertyAccess(:final operator, :final target) =>
      operator.lexeme == '?.' || (target != null && _nullShorting(target)),
    _ => false,
  };

  @override
  void visitListLiteral(ListLiteral node) {
    for (final e in node.elements) {
      if (e is ConditionalExpression) {
        replace(
          e,
          'if (${text(e.condition)}) ${text(e.thenExpression)} '
          'else ${text(e.elseExpression)}',
        );
      }
    }
    super.visitListLiteral(node);
  }
}

/// Braces around `if` bodies that span several lines
/// (curly_braces_in_flow_control_structures).
class _Braces extends _Rewriter {
  _Braces(super.src);

  @override
  void visitIfStatement(IfStatement node) {
    final multiline = text(node).contains('\n');
    final body = node.thenStatement;
    if (multiline && body is! Block && node.elseStatement == null) {
      replace(body, '{ ${text(body)} }');
      return;
    }
    super.visitIfStatement(node);
  }
}
