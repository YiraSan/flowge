namespace Flowge.Lexing {

    public sealed class Lexer {

        private string CurrentValue = ".hello world!";

        private uint Column = 1;
        private uint Line = 1;
        private int Index = 0;

        private Entry[] Entries = new Entry[] {
            new UntilEntry('\'', true),
        };

        public Lexer()
        {

        }

        public Lexer(Entry[] Entries)
        {
            this.Entries = Entries;
        }

        public void Set(string NewValue)
        {
            this.CurrentValue = NewValue;
            this.Column = 1;
            this.Line = 1;
            this.Index = 0;
        }

        public Token Next()
        {

            if (this.Index > this.CurrentValue.Length-1)
            {
                TextPosition end = new TextPosition(this.Column, this.Line);
                return new EndSequenceToken(-2, end, end);
            }

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

            for (uint i = 0; i < this.Entries.Length; i++)
            {

                if (typeof(CharEntry).IsInstanceOfType(this.Entries[i]))
                {
                    if (this.CurrentValue[this.Index].Equals(((CharEntry) this.Entries[i]).Char)){
                        this.Index++;
                        this.Column++;
                        return new CharToken((int) this.Entries[i].Id, Begin, new TextPosition(this.Column, this.Line), this.CurrentValue[this.Index-1]);
                    }
                }
                else if (typeof(UntilEntry).IsInstanceOfType(this.Entries[i]))
                {

                    UntilEntry entry = (UntilEntry) this.Entries[i];

                    if (this.CurrentValue[this.Index].Equals(entry.BeginEnd))
                    {

                        int Temp = this.Index+1;
                        string Segment = "";

                        uint NL = this.Line;
                        uint NC = this.Column;

                        while (true)
                        {
                            if (Temp >= this.CurrentValue.Length)
                            {
                                break;
                            } 
                            else  if (this.CurrentValue[Temp].Equals(entry.BeginEnd))
                            {
                                this.Column = NC;
                                this.Line = NL;
                                this.Index = Temp+1;
                                return new UntilToken((int) entry.Id, Begin, new TextPosition(this.Column, this.Line), Segment);
                            } 
                            else if (this.CurrentValue[Temp].Equals('\n'))
                            {
                                if (entry.SupportBreakLines==false)
                                {
                                    break;
                                } else {
                                    Segment += '\n';
                                    NL++;
                                    NC=1;
                                    Temp++;
                                    continue;
                                }
                            }

                            Segment += this.CurrentValue[Temp];
                            NC++;
                            Temp++;
            
                        }

                    }

                }
                else if (typeof(RegularEntry).IsInstanceOfType(this.Entries[i]))
                {
                    RegularEntry entry = (RegularEntry) this.Entries[i];
                    if (entry.Chars.Contains(this.CurrentValue[this.Index]))
                    {
                        int Temp = this.Index+1;
                        uint NL = this.Line;
                        uint NC = this.Column;
                        string segment = ""+this.CurrentValue[this.Index];
                        while(true)
                        {
                            if (Temp >= this.CurrentValue.Length||!entry.Chars.Contains(this.CurrentValue[Temp]))
                            {
                                this.Line = NL;
                                this.Column = NC;
                                this.Index = Temp;
                                return new RegularToken((int) entry.Id, Begin, new TextPosition(this.Column, this.Line), segment);
                            } 
                            else if (this.CurrentValue[Temp].Equals('\n'))
                            {
                                segment += "\n";
                                NL++;
                                Temp++;
                                NC=1;
                            }
                            else if (entry.Chars.Contains(this.CurrentValue[Temp]))
                            {
                                segment += this.CurrentValue[Temp];
                                Temp++;
                                NC++;
                            }
                        }
                    }
                    
                }

            }

            // When unexpected
            return new UnexpectedToken(-1, Begin, new TextPosition(this.Column+1, this.Line));

        }



    }

}