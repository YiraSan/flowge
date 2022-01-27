using Flowge.Tools;
using Flowge.Lexing;

namespace Flowge.Grammar 
{

    public sealed class FlowgeGrammar
    {

        private Dictionary<string, Expression[]> words = new Dictionary<string, Expression[]>();

        private void GetExported()
        {
            // todo
        }

        private static List<Entry> Segment(string from)
        {

            from = from.Trim();

            List<Entry> result = new List<Entry>();

            string current = "";

            if (from[0].Equals('(')) {
                for (int i = 1; i < from.Length; i++)
                {
                    if (from[i].Equals(')')){
                        result.Add(new Entry(current, false));
                        result = (List<Entry>) result.Concat(Segment(String.Join("", from.Skip(i)))).ToList();
                        break;
                    }
                    current += from[i];
                }
            }
            else
            {
                for (int i = 0; i < from.Length; i++)
                {
                    if (from[i].Equals(')'))
                    {
                        continue;
                    }
                    if (from[i].Equals('(')){
                        result.Add(new Entry(current, true));
                        result = (List<Entry>) result.Concat(Segment(String.Join("", from.Skip(i)))).ToList();
                        break;
                    }
                    current += from[i];
                    if (i == from.Length-1&&!current.Equals(""))
                    {
                        result.Add(new Entry(current, true));
                    }
                }
            }

            return result;

        }

        private bool ParseLine(string[] exprs)
        {

            bool isGlobal = exprs[0].StartsWith("@");
            string name = exprs[0].Substring(1);

            string[] expressions = String.Join("", exprs.Skip(1)).Split(",");

            Lexer grammarLexer = new Lexer(new LexerEntry[]{

                // keyword
                new UntilEntry('\'', '\'', false),

                // reference
                (RegularEntry) "abcdefghijklmnopqrstuvwxyzABDEFGHIJKLMNOPQRSTUVWXYZ_",
                (CharEntry) '.',
                (CharEntry) '&',
 
            });

            // expression: pre build
            for (int i = 0; i < expressions.Length; i++)
            {

                List<Entry> segmented = Segment(expressions[i]);

                List<Section> sections = new List<Section>();

                for (int e = 0; e < segmented.Count; e++)
                {

                    Section section = new Section(segmented[e].Required);

                    grammarLexer.Set((string) segmented[e].Content);

                    Token[] tokens = grammarLexer.Skip();

                    Array.ForEach(tokens, c=>Console.WriteLine(c.getType()));

                    sections.Add(section);

                    Console.WriteLine();

                }

            }

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