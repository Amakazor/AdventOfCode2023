using System.Linq;

var lines = File.ReadAllLines("input.txt");
var sections = new List<List<string>>();

var currentSection = new List<string>();
foreach (var line in lines)
{
    if (line == "")
    {
        sections.Add(currentSection);
        currentSection = [];
    }
    else if (line[^1] != ':') currentSection.Add(line);
}
sections.Add(currentSection);

var seeds = sections[0][0].Split(": ")[1].Split(' ').Select(long.Parse).ToList();

var mappings = Enumerable
    .Range(1, sections.Count - 1)
    .Select(sectionIndex => sections[sectionIndex])
    .Select(section => new Mapping(section))
    .ToList();

var locations = seeds.Select(seed => mappings.Aggregate(seed, (acc, current) => current.Get(acc)));

Console.WriteLine(locations.Min());

var seedRanges = seeds.Chunk(2).Select(chunk => new SeedRange(chunk[0], chunk[0] + chunk[1])).ToList();
var newSeedRanges = new List<SeedRange>();

foreach (var mapping in mappings)
{
    while (seedRanges.Count > 0)
    {
        var range = seedRanges[0];
        seedRanges.RemoveAt(0);
        
        OverlapedSeedRange overlap = new();
        if (mapping.TryGetOverlap(range, out overlap))
        {
            newSeedRanges.Add(new(overlap.Start, overlap.End));

            if (overlap.OverlapEnd < range.End) seedRanges.Add(new(overlap.OverlapEnd + 1, range.End));

            if (overlap.OverlapStart > range.Start) seedRanges.Add(new(range.Start, overlap.OverlapStart - 1));
        } 
        else
        {
            newSeedRanges.Add(range);
        }

        Console.WriteLine($"Seed ranges: {seedRanges.Count}");
    }

    Console.WriteLine($"New seed ranges: {newSeedRanges.Count}\n");

    seedRanges = newSeedRanges;
    newSeedRanges = [];
}

Console.WriteLine(seedRanges.Min(range => range.Start));

public class Mapping
{
    private readonly HashSet<MappingRange> ranges = [];

    public Mapping(List<string> lines)
    {
        foreach (var line in lines) ParseLine(line);
    }

    private void ParseLine(string line)
    {
        var parts = line.Split(' ');
        var key = long.Parse(parts[1]);
        var value = long.Parse(parts[0]);

        var iterator = long.Parse(parts[2]) - 1;

        ranges.Add(new MappingRange(key, value, iterator));
    }

    public long Get(long key)
    {
        foreach (var range in ranges) if (range.TryGet(key, out var value)) return value;

        return key;
    }

    public bool TryGetOverlap(SeedRange range, out OverlapedSeedRange overlap)
    {
        foreach (var currentRange in ranges)
        {
            if (currentRange.TryGetOverlap(range, out overlap)) return true;
        }

        overlap = new OverlapedSeedRange();
        return false;
    }
}

public struct MappingRange(long SourceStart, long DestinationStart, long Distance)
{
    private long SourceStart { get; } = SourceStart;
    private long DestinationStart { get; } = DestinationStart;
    private long Distance { get; } = Distance;

    private readonly long SourceEnd => SourceStart + Distance;

    public readonly bool TryGet(long key, out long value)
    {
        value = 0;
        if (key < SourceStart) return false;
        if (key > SourceStart + Distance) return false;

        value = DestinationStart + (key - SourceStart);
        return true;
    }

    public readonly bool TryGetOverlap(SeedRange other, out OverlapedSeedRange overlap)
    {
        overlap = new OverlapedSeedRange();
        if (other.Start > SourceEnd) return false;
        if (other.End < SourceStart) return false;

        var start = other.Start > SourceStart ? other.Start : SourceStart;
        var end = other.End < SourceEnd ? other.End : SourceEnd;

        var distanceFromStart = start - SourceStart;
        var count = end - start;

        var destinationStart = DestinationStart + distanceFromStart;
        var destinationEnd = destinationStart + count;

        overlap = new OverlapedSeedRange(destinationStart, destinationEnd, start, end);
        return true;
    }
}
public record struct SeedRange(long Start, long End);

public record struct OverlapedSeedRange(long Start, long End, long OverlapStart, long OverlapEnd);