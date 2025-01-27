lexer grammar TypeScriptLexer;

channels { ERROR }

options {
    superClass=TypeScriptLexerBase;
}


JsxComment:                     '{/*' .*? '*/}'           -> channel(HIDDEN);
MultiLineComment:               '/*' .*? '*/'             -> channel(HIDDEN);
SingleLineComment:              '//' ~[\r\n\u2028\u2029]* -> channel(HIDDEN);
RegularExpressionLiteral:       '/' RegularExpressionFirstChar RegularExpressionChar* {this.IsRegexPossible()}? '/' IdentifierPart*;

OpenBracket:                    '[';
CloseBracket:                   ']';
OpenParen:                      '(';
CloseParen:                     ')';
OpenBrace:                      '{' {this.ProcessOpenBrace();};
TemplateCloseBrace:             {this.IsInTemplateString()}? '}' -> popMode;
CloseBrace:                     '}' {this.ProcessCloseBrace();};
SemiColon:                      ';';
Comma:                          ',';
Assign:                         '=';
QuestionMark:                   '?';
Colon:                          ':';
Ellipsis:                       '...';
Dot:                            '.';
PlusPlus:                       '++';
MinusMinus:                     '--';
Plus:                           '+';
Minus:                          '-';
BitNot:                         '~';
Not:                            '!';
Multiply:                       '*';
Divide:                         '/';
Modulus:                        '%';
Power:                          '**';
NullCoalesce:                   '??';
Hashtag:                        '#';
RightShiftArithmetic:           '>>';
LeftShiftArithmetic:            '<<';
RightShiftLogical:              '>>>';
LessThan:                       '<';
MoreThan:                       '>';
LessThanEquals:                 '<=';
GreaterThanEquals:              '>=';
Equals_:                        '==';
NotEquals:                      '!=';
IdentityEquals:                 '===';
IdentityNotEquals:              '!==';
BitAnd:                         '&';
BitXOr:                         '^';
BitOr:                          '|';
And:                            '&&';
Or:                             '||';
MultiplyAssign:                 '*=';
DivideAssign:                   '/=';
ModulusAssign:                  '%=';
PlusAssign:                     '+=';
MinusAssign:                    '-=';
LeftShiftArithmeticAssign:      '<<=';
RightShiftArithmeticAssign:     '>>=';
RightShiftLogicalAssign:        '>>>=';
BitAndAssign:                   '&=';
BitXorAssign:                   '^=';
BitOrAssign:                    '|=';
ARROW:                          '=>';

Lodash:                         '_'; // lodash
Dollar:                         '$'; // jquery

/// Null Literals

NullLiteral:                    'null';

/// Boolean Literals

BooleanLiteral:                 'true'
              |                 'false';

/// Numeric Literals

DecimalLiteral:                 DecimalIntegerLiteral '.' [0-9]* ExponentPart?
              |                 '.' [0-9]+ ExponentPart?
              |                 DecimalIntegerLiteral ExponentPart?
              ;

/// Numeric Literals

HexIntegerLiteral:              '0' [xX] HexDigit+;
OctalIntegerLiteral:            '0' [0-7]+ {!this.IsStrictMode()}?;
OctalIntegerLiteral2:           '0' [oO] [0-7]+;
BinaryIntegerLiteral:           '0' [bB] [01]+;

/// Keywords

Break:                          'break';
Do:                             'do';
Instanceof:                     'instanceof';
Typeof:                         'typeof';
Keyof:                          'keyof';
Case:                           'case';
Else:                           'else';
New:                            'new';
Var:                            'var';
Catch:                          'catch';
Finally:                        'finally';
Return:                         'return';
Void:                           'void';
Continue:                       'continue';
For:                            'for';
Switch:                         'switch';
While:                          'while';
Debugger:                       'debugger';
Function_:                       'function';
This:                           'this';
With:                           'with';
Default:                        'default';
If:                             'if';
Throw:                          'throw';
Delete:                         'delete';
In:                             'in';
Try:                            'try';
As:                             'as';
From:                           'from';
ReadOnly:                       'readonly';
Async:                          'async';

Of:                             'of';
Await:                          'await';

/// Future Reserved Words

Class:                          'class';
Enum:                           'enum';
Extends:                        'extends';
Super:                          'super';
Const:                          'const';
Export:                         'export';
Import:                         'import';

/// The following tokens are also considered to be FutureReservedWords
/// when parsing strict mode

Implements:                     'implements' ;
Let:                            'let' ;
Private:                        'private' ;
Public:                         'public' ;
Interface:                      'interface' ;
Package:                        'package' ;
Protected:                      'protected' ;
Static:                         'static' ;
Yield:                          'yield' ;


//keywords:

Any : 'any';
Number: 'number';
Boolean: 'boolean';
String: 'string';
Symbol: 'symbol';


TypeAlias : 'type';

Get: 'get';
Set: 'set';

Constructor: 'constructor';
Namespace: 'namespace';
Require: 'require';
Module: 'module';
Declare: 'declare';
Unknown: 'unknown';
Undefined: 'undefined';

Abstract: 'abstract';

Is: 'is';

//
// Ext.2 Additions to 1.8: Decorators
//
At: '@';

/// Identifier Names and Identifiers

Identifier:                     IdentifierStart IdentifierPart*;

/// String Literals
StringLiteral:                 ('"' DoubleStringCharacter* '"'
             |                  '\'' SingleStringCharacter* '\'') {this.ProcessStringLiteral();}
             ;

BackTick:                       '`' {this.IncreaseTemplateDepth();} -> pushMode(TEMPLATE);

WhiteSpaces:                    [\t\u000B\u000C\u0020\u00A0]+ -> channel(HIDDEN);

LineTerminator:                 [\r\n\u2028\u2029] -> channel(HIDDEN);

/// Comments


HtmlComment:                    '<!--' .*? '-->' -> channel(HIDDEN);
CDataComment:                   '<![CDATA[' .*? ']]>' -> channel(HIDDEN);
UnexpectedCharacter:            . -> channel(ERROR);

mode TEMPLATE;

BackTickInside:                 '`' {this.DecreaseTemplateDepth();} -> type(BackTick), popMode;
TemplateStringStartExpression:  '${' -> pushMode(DEFAULT_MODE);
TemplateStringAtom:             ~[`];

//
// html tag declarations
//
mode TAG;

TagOpen
    : LessThan -> pushMode(TAG)
    ;
TagClose
    : MoreThan -> popMode
    ;

TagSlashClose
    : '/>' -> popMode
    ;

TagSlash
    : Divide
    ;

TagName
    : TagNameStartChar TagNameChar*
    ;

// an attribute value may have spaces b/t the '=' and the value
AttributeValue
    : [ ]* Attribute -> popMode
    ;

Attribute
    : DoubleQuoteString
    | SingleQuoteString
    | AttributeChar
    | HexChars
    | DecChars
    ;


// Fragment rules
fragment AttributeChar
    : '-'
    | '_'
    | '.'
    | '/'
    | '+'
    | ','
    | '?'
    | '='
    | ':'
    | ';'
    | '#'
    | [0-9a-zA-Z]
    ;

fragment AttributeChars
    : AttributeChar+ ' '?
    ;

fragment HexChars
    : '#' [0-9a-fA-F]+
    ;

fragment DecChars
    : [0-9]+ '%'?
    ;

fragment DoubleQuoteString
    : '"' ~[<"]* '"'
    ;
fragment SingleQuoteString
    : '\'' ~[<']* '\''
    ;

fragment
TagNameStartChar
    :   [:a-zA-Z]
    |   '\u2070'..'\u218F'
    |   '\u2C00'..'\u2FEF'
    |   '\u3001'..'\uD7FF'
    |   '\uF900'..'\uFDCF'
    |   '\uFDF0'..'\uFFFD'
    ;

fragment
TagNameChar
    : TagNameStartChar
    | '-'
    | '_'
    | '.'
    | Digit
    |   '\u00B7'
    |   '\u0300'..'\u036F'
    |   '\u203F'..'\u2040'
    ;

fragment
Digit
    : [0-9]
    ;

// Fragment rules

fragment DoubleStringCharacter
    : ~["\\\r\n]
    | '\\' EscapeSequence
    | LineContinuation
    ;

fragment SingleStringCharacter
    : ~['\\\r\n]
    | '\\' EscapeSequence
    | LineContinuation
    ;

fragment EscapeSequence
    : CharacterEscapeSequence
    | '0' // no digit ahead! TODO
    | HexEscapeSequence
    | UnicodeEscapeSequence
    | ExtendedUnicodeEscapeSequence
    ;

fragment CharacterEscapeSequence
    : SingleEscapeCharacter
    | NonEscapeCharacter
    ;

fragment HexEscapeSequence
    : 'x' HexDigit HexDigit
    ;

fragment UnicodeEscapeSequence
    : 'u' HexDigit HexDigit HexDigit HexDigit
    ;

fragment ExtendedUnicodeEscapeSequence
    : 'u' '{' HexDigit+ '}'
    ;

fragment SingleEscapeCharacter
    : ['"\\bfnrtv]
    ;

fragment NonEscapeCharacter
    : ~['"\\bfnrtv0-9xu\r\n]
    ;

fragment EscapeCharacter
    : SingleEscapeCharacter
    | [0-9]
    | [xu]
    ;

fragment LineContinuation
    : '\\' [\r\n\u2028\u2029]
    ;

fragment HexDigit
    : [0-9a-fA-F]
    ;

fragment DecimalIntegerLiteral
    : '0'
    | [1-9] [0-9]*
    ;

fragment ExponentPart
    : [eE] [+-]? [0-9]+
    ;

fragment IdentifierPart
    : IdentifierStart
    | [\p{Mn}]
    | [\p{Nd}]
    | [\p{Pc}]
    | '\u200C'
    | '\u200D'
    ;

fragment IdentifierStart
    : [\p{L}]
    | [$_]
    | '\\' UnicodeEscapeSequence
    ;

fragment RegularExpressionFirstChar
    : ~[*\r\n\u2028\u2029\\/[]
    | RegularExpressionBackslashSequence
    | '[' RegularExpressionClassChar* ']'
    ;

fragment RegularExpressionChar
    : ~[\r\n\u2028\u2029\\/[]
    | RegularExpressionBackslashSequence
    | '[' RegularExpressionClassChar* ']'
    ;

fragment RegularExpressionClassChar
    : ~[\r\n\u2028\u2029\]\\]
    | RegularExpressionBackslashSequence
    ;

fragment RegularExpressionBackslashSequence
    : '\\' ~[\r\n\u2028\u2029]
    ;

