using Flowge.Lexing;
using Flowge.Primary;

namespace Flowge.Parsers {

    public class TestParser : Lexer {

        public TestParser() : base() 
        {
            this.init();
        }

        private void init()
        {
            Expression expression = new Expression();
            expression.Words = new Word[] {Word.Build(new string[]{"test"}, false, false)};
            this.Add(expression, new TestMatch());
        }

        private class TestMatch : LexerRunnable {

            public void OnMatch(Token[] tokens){
                
            }

        }

    }

}