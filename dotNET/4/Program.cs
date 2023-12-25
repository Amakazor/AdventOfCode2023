using System.Runtime.CompilerServices;

var lines = File.ReadAllLines("input.txt");
var cards = lines.Select(Scratchcard.Parse).ToList();
foreach (var card in cards) foreach (var newId in Enumerable.Range(card.Id, card.WinningAmount))
{
    if (cards.Count > newId) cards[newId].Count += card.Count;
} 


Console.WriteLine(cards.Sum(card => card.Points));
Console.WriteLine(cards.Sum(card => card.Count));

static class Util
{
    public static bool NotEmptyString(string str) => str != "";
}

record class Scratchcard(int Id, HashSet<int> WinningNumbers, HashSet<int> Numbers, int Count = 1)
{
    public int Count { get; set; } = Count;

    public int WinningAmount => Numbers.Intersect(WinningNumbers).Count();
    public int Points => WinningAmount > 0 ? 1 << (WinningAmount - 1) : 0;

    public static Scratchcard Parse(string data)
    {
        #pragma warning disable S3220
        var parts = data.Split(':', '|');
        #pragma warning restore S3220
        var id = int.Parse(parts[0].Split(' ')[^1]);
        var winning = parts[1].Split(' ').Where(Util.NotEmptyString).Select(int.Parse).ToHashSet();
        var numbers = parts[2].Split(' ').Where(Util.NotEmptyString).Select(int.Parse).ToHashSet();

        return new Scratchcard(id, winning, numbers);
    }
}