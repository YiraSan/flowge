using Flowge.Primary;

namespace Flowge.Lexing {

    public struct RunContext {
        public int Lines { get; set; }
        public int Columns { get; set; }
        public string Text { get; set; }
    }

    public class Lexer : ILexer {

        Root[] roots = new Root[]{};
        
        private struct Root {
            public Expression expression;
            public LexerRunnable runnable;
            public static Root Build(Expression expression, LexerRunnable runnable){
                Root root = new Root();
                root.expression = expression;
                root.runnable = runnable;
                return root;
            }
        }

        public void Add(Expression expression, LexerRunnable runnable)
        {
            this.roots.Append(Root.Build(expression, runnable));
        }

        public void Remove(Expression expression)
        {
            this.roots = (Root[]) this.roots.Where(c=>!c.Equals(expression));
        }

        private void Next(RunContext Context)
        {

            int to = Context.Columns+Context.Lines-2;
            int from = Context.Text.Substring(to).IndexOf(" ");

            if (from==-1) { from = Context.Text.Length; }

            // Note: The loop is in the opposite sense, for concurrent word match.
            for (int i = from; i > 0; i--)
            {

                string txt = Context.Text.Substring(to, i);

                Console.WriteLine(txt);

                foreach (var item in this.roots) 
                {

                    bool caught;

                    foreach (var word in item.expression.Words)
                    {

                        Console.WriteLine(String.Join(",", word.Match));

                        if (word.Match.Contains(txt)) {
                            Console.WriteLine(txt);
                        }

                        break;

                    }

                    // Here: Caught by this expression

                    // todo

                }

            }

            // Here: Unexpected Token :(

            // todo

        }

        public void Run(string text)
        {
            RunContext context = new RunContext();
            context.Lines = 1;
            context.Columns = 1;
            context.Text = text;
            this.Next(context);
        }

    }

}