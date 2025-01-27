package chapi.ast.antlr;

import chapi.ast.antlr.CSharpParser;
import org.antlr.v4.runtime.Parser;
import org.antlr.v4.runtime.TokenStream;

public abstract class CSharpParserBase extends Parser {
    protected CSharpParserBase(TokenStream input) {
        super(input);
    }

    protected boolean IsLocalVariableDeclaration() {
        CSharpParser.Local_variable_declarationContext local_var_decl = (CSharpParser.Local_variable_declarationContext) this._ctx;
        if (local_var_decl == null) {
			return true;
		}
        CSharpParser.Local_variable_typeContext local_variable_type = local_var_decl.local_variable_type();
        if (local_variable_type == null) {
			return true;
		}
        if (local_variable_type.getText().equals("var")) {
			return false;
		}
        return true;
    }
}
