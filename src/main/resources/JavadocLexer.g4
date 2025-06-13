lexer grammar JavadocLexer;

channels {
    LEADING_ASTERISKS, WHITESPACES
}

tokens {
    JAVADOC, LEADING_ASTERISK, NEWLINE, TEXT, WS, JAVADOC_INLINE_TAG_START, JAVADOC_INLINE_TAG_END,
    CODE_LITERAL, LINK_LITERAL, IDENTIFIER, DOT, HASH, LPAREN, RPAREN, COMMA, LINKPLAIN_LITERAL,
    AUTHOR_LITERAL, DEPRECATED_LITERAL, RETURN_LITERAL, PARAM_LITERAL, TAG_OPEN, TAG_CLOSE, TAG_SLASH_CLOSE,
    TAG_SLASH, TAG_EQUALS, TAG_NAME, ATTRIBUTE_VALUE
}

@header {
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Deque;
import java.util.List;

import org.antlr.v4.runtime.Token;
}


@lexer::members {
    private int previousTokenType = 0;
    private Token previousToken = null;
    private boolean afterNewline = true;
    private boolean isJavadocTag = true;

    public boolean isAfterNewline() {
        return afterNewline;
    }

    public void setAfterNewline() {
        afterNewline = true;
    }

    public boolean isNormalText() {
        int nextChar = _input.LA(1);
        int afterNextChar = _input.LA(2);
        boolean isJavadocTag = isJavadocTag();
        boolean isHtmlTag = nextChar == '<'
                    && (Character.isLetter(afterNextChar) || afterNextChar == '/');
        boolean isInlineTag = nextChar == '{' && afterNextChar == '@';
        return !isJavadocTag && !isHtmlTag && !isInlineTag;
    }

    public boolean isJavadocTag() {
        if (previousToken == null) {
            return true;
        }
        int nextChar = _input.LA(1);

        return (previousTokenType == WS || previousTokenType == LEADING_ASTERISK)
                        && nextChar == '@';
    }

    @Override
    public void emit(Token token) {
        super.emit(token);
        if (token.getType() == TAG_NAME) {
            if (isOpenTagName(token)) {
                openTagNameTokens.push(token);
            } else {
                closeTagNameTokens.push(token);
            }
        }
        previousTokenType = token.getType();
        previousToken = token;
        if (previousTokenType != NEWLINE) {
            afterNewline = false;
        }
    }

    private final Deque<Token> openTagNameTokens = new ArrayDeque<>();
    private final Deque<Token> closeTagNameTokens = new ArrayDeque<>();

    public List<Token> getUnclosedTagNameTokens() {
        final List<Token> unmatched = new ArrayList<>();

        while (!closeTagNameTokens.isEmpty()) {
            final Token closingTag = closeTagNameTokens.pop();

            while (!openTagNameTokens.isEmpty()) {
                final Token openingTag = openTagNameTokens.peek();
                if (openingTag.getText().equals(closingTag.getText())) {
                    // matched, discard both
                    openTagNameTokens.pop();
                    break;
                }

                // unmatched opening tag
                unmatched.add(openTagNameTokens.pop());
            }
        }

        // Any remaining open tags are unmatched too
        while (!openTagNameTokens.isEmpty()) {
            unmatched.add(openTagNameTokens.pop());
        }

        // Reverse to restore original order
        Collections.reverse(unmatched);
        return Collections.unmodifiableList(unmatched);
    }


    private boolean isOpenTagName(Token token) {
        return previousToken == null || previousToken.getType() != TAG_SLASH;
    }

}

LEADING_ASTERISK
    : [ \t]* '*' {isAfterNewline()}? {
        if (!Character.isWhitespace(_input.LA(1))) {
           pushMode(text);
        }
    } -> channel(LEADING_ASTERISKS)
    ;

WS :   (' '|'\t')+ -> channel(WHITESPACES),  pushMode(text) ;

NEWLINE
    : '\r'? '\n' {setAfterNewline();}
    ;

mode text;

Text_NEWLINE
    : '\r'? '\n' {setAfterNewline();} -> mode(DEFAULT_MODE), type(NEWLINE)
    ;

TEXT
    : TEXT_CHAR+
    ;

fragment TEXT_CHAR
    : {isNormalText()}? ~[\r\n]
    ;

BLOCK_TAG_ENTRY
    : {isJavadocTag()}? -> pushMode(blockTag), skip
    ;

JAVADOC_INLINE_TAG_START: '{@' -> pushMode(javadocInlineTag);

TAG_OPEN: '<' -> pushMode(tag);


mode javadocInlineTag;

CODE_LITERAL: 'code' -> pushMode(code);
LINK_LITERAL : 'link'-> pushMode(link);
LINKPLAIN_LITERAL : 'linkplain' -> pushMode(link);
CUSTOM_NAME:  [a-zA-Z0-9:._-]+ -> pushMode(inlineTagDescription);

mode code;
// TODO: Allow '}' to be treated as regular text within code blocks.

Code_NEWLINE
    : '\r'? '\n' {setAfterNewline();} -> pushMode(startOfLine), type(NEWLINE)
    ;

Code_TEXT: ~[}\r\n]+ -> type(TEXT);

JAVADOC_INLINE_TAG_END: '}' -> mode(text);


mode link;
IDENTIFIER:
    Letter LetterOrDigit*
    {
        int la = _input.LA(1);
        if (previousTokenType == HASH && la != '(') {
            _mode = inlineTagDescription;
        }
    };

DOT: '.';
HASH: '#';
LPAREN: '(';
RPAREN: ')' -> pushMode(inlineTagDescription);
COMMA: ',';
Link_WS: [ \t]+ -> type(WS), channel(WHITESPACES);
Link_JAVADOC_INLINE_TAG_END: '}' -> type(JAVADOC_INLINE_TAG_END), mode(text);

fragment LetterOrDigit
    : Letter
    | [0-9]
    ;

fragment Letter: [a-zA-Z$_];


mode inlineTagDescription;

InlineDescription_TEXT
    : ~[}\r\n]+ -> type(TEXT)
    ;

InlineDescription_NEWLINE
    : '\r'? '\n' {setAfterNewline();} -> pushMode(startOfLine), type(NEWLINE)
    ;

InlineDescription_JAVADOC_INLINE_TAG_END: '}' -> type(JAVADOC_INLINE_TAG_END), mode(text);

mode startOfLine;

StartOfLine_LEADING_ASTERISK
    : [ \t]* '*' -> channel(LEADING_ASTERISKS), popMode, type(LEADING_ASTERISK)
    ;

mode blockTag;
AUTHOR_LITERAL: '@author' -> pushMode(text);
DEPRECATED_LITERAL : '@deprecated' -> pushMode(text);
RETURN_LITERAL: '@return' -> pushMode(text);
PARAM_LITERAL: '@param' -> pushMode(parameterName);
BlockTag_CUSTOM_NAME: '@' [a-zA-Z0-9:._-]+ -> type(CUSTOM_NAME), pushMode(text);

mode parameterName;
PARAMETER_NAME: Letter LetterOrDigit* -> type(IDENTIFIER), mode(text);
Param_WS: [ \t]+ -> type(WS), channel(WHITESPACES);


mode tag;

TAG_CLOSE: '>' -> popMode;
TAG_SLASH_CLOSE: '/>' -> popMode;
TAG_SLASH: '/';
TAG_EQUALS: '=' -> pushMode(attrValue);
TAG_NAME: TagNameStartChar TagNameChar*;
Tag_NEWLINE
    : '\r'? '\n' {setAfterNewline();} -> pushMode(startOfLine), type(NEWLINE)
    ;
TAG_WHITESPACE:  [ \t]+ -> type(WS), channel(WHITESPACES);

fragment TagNameChar:
    TagNameStartChar
    | '-'
    | '_'
    | '.'
    | DIGIT
    | '\u00B7'
    | '\u0300' ..'\u036F'
    | '\u203F' ..'\u2040'
;

fragment TagNameStartChar:
    [:a-zA-Z]
    | '\u2070' ..'\u218F'
    | '\u2C00' ..'\u2FEF'
    | '\u3001' ..'\uD7FF'
    | '\uF900' ..'\uFDCF'
    | '\uFDF0' ..'\uFFFD'
;

fragment DIGIT: [0-9];

mode attrValue;

ATTRIBUTE_VALUE: ' '* ATTRIBUTE -> popMode;

ATTRIBUTE: DOUBLE_QUOTE_STRING | SINGLE_QUOTE_STRING | ATTCHARS | HEXCHARS | DECCHARS;

fragment ATTCHARS: ATTCHAR+ ' '?;

fragment ATTCHAR: '-' | '_' | '.' | '/' | '+' | ',' | '?' | '=' | ':' | ';' | '#' | [0-9a-zA-Z];

fragment HEXCHARS: '#' [0-9a-fA-F]+;

fragment DECCHARS: [0-9]+ '%'?;

fragment DOUBLE_QUOTE_STRING: '"' ~[<"]* '"';

fragment SINGLE_QUOTE_STRING: '\'' ~[<']* '\'';
