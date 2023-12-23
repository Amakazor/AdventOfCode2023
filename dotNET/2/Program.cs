// See https://aka.ms/new-console-template for more information


using System.Linq;

var lines = File.ReadAllLines("test_input_1.txt");

var games = lines
    .Select(line => line.Split(": "))
    .Select(parts => new { Id = parts[0].Split(' ')[^1], Rounds = parts[1].Split("; ").Select(round => new Round(round)) })
    .Select(parts => new Game(int.Parse(parts.Id), parts.Rounds));

Console.WriteLine(games.Where(game => game.CanFitInRound(new Round() { Red = 12, Green = 13, Blue = 14 })).Sum(game => game.Id));
Console.WriteLine(games.Sum(game => game.SmallestPossibleRound.Power));

public struct Game
{
    public int Id { get; set; }
    List<Round> Rounds { get; set; } = new();

    public Game(int id, IEnumerable<Round> rounds)
    {
        Id = id;
        Rounds = rounds.ToList();
    }

    public readonly bool CanFitInRound(Round other)
    {
        return Rounds.TrueForAll(round => round.CanFitIn(other));
    }

    public readonly Round SmallestPossibleRound => Rounds.Aggregate((acc, round) => {
        acc.Red = Math.Max(acc.Red, round.Red);
        acc.Green = Math.Max(acc.Green, round.Green);
        acc.Blue = Math.Max(acc.Blue, round.Blue);

        return acc;
    });
}

public struct Round
{
    public int Red { get; set; }
    public int Green { get; set; }
    public int Blue { get; set; }

    public readonly bool CanFitIn(Round other)
    {
        return other.Red >= Red && other.Green >= Green && other.Blue >= Blue;
    }

    public Round()
    {
        Red = 0;
        Green = 0;
        Blue = 0;
    }

    public Round(string data)
    {
        var red = 0;
        var green = 0;
        var blue = 0;

        var parts = data.Split(", ");
        parts.ToList().ForEach(part =>
        {
            if (part.EndsWith("red")) red = int.Parse(part.Split(' ')[0]);
            if (part.EndsWith("green")) green = int.Parse(part.Split(' ')[0]);
            if (part.EndsWith("blue")) blue = int.Parse(part.Split(' ')[0]);
        });

        Red = red;
        Green = green;
        Blue = blue;
    }

    public readonly int Power => Red * Green * Blue;
}
