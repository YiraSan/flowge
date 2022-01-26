namespace Flowge.Grammar
{

    public class Expression
    {

        public List<Section> sections = new List<Section>();

        public bool isGlobal { get; }

        public Expression(bool isGlobal)
        {
            this.isGlobal = isGlobal;
        }

    }

}