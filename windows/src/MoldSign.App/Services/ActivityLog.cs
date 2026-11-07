using System.Text.Json;
using System.Text.Json.Serialization;

namespace MoldSign.App.Services;

/// <summary>
/// The activity log on disk: %LOCALAPPDATA%\MoldSign\activity.json (codename path), newest first, at most
/// <see cref="MaxItems"/> entries, plus the moment the flyout's "Golește lista" last cleared the recent documents.
/// Holds file names and paths only (no PIN, no certificate data: SEC-04).
/// </summary>
internal static class ActivityLog
{
    public const int MaxItems = 100;

    private static readonly string s_path = AppSettings.ActivityPath;

    private static readonly JsonSerializerOptions s_json = new() { WriteIndented = true };

    public sealed record Snapshot(IReadOnlyList<ActivityItem> Items, DateTimeOffset RecentsClearedAt, IReadOnlyList<ActivityItem> SignedDocuments);

    public static Snapshot Load()
    {
        if (DemoMode.Scenario is not null) return new Snapshot([], DateTimeOffset.MinValue, []);
        try
        {
            if (File.Exists(s_path) && JsonSerializer.Deserialize<Stored>(File.ReadAllText(s_path), s_json) is { } stored)
                return new Snapshot(stored.Items ?? [], stored.RecentsClearedAt,
                    stored.SignedDocuments ?? (stored.Items ?? []).Where(item => item.IsSignedDocument).ToArray());
        }
        catch (Exception e) when (e is IOException or JsonException or UnauthorizedAccessException)
        {
            // Corrupt or locked: start empty.
        }
        return new Snapshot([], DateTimeOffset.MinValue, []);
    }

    public static void Save(IEnumerable<ActivityItem> items, DateTimeOffset recentsClearedAt, IEnumerable<ActivityItem> signedDocuments)
    {
        if (DemoMode.Scenario is not null) return;
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(s_path)!);
            // Save both independent collections atomically. Clearing bounded history never clears the library.
            var temporary = s_path + ".tmp";
            File.WriteAllText(temporary, JsonSerializer.Serialize(new Stored
            {
                Items = [.. items.Take(MaxItems)], RecentsClearedAt = recentsClearedAt,
                SignedDocuments = [.. signedDocuments],
            }, s_json));
            File.Move(temporary, s_path, overwrite: true);
        }
        catch (Exception e) when (e is IOException or UnauthorizedAccessException)
        {
            System.Diagnostics.Debug.WriteLine($"activity not saved: {e.Message}");
        }
    }

    private sealed class Stored
    {
        [JsonPropertyName("items")]
        public List<ActivityItem>? Items { get; set; }

        // null means a pre-library file: migrate its successful signing records once.
        [JsonPropertyName("signedDocuments")]
        public IReadOnlyList<ActivityItem>? SignedDocuments { get; set; }

        [JsonPropertyName("recentsClearedAt")]
        public DateTimeOffset RecentsClearedAt { get; set; }
    }
}
