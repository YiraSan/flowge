using Flowge.Lexer;

namespace Flowge.Parser {

    public class FileParser 
    {

        private Lexer.Lexer lexer = new Lexer.Lexer(new Entry[]{
            /** character **/
            (CharEntry) ' ', // white space
            (CharEntry) '.', // dot
            (CharEntry) '!', // exclamation mark
            (CharEntry) '?', // interogation mark
            (CharEntry) '=', // equal
            (CharEntry) '*', // star
            (CharEntry) '+', // plus
            (CharEntry) '/', // slash
            (CharEntry) '_', // underscore
            (CharEntry) '-', // dash
            (CharEntry) '%', // percentage
            (CharEntry) ',', // period
            (CharEntry) '#', // hash
            (CharEntry) ':', // colon
            (CharEntry) ';', // semicolon 
            /** alphanumeric **/
            (RegularEntry) "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", // alpha
            (RegularEntry) "0123456789", // numeric
            /** string **/
            new UntilEntry('"', false),
            new UntilEntry('\'', false), 
            new UntilEntry('`', true), 
        });

        private ParseReturn parse()
        {
            
            Token token = this.lexer.Next();

            if (token.getType()==TokenType.CHAR)
            {

                CharToken charToken = (CharToken) token;

                // skip white space
                if (charToken.Char.Equals(' ')) 
                {
                    return this.parse();
                }

            }
            else if (token.getType()==TokenType.REGULAR)
            {

                RegularToken regularToken = (RegularToken) token;
                
                if (regularToken.Content.Equals("import"))
                {

                    

                    return this.parse();

                }

            }

            // Unexpected Token
            return new ParseReturn(false, new Token[]{token});

        }

        public ParseReturn parse(string text)
        {
            this.lexer.Set(text);
            return this.parse();
        }

    }

}