import org.antlr.v4.runtime.CharStream;
import org.antlr.v4.runtime.CommonToken;
import org.antlr.v4.runtime.Token;
import org.antlr.v4.runtime.TokenSource;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

public class AstTest extends AbstractTestSupport {
    @Override
    protected String getPackageLocation() {
        return "";
    }

    @Test
    public void testEmpty() throws IOException {
        verifyAst(getPath("empty.txt"), getPath("empty.javadoc"));
    }

    @Test
    public void testJavadocWithText() throws IOException {
        verifyAst(getPath("text.txt"), getPath("text.javadoc"));
    }

    @Test
    public void testJavadocWithText2() throws IOException {
        verifyAst(getPath("text2.txt"), getPath("text2.javadoc"));
    }

    @Test
    public void testSpecialCharacter() throws IOException {
    verifyAst(getPath("specialCharacter.txt"), getPath("specialCharacter.javadoc"));
    }

    @Test
    public void testInlineCodeTag1() throws IOException {
        verifyAst(getPath("inline1.txt"), getPath("inline1.javadoc"));
    }

    @Test
    public void testInlineCodeTag2() throws IOException {
        verifyAst(getPath("inline2.txt"), getPath("inline2.javadoc"));
    }

    @Test
    public void testInlineLinkTag1() throws IOException {
        verifyAst(getPath("inlineLink1.txt"), getPath("inlineLink1.javadoc"));
    }

    @Test
    public void testInlineLinkTag2() throws IOException {
        verifyAst(getPath("inlineLink2.txt"), getPath("inlineLink2.javadoc"));
    }

    @Test
    public void testInlineLinkTag3() throws IOException {
        verifyAst(getPath("inlineLink3.txt"), getPath("inlineLink3.javadoc"));
    }

    @Test
    public void testBlockAuthorTag() throws IOException {
        verifyAst(getPath("blockAuthor.txt"), getPath("blockAuthor.javadoc"));
    }

    @Test
    public void testBlockReturnTag() throws IOException {
        verifyAst(getPath("blockReturn.txt"), getPath("blockReturn.javadoc"));
    }

    @Test
    public void testBlockParamTag() throws IOException {
        verifyAst(getPath("blockParam.txt"), getPath("blockParam.javadoc"));
    }

    @Test
    public void testHTML1() throws IOException {
        verifyAst(getPath("html1.txt"), getPath("html1.javadoc"));
    }

    @Test
    public void testHTML2() throws IOException {
        verifyAst(getPath("html2.txt"), getPath("html2.javadoc"));
    }

    @Test
    public void testVoidTags() throws IOException {
        verifyAst(getPath("htmlVoidTags1.txt"), getPath("htmlVoidTags1.javadoc"));
    }

    @Test
    public void testNonTightTags() throws IOException {
        final List<Token> expectedNonTightTags = List.of(
                getTagNameToken(7, 43, "p", 2, 3),
                getTagNameToken(29, 118, "li", 7, 5),
                getTagNameToken(36, 138, "li", 8, 5)

        );
        verifyAst(getPath("htmlNonTight1.txt"), getPath("htmlNonTight1.javadoc"), expectedNonTightTags);
    }

    private static Token getTagNameToken(
            int tokenIndex,
            int startIndex,
            String text,
            int line,
            int charPositionInLine)  {
        final CommonToken t = new CommonToken(JavadocLexer.TAG_NAME);
        t.setLine(line);
        t.setCharPositionInLine(charPositionInLine);
        t.setText(text);
        t.setStartIndex(startIndex);
        t.setStopIndex(startIndex + text.length() -1);
        t.setTokenIndex(tokenIndex);
        return t;
    }


}
