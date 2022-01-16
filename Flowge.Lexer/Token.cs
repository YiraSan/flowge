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

    public abstract class Token 
    {
        public uint Id;
        public TextPosition Begin;
        public TextPosition End;
        public Token(uint Id, TextPosition Begin, TextPosition End)
        {
            this.Id = Id;
            this.Begin = Begin;
            this.End = End;
        }
    }

    public class ChunkToken : Token
    {
        public Token[] Tokens;
        public ChunkToken(uint Id, TextPosition Begin, TextPosition End, Token[] Tokens) 
        : base(Id, Begin, End)
        {
            this.Tokens = Tokens;
        }
    }

    public class UntilToken : Token
    {
        public Token[] Tokens;
        public UntilToken(uint Id, TextPosition Begin, TextPosition End, Token[] Tokens) 
        : base(Id, Begin, End)
        {
            this.Tokens = Tokens;
        }
    }

    public class CharToken : Token
    {
        public char Char;
        public CharToken(uint Id, TextPosition Begin, TextPosition End, char Char) 
        : base(Id, Begin, End)
        {
            this.Char = Char;
        }
    }

}