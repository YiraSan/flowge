namespace Flowge.Lexer {

    public struct TextPosition
    {
        public TextPosition(uint? Column, uint? Line)
        {
            this.Column = Column != null ? (uint) Column : 1;
            this.Line = Line != null ? (uint) Line : 1;
        }
        public uint Column { get; }
        public uint Line { get; }
    }    

    public class Token 
    {
        public TextPosition Begin;
        public TextPosition End;
        public Token(TextPosition Begin, TextPosition End)
        {
            this.Begin = Begin;
            this.End = End;
        }
    }

    public class ChunkToken : Token
    {
        public Token[] Tokens;
        public ChunkToken(TextPosition Begin, TextPosition End, Token[] Tokens) : base(Begin, End)
        {
            this.Tokens = Tokens;
        }
    }

    public class UntilToken : Token
    {
        public Token[] Tokens;
        public UntilToken(TextPosition Begin, TextPosition End, Token[] Tokens) : base(Begin, End)
        {
            this.Tokens = Tokens;
        }
    }

    public class CharToken : Token
    {
        public char Char;
        public CharToken(TextPosition Begin, TextPosition End, char Char) : base(Begin, End)
        {
            this.Char = Char;
        }
    }

}