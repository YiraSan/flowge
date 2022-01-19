namespace Flowge.Math
{

    public class Entry
    {
        public Object Content { get; }
        public bool Required { get; }
        public Entry(Object content, bool required)
        {
            this.Content = content;
            this.Required = required;
        }
    }

    public class IndexedEntry
    {
        public int Index { get; }
        public Object Content { get; }
        public IndexedEntry(Object content, int index){
            this.Content = content;
            this.Index = index;
        }
    }

    public static class Possibility
    {

        public static object[][] GetCombs(object[] objects)
        {

            List<object[]> Resp = new List<object[]>();
            
            int Length = objects.Length;
            int Total = (1 << Length);

            for (int i = 0; i < Total; i++)
            {
                List<object> Temp = new List<object>();
                for (int k = 0; k < Length; k++)
                {
                    if ((i & (1 << k))!=0)
                    {
                        Temp.Add(objects[k]);
                    }
                }
                Resp.Add(Temp.ToArray());
            }

            return (object[][]) (Resp.Where(c=>c.Length>0).ToArray());

        }

        public static object[][] GetOptions(Entry[] entries)
        {
 
            List<IndexedEntry> required = new List<IndexedEntry>();
            List<IndexedEntry> optional = new List<IndexedEntry>();

            for (int i = 0; i < entries.Length; i++)
            {
                IndexedEntry entry = new IndexedEntry(entries[i].Content, i);
                if (entries[i].Required)
                {
                    required.Add(entry);
                }
                else 
                {
                    optional.Add(entry);
                }
            }

            List<object[]> Result = new List<object[]>();
            if (((IndexedEntry[]) required.ToArray()).Length>0)
            {
                Result.Add((object[]) required.Select(c=>c.Content).ToArray());
            }
            
            object[][] poss = Possibility.GetCombs(optional.ToArray());

            for (int i = 0; i < poss.Length; i++)
            {
                object[] entr = poss[i];
                List<IndexedEntry> entrs = new List<IndexedEntry>();
                for (int k = 0; k < entr.Length; k++)
                {
                    IndexedEntry entry = (IndexedEntry) entr[k];
                    entrs.Add(entry);
                }
                Result.Add((object[]) entrs.Concat(required).OrderBy(c=>c.Index).Select(c=>c.Content).ToArray());
            }

            return (object[][]) Result.ToArray();

        }

    }

}