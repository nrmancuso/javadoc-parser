import org.antlr.v4.runtime.CommonToken;
import org.antlr.v4.runtime.Token;
import org.junit.jupiter.api.Assertions;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;

public abstract class AbstractTestSupport {

    // we are using positive lookahead here, to convert \r\n to \n
    // and \\r\\n to \\n (for parse tree dump files),
    // by replacing the full match with the empty string
    private static final String CR_FOLLOWED_BY_LF_REGEX = "(?x)\\\\r(?=\\\\n)|\\r(?=\\n)";

    protected static void verifyAst(String expectedAstPrintFilename, String actualJavadocFilename) throws IOException {
        final String expectedContents = readFile(expectedAstPrintFilename);
        final AstPrinter.ParseDetails parseDetails = AstPrinter.createAstString(actualJavadocFilename);
        final String actualContents = toLfLineEnding(parseDetails.ast());

        assertEquals(expectedContents, actualContents,
            "Generated AST should match AST from printed text file.");
    }

    protected static void verifyAst(String expectedAstPrintFilename, String actualJavadocFilename, List<Token> expectedNonTightTags) throws IOException {
        final String expectedContents = readFile(expectedAstPrintFilename);
        final AstPrinter.ParseDetails parseDetails = AstPrinter.createAstString(actualJavadocFilename);
        final String actualContents = toLfLineEnding(parseDetails.ast());
        assertTokensEqual(expectedNonTightTags, parseDetails.nonTightTags());

        assertEquals(expectedContents, actualContents,
                "Generated AST should match AST from printed text file.");
    }

    private static void assertTokensEqual(List<? extends Token> expected, List<? extends Token> actual) {
        assertEquals(expected.size(), actual.size(), "Token list size mismatch");
        for (int i = 0; i < expected.size(); i++) {
            Token e = expected.get(i);
            Token a = actual.get(i);
            assertEquals(e.getType(), a.getType(), "Token type mismatch at index " + i);
            assertEquals(e.getText(), a.getText(), "Token text mismatch at index " + i);
            assertEquals(e.getLine(), a.getLine(), "Token line mismatch at index " + i);
            assertEquals(e.getCharPositionInLine(), a.getCharPositionInLine(), "Token char position mismatch at index " + i);
            assertEquals(e.getStartIndex(), a.getStartIndex(), "Token start index mismatch at index " + i);
            assertEquals(e.getStopIndex(), a.getStopIndex(), "Token stop index mismatch at index " + i);
        }
    }




    /**
     * Returns canonical path for the file with the given file name.
     * The path is formed base on the root location.
     * This implementation uses 'src/test/resources/'
     * as a root location.
     *
     * @param filename file name.
     * @return canonical path for the file name.
     * @throws IOException if I/O exception occurs while forming the path.
     */
    protected final String getPath(String filename) throws IOException {
        return new File("src/" + getResourceLocation() + "/resources/" + getPackageLocation() + "/"
            + filename).getCanonicalPath();
    }

    /**
     * Returns the exact location for the package where the file is present.
     *
     * @return path for the package name for the file.
     */
    protected abstract String getPackageLocation();

    /**
     * Retrieves the name of the folder location for resources.
     *
     * @return The name of the folder.
     */
    protected String getResourceLocation() {
        return "test";
    }

    /**
     * Reads the contents of a file.
     *
     * @param filename the name of the file whose contents are to be read
     * @return contents of the file with all {@code \r\n} replaced by {@code \n}
     * @throws IOException if I/O exception occurs while reading
     */
    protected static String readFile(String filename) throws IOException {
        return toLfLineEnding(Files.readString(
            Paths.get(filename)));
    }

    protected static String toLfLineEnding(String text) {
        return text.replaceAll(CR_FOLLOWED_BY_LF_REGEX, "");
    }
}