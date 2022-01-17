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
        public WordGroup[] Groups { get; }
        public Word(WordType type, WordGroup[] groups)
        {
            this.Type = type;
            this.Groups = groups;
        }
    }

    public enum WordGroupType
    {
        OPTIONAL,
        REQUIRED,
    }

    public class WordGroup
    {
        public WordGroupType Type { get; }
        public WordContent[] Contents { get; }
        public WordGroup(WordContent[] wordContents, WordGroupType type)
        {
            this.Contents = wordContents;
            this.Type = type;
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