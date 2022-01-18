namespace Flowge.Grammar
{

    public enum WordType
    {
        LOCAL,
        EXPORTED,
    }

    public class Word
    {
        public WordType Type { get; }
        public WordContent[] Contents { get; }
        public Word(WordType type, WordContent[] contents)
        {
            this.Type = type;
            this.Contents = contents;
        }
    }

    public enum WordContentType
    {
        REFERENCE,
        KEY_WORD,
    }

    public class WordContent
    {
        public WordContentType Type { get; }
        public string Content { get; }
        public WordContent(string content, WordContentType type)
        {
            this.Content = content;
            this.Type = type;
        }
    }

}