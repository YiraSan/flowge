namespace Flowge.Primary {

    public struct Word {
        public string[] Match { get; set; }
        public bool Optional { get; set; }
        public bool IfLast { get; set; }
        public static Word Build(string[] args, bool optional, bool IfLast)
        {
            Word word = new Word();
            word.Match = args;
            word.Optional = optional;
            word.IfLast = IfLast;
            return word;
        }
    }

}