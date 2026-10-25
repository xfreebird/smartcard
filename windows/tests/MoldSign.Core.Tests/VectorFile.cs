using System.Text.Json;

namespace MoldSign.Core.Tests;

/// <summary>
/// Loads <c>spec/vectors/card-crypto.json</c>, the golden vectors shared with the Swift and Kotlin ports.
/// Found by walking up from the test binaries until a directory containing <c>spec/vectors</c> appears.
/// </summary>
internal static class VectorFile
{
    private static readonly Lazy<JsonDocument> s_document = new(Load);

    public static JsonElement Root => s_document.Value.RootElement;

    public static string RepoRoot { get; } = FindRepoRoot();

    /// <summary>Hex value at a property path, e.g. <c>Bytes("kdf", "kenc")</c>.</summary>
    public static byte[] Bytes(params string[] path) => Hex.Decode(String(path));

    public static string String(params string[] path)
    {
        var element = Root;
        foreach (var segment in path) element = element.GetProperty(segment);
        return element.GetString() ?? throw new InvalidOperationException($"null at {string.Join('.', path)}");
    }

    public static byte[] Ascii(params string[] path) => System.Text.Encoding.ASCII.GetBytes(String(path));

    private static JsonDocument Load() =>
        JsonDocument.Parse(File.ReadAllText(Path.Combine(RepoRoot, "spec", "vectors", "card-crypto.json")));

    private static string FindRepoRoot()
    {
        for (var dir = new DirectoryInfo(AppContext.BaseDirectory); dir is not null; dir = dir.Parent)
        {
            if (Directory.Exists(Path.Combine(dir.FullName, "spec", "vectors"))) return dir.FullName;
        }
        throw new DirectoryNotFoundException(
            $"spec/vectors not found above {AppContext.BaseDirectory}; run the tests from inside the repository.");
    }
}
