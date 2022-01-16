namespace Flowge.Lexer 
{

    public interface Entry 
    {
        bool SupportBreakLines { get; }
    }

    public struct ChunkEntry : Entry
    {
        public bool SupportBreakLines { get; set; }
        public char Begin { get; set; }
        public char End { get; set; }
    }

    public struct UntilEntry : Entry
    {
        public bool SupportBreakLines { get; set; }
        public string BeginEnd { get; set; }
        public bool ReturnAsString { get; set; }
    }

    public struct RegularEntry : Entry
    {
        public bool SupportBreakLines { get; set; }
        public char[] Chars { get; set; }
        public static RegularEntry New(char[] Chars, bool SBL)
        {
            RegularEntry entry = new RegularEntry();
            entry.SupportBreakLines = SBL;
            entry.Chars = Chars;
            return entry;
        }
        public static RegularEntry New(string chrs, bool SBL)
        {
            char[] chars = new char[]{};
            foreach (var chr in chrs)
            {
                chars.Append(chr);
            }
            return New(chars, SBL);
        }
        public static implicit operator RegularEntry(string str) => New(str, false);
        public static implicit operator RegularEntry(char[] chrs) => New(chrs, false);
    }

    public struct CharEntry : Entry
    {
        public bool SupportBreakLines { get; set; }
        public char KeyChar { get; set; }
        public static CharEntry New(char KeyChar)
        {
            CharEntry entry = new CharEntry();
            entry.SupportBreakLines = false;
            entry.KeyChar = KeyChar;
            return entry;
        }
        public static implicit operator CharEntry(char Char) => New(Char);
    }

}