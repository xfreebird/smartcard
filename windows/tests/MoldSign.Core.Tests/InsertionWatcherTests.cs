using MoldSign.Desktop;

namespace MoldSign.Core.Tests;

public sealed class InsertionWatcherTests
{
    [Fact]
    public void Reader_insertion_opens_once_and_startup_is_only_a_baseline()
    {
        var policy = new InsertionActivationPolicy();
        var options = new DesktopPreferences { OpenOnReaderInsertion = true };
        Assert.False(policy.Update([], options));
        Assert.True(policy.Update([new("fixture", false)], options));
        Assert.False(policy.Update([new("fixture", false)], options));
        Assert.False(policy.Update([], options));
        Assert.True(policy.Update([new("fixture", false)], options));
        Assert.False(new InsertionActivationPolicy().Update([new("already connected", true)], options));
    }

    [Fact]
    public void Card_insertions_and_swaps_are_bound_to_configured_edges()
    {
        var policy = new InsertionActivationPolicy();
        var options = new DesktopPreferences { OpenOnCardInsertion = true };
        Assert.False(policy.Update([], options));
        Assert.False(policy.Update([new("fixture", false)], options));
        Assert.True(policy.Update([new("fixture", true, EventCount: 1)], options));
        Assert.False(policy.Update([new("fixture", true, EventCount: 1)], options));
        Assert.True(policy.Update([new("fixture", true, EventCount: 3)], options));
        Assert.True(policy.Update([new("fixture", true, Mute: true, EventCount: 4)], options));
        Assert.False(policy.Update([new("fixture", false)], options));
    }

    [Fact]
    public void A_muted_inserted_card_still_opens_the_app_for_error_interaction()
    {
        var policy = new InsertionActivationPolicy();
        var options = new DesktopPreferences { OpenOnCardInsertion = true };
        policy.Update([new("fixture", false)], options);
        Assert.True(policy.Update([new("fixture", true, Mute: true)], options));
        Assert.False(policy.Update([new("fixture", true, Mute: true)], options));
    }

    [Fact]
    public async Task Helper_runs_with_injected_snapshots_and_launcher_without_any_card_connection()
    {
        var source = new Snapshots();
        var launcher = new Launcher();
        var options = new DesktopPreferences { OpenOnReaderInsertion = true, OpenOnCardInsertion = true };
        var watcher = new InsertionWatcher(source, launcher, () => options);
        Assert.True(await watcher.CheckAsync(default));
        source.Readers = [new("fixture", false)];
        await watcher.CheckAsync(default);
        source.Readers = [new("fixture", true, EventCount: 1)];
        await watcher.CheckAsync(default);
        await watcher.CheckAsync(default);
        Assert.Equal(2, launcher.Opens);
        options.OpenOnReaderInsertion = options.OpenOnCardInsertion = false;
        Assert.False(await watcher.CheckAsync(default));
        Assert.Equal(2, launcher.Opens);
    }

    [Fact]
    public void Preferences_round_trip_atomically_without_a_pin_field()
    {
        using var files = new SigningCoreTests.TestFiles();
        var path = Path.Combine(files.DirectoryPath, "preferences.json");
        var store = new DesktopPreferenceStore(path);
        store.Save(new DesktopPreferences { OpenOnReaderInsertion = true, Language = "ru-RU" });
        var loaded = store.Load<DesktopPreferences>();
        Assert.True(loaded.OpenOnReaderInsertion);
        Assert.Equal("ru-RU", loaded.Language);
        Assert.DoesNotContain("\"Pin\"", File.ReadAllText(path), StringComparison.OrdinalIgnoreCase);
        Assert.Empty(Directory.GetFiles(files.DirectoryPath, "*.tmp"));
    }

    [Fact]
    public async Task Windows_secondary_instance_sends_only_an_activation_to_primary()
    {
        if (!OperatingSystem.IsWindows()) return;
        var key = "MoldSign-Test-" + Guid.NewGuid().ToString("N");
        using var first = new DesktopActivationBroker(key);
        Assert.True(first.IsPrimary);
        var opened = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        first.Listen(() => opened.TrySetResult());
        using var second = new DesktopActivationBroker(key);
        Assert.False(second.IsPrimary);
        await second.OpenExistingAsync(default);
        await opened.Task.WaitAsync(TimeSpan.FromSeconds(5));
    }

    private sealed class Snapshots : IReaderSnapshotSource
    {
        public IReadOnlyList<ReaderStatus> Readers { get; set; } = [];
        public IReadOnlyList<ReaderStatus> Read() => Readers;
    }
    private sealed class Launcher : IApplicationActivator
    {
        public int Opens { get; private set; }
        public Task OpenAsync(CancellationToken cancellationToken) { Opens++; return Task.CompletedTask; }
    }
}
