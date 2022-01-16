namespace Flowge.Lexer 
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

    public abstract class Entry 
    {
        public bool SupportBreakLines { get; }
        public uint Id { get; }
        public Entry(bool SupportBreakLines)
        {
            this.SupportBreakLines = SupportBreakLines;
            this.Id = LinkIds.NewId();
        }
    }

    public class ChunkEntry : Entry
    {
        public char Begin { get; }
        public char End { get; }
        public ChunkEntry(char Begin, char End, bool SupportBreakLines)
        : base(SupportBreakLines)
        {
            this.Begin = Begin;
            this.End = End;
        }
    }

    public class UntilEntry : Entry
    {
        public char BeginEnd { get; }
        public UntilEntry(char BeginEnd, bool SupportBreakLines)
        : base(SupportBreakLines)
        {
            this.BeginEnd = BeginEnd;
        }
    }

    public class RegularEntry : Entry
    {
        public char[] Chars { get; }

        public RegularEntry(char[] Chars, bool SupportBreakLines)
        : base(SupportBreakLines)
        {
            this.Chars = Chars;
        }

        public RegularEntry(string chrs, bool SupportBreakLines)
        : base(SupportBreakLines)
        {
            this.Chars = new char[]{};
            foreach (var chr in chrs)
            {
                this.Chars.Append(chr);
            }
        }

        public static implicit operator RegularEntry(string str) => new(str, false);
        public static implicit operator RegularEntry(char[] chrs) => new(chrs, false);
    }

    public class CharEntry : Entry
    {
        public char Char { get; set; }
        public CharEntry(char Char, bool SupportBreakLines)
        : base(SupportBreakLines)
        {
            this.Char = Char;
        }
        public static implicit operator CharEntry(char Char) => new(Char, false);
    }

}