using System.Text.RegularExpressions;

var pairs = new Dictionary<string, string>
{
    {"one"  , "1" },
    {"two"  , "2" },
    {"three", "3" },
    {"four" , "4" },
    {"five" , "5" },
    {"six"  , "6" },
    {"seven", "7" },
    {"eight", "8" },
    {"nine" , "9" },
};

string parseNumeric(string numeric)
{
    return pairs.TryGetValue(numeric, out string? parsed) ? parsed : numeric;
}

int parse(Regex regex, IEnumerable<string> lines)
{
    return lines
        .Select(line => regex.Matches(line))
        .Select(match => new { First = match[0].Groups.Values.First(group => group.Value != "").Value, Last = match[^1].Groups.Values.First(group => group.Value != "").Value })
        .Select(pair => new {First = parseNumeric(pair.First), Last = parseNumeric(pair.Last) })
        .Select(row => int.Parse($"{row.First}{row.Last}"))
        .Sum();
}

var regex1 = new Regex("(?=(\\d))");
var regex2 = new Regex("(?=(one)|(two)|(three)|(four)|(five)|(six)|(seven)|(eight)|(nine)|(\\d))");

new List<Regex>{ regex1, regex2 }.ForEach(regex => Console.WriteLine(parse(regex, File.ReadAllLines("input.txt"))));