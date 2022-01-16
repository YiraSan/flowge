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

    public enum TokenType
    {
        CHUNK,
        UNTIL,
        CHAR,
        END_SEQUENCE,
        UNEXPECTED,
        DEFAULT,
    }

    public abstract class Token 
    {
        public int Id;
        public TextPosition Begin;
        public TextPosition End;
        public Token(int Id, TextPosition Begin, TextPosition End)
        {
            this.Id = Id;
            this.Begin = Begin;
            this.End = End;
        }
        public virtual TokenType getType()
        {
            return TokenType.DEFAULT;
        }
    }

    public class ChunkToken : Token
    {
        public Token[] Tokens;
        public ChunkToken(int Id, TextPosition Begin, TextPosition End, Token[] Tokens) 
        : base(Id, Begin, End)
        {
            this.Tokens = Tokens;
        }
        public override TokenType getType() => TokenType.CHUNK;
    }

    public class UntilToken : Token
    {
        public string Content;
        public UntilToken(int Id, TextPosition Begin, TextPosition End, string Content) 
        : base(Id, Begin, End)
        {
            this.Content = Content;
        }
        public override TokenType getType() => TokenType.UNTIL;
    }

    public class CharToken : Token
    {
        public char Char;
        public CharToken(int Id, TextPosition Begin, TextPosition End, char Char) 
        : base(Id, Begin, End)
        {
            this.Char = Char;
        }
        public override TokenType getType() => TokenType.CHAR;
    }

    public class UnexpectedToken : Token
    {
        public UnexpectedToken(int Id, TextPosition Begin, TextPosition End) 
        : base(Id, Begin, End)
        {}
        public override TokenType getType() => TokenType.UNEXPECTED;
    }

    public class EndSequenceToken : Token
    {
        public EndSequenceToken(int Id, TextPosition Begin, TextPosition End) 
        : base(Id, Begin, End)
        {}
        public override TokenType getType() => TokenType.END_SEQUENCE;
    }

}