namespace Flowge.Primary {
    
    public struct TokenPosition {
        public int Columns { get; set; }
        public int Lines { get; set; }
    }

    public struct Token {
        public string Content { get; set; }
        public TokenPosition Begin { get; set; }
        public TokenPosition End { get; set; }
    }

}