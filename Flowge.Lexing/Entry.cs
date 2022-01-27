namespace Flowge.Lexing 
{

    public static class LinkIds
    {
        private static uint Id = 0;
        public static uint NewId()
        {
            Id++;
            return Id-1;
        }
    }

    public abstract class LexerEntry 
    {
        public bool SupportBreakLines { get; }
        public uint Id { get; }
        public LexerEntry(bool SupportBreakLines)
        {
            this.SupportBreakLines = SupportBreakLines;
            this.Id = LinkIds.NewId();
        }
    }

    public class UntilEntry : LexerEntry
    {
        public char Begin { get; }
        public char End { get; }
        public UntilEntry(char Begin, char End, bool SupportBreakLines)
        : base(SupportBreakLines)
        {
            this.Begin = Begin;
            this.End = End;
        }
    }

    public class RegularEntry : LexerEntry
    {
        public List<char> Chars { get; }

        public RegularEntry(List<char> chars, bool SupportBreakLines)
        : base(SupportBreakLines)
        {
            this.Chars = chars;
        }

        public RegularEntry(string chrs, bool SupportBreakLines)
        : base(SupportBreakLines)
        {
            this.Chars = new List<char>();
            for (int i = 0; i < chrs.Length; i++)
            {
                this.Chars.Add(chrs[i]);
            }
        }

        public static implicit operator RegularEntry(string str) => new(str, false);
        public static implicit operator RegularEntry(List<char> chrs) => new(chrs, false);
    }

    public class CharEntry : LexerEntry
    {
        public char Char { get; set; }
        public CharEntry(char Char)
        : base(false)
        {
            this.Char = Char;
        }
        public static implicit operator CharEntry(char Char) => new(Char);
    }

}