using Flowge.Lexer;

namespace Flowge.Parser
{

    public class ParseReturn
    {

        public bool Successful { get; }
        public Token[] Tokens { get; }

        public ParseReturn(bool successful, Token[] tokens)
        {
            this.Successful = successful;
            this.Tokens = tokens;
        }

    }

}