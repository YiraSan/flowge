namespace Flowge.Grammar 
{

    public sealed class FlowgeGrammar
    {

        private Dictionary<string, Word[]> words = new Dictionary<string, Word[]>();

        private void GetExported()
        {

        }

        // analyzing

        private bool ParseWord(string[] Exprs)
        {

            bool IsGlobal = Exprs[0].StartsWith("@");
            string Name = Exprs[0].Substring(1);

            List<WordGroup> wordGroups = new List<WordGroup>();

            for (int e = 1; e < Exprs.Length; e++)
            {
                for (int ei = 0; ei < Exprs[e].Length; ei++)
                {
                    if (Exprs[e][ei].Equals('('))
                    {

                        string stored = "";


                        while ()
                        {
                            
                        }

                        // todo
                        new WordGroup(null, WordGroupType.OPTIONAL);

                    }
                    // Next Word
                    else if (Exprs[e][ei].Equals(','))
                    {

                    }
                    // KeyWord
                    else if (Exprs[e][ei].Equals('\''))
                    {

                    }
                    // Reference
                    else 
                    {

                    }
                }
            }

            return true;

        }

        public bool LoadGrammar(string path)
        {
            string file = File.ReadAllText(path+".fgc");
            string[] Lines = file.Split("\n");
            for (int i = 0; i < Lines.Length; i++)
            {
                string[] Line = Lines[i].Trim().Split(" ").Where(c=>!c.Equals("")).ToArray();
                if (Line.Length==0) continue;
                if (Line[0].StartsWith("$"))
                {
                    if (Line[0].Equals("$import"))
                    {
                        Console.WriteLine("Uniplemented Function 'import'");
                    }
                    else
                    {
                        Console.WriteLine($"[FlowgeGrammar] Invalid command: '{Line[0]}'");
                        return false;
                    }
                }
                else if (Line[0].StartsWith(":")||Line[0].StartsWith("@"))
                {
                    if (this.ParseWord(Line)==false)
                    {
                        return false;
                    }
                }
            }
            return false;
        }

    }

}