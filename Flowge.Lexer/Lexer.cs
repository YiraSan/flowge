namespace Flowge.Lexer {

    public class Lexer {

        private string CurrentValue = ".hello world!";

        private uint Column = 1;
        private uint Line = 1;
        private int Index = 0;

        private Entry[] entries = new Entry[] {
            (CharEntry) ' ',
            (CharEntry) '.',
        };

        public void Set(string NewValue)
        {
            this.CurrentValue = NewValue;
            this.Column = 1;
            this.Line = 1;
            this.Index = 0;
        }

        public Token? Next()
        {

            if (this.CurrentValue[this.Index].Equals('\n'))
            {
                this.Line++;
                this.Column = 1;
                this.Index++;
                return this.Next();
            }
            else if (this.CurrentValue[this.Index].Equals('\r')) 
            {
                this.Index++;
                return this.Next();
            }

            TextPosition Begin = new TextPosition(this.Column, this.Line);

            for (uint i = 0; i < this.entries.Length; i++)
            {

                if (typeof(CharEntry).IsInstanceOfType(this.entries[i]))
                {
                    if (this.CurrentValue[this.Index].Equals(((CharEntry) this.entries[i]).Char)){
                        this.Index++;
                        this.Column++;
                        return new CharToken(this.entries[i].Id, Begin, new TextPosition(this.Column, this.Line), this.CurrentValue[this.Index-1]);
                    }
                }
                else if (typeof(UntilEntry).IsInstanceOfType(this.entries[i]))
                {

                    UntilEntry entry = (UntilEntry) this.entries[i];

                    if (this.CurrentValue[this.Index].Equals(entry.BeginEnd))
                    {

                        int temp = this.Index+1;
                        bool valid = false;
                        string segment = "";

                        while (true)
                        {
                            segment += this.CurrentValue[temp];
                            temp++;
                            if (temp >= this.CurrentValue.Length)
                            {
                                break;
                            }
                            else if (this.CurrentValue[temp].Equals(entry.BeginEnd))
                            {
                                valid = true;
                            }
                        }

                        if (valid)
                        {



                        }

                    }

                }

            }

            // When unexpected
            return null;

        }

    }

}