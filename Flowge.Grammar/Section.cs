namespace Flowge.Grammar
{

    public class Section
    {

        public bool isRequired { get; }

        public List<Word> words = new List<Word>();

        public Section(bool isRequired)
        {
            this.isRequired = isRequired;
        }

    }

}