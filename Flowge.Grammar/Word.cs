namespace Flowge.Grammar
{

    public enum WordKind
    {
        REFERENCE,
        KEYWORD,
    }

    public class Word
    {

        public WordKind wordKind { get; }
        public string content { get; }

        public Word(string content, WordKind wordKind)
        {
            this.content = content;
            this.wordKind = wordKind;
        }

    }

}