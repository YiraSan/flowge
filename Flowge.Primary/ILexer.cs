namespace Flowge.Primary {

    public interface ILexer {
        void Add(Expression expression, LexerRunnable runnable);
        void Remove(Expression expression);
        void Run(string text);
    }

}