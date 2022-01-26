namespace Flowge.Grammar 
{

    public sealed class FlowgeGrammar
    {

        private Dictionary<string, Expression[]> words = new Dictionary<string, Expression[]>();

        private void GetExported()
        {
            // todo
        }

        private bool ParseLine(string[] exprs)
        {

            bool isGlobal = exprs[0].StartsWith("@");
            string name = exprs[0].Substring(1);



            return true;

        }

        public bool LoadGrammar(string path)
        {

            if (!path.EndsWith(".fgc"))
            {
                path = path + ".fgc";
            }

            string fileContent = File.ReadAllText(path);

            string[] Lines = fileContent.Split("\n");

            for (int i = 0; i < Lines.Length; i++)
            {

                // supress white space
                string[] Line = Lines[i].Trim().Split(" ").Where(c=>!c.Equals("")).ToArray();

                if (Line.Length==0) continue;
                if (Line[0].StartsWith("$"))
                {
                    if (Line[0].Equals("$import"))
                    {
                        Console.WriteLine("Uniplemented Command 'import'");
                    }
                    else
                    {
                        Console.WriteLine($"[FlowgeGrammar] Invalid command: '{Line[0]}'");
                        return false;
                    }
                }
                else if (Line[0].StartsWith(":")||Line[0].StartsWith("@"))
                {
                    if (this.ParseLine(Line)==false)
                    {
                        return false;
                    }
                }

            }

            return false;

        }

    }

}