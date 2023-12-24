using System.Text.RegularExpressions;

var lines = File.ReadAllLines("input.txt");

var regex = new Regex("\\d+");

var matches = lines.Select(line => regex.Matches(line));
var parts = matches.SelectMany((match, index) => match.Select(matchInstance => new Part(index, matchInstance.Index, matchInstance.Length, int.Parse(matchInstance.Value), lines )));

var gears = new Dictionary<(int, int), Gear>();

foreach (var part in parts)
{
    foreach (var neighbor in part.Neighbors)
    {
        if (neighbor.Value == '*')
        {
            if (gears.TryGetValue((neighbor.Line, neighbor.Index), out Gear gear))
            {
                gear.AddNeighbor(part);
            } 
            else
            {
                gears.Add((neighbor.Line, neighbor.Index), new Gear(part));
            }
        }
    }
}

Console.WriteLine(parts.Where(part => part.HasNeighbor()).Sum(part => part.Value));
Console.WriteLine(gears.Values.Where(gear => gear.Neighbors.Count == 2).Sum(gear => gear.Ratio));


Console.WriteLine("Hello, World!");

struct Part
{
    public int Line { get; set; }
    public int Start { get; set; }
    public int Length { get; set; }
    public int Value { get; set; }
    public List<Symbol> Neighbors { get; } = [];

    public Part(int line, int start, int length, int value, IList<string> lines)
    {
        Line = line;
        Start = start;
        Length = length;
        Value = value;

        Neighbors = new int[] { -1, 0, 1 }
            .SelectMany(line_offset => Enumerable.Range(-1, length + 2).Select(column_offset => new { line = line + line_offset, column = start + column_offset }))
            .Where(offset => offset.line >= 0 && offset.line < lines.Count && offset.column >= 0 && offset.column < lines[offset.line].Length)
            .Select(offset => new Symbol { Index = offset.column, Line = offset.line, Value = lines[offset.line][offset.column] })
            .Where(symbol => symbol.Value != '.' && !char.IsNumber(symbol.Value))
            .ToList();
    }

    public readonly bool HasNeighbor() => Neighbors.Count != 0;
}

struct Symbol
{
    public int Line { get; set; }
    public int Index { get; set; }
    public char Value { get; set; }

    public override readonly string ToString()
    {
        return $"[{Line}:{Index}] {Value}";
    }
}

struct Gear
{
    public List<Part> Neighbors { get; } = [];

    public Gear(Part part) 
    {
        Neighbors.Add(part);
    }

    public readonly void AddNeighbor(Part part)
    {
        Neighbors.Add(part);
    }

    public readonly int Ratio => Neighbors.Aggregate(1, (acc, next) => acc * next.Value);
}