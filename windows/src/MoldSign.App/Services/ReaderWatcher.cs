using System.Diagnostics;
using MoldSign.Core;
using Windows.Devices.Enumeration;
using Windows.Devices.SmartCards;

namespace MoldSign.App.Services;

/// <summary>
/// Windows ReaderMonitor (docs/09 §3.1b and §3.7, WIN-03): every reader, every card, every card change.
///
/// The truth is PC/SC: <see cref="WinSCardTransport.GetReaderStates"/> (SCardGetStatusChange, zero timeout, never
/// connects) gives the reader names the transport connects to, card presence, the mute flag and the card event
/// counter; <see cref="ReaderGenerationTracker"/> turns that into a generation per reader, so a remove + reinsert or
/// a swap always produces a new card. What triggers a snapshot:
/// <list type="bullet">
/// <item><see cref="DeviceWatcher"/> over <c>SmartCardReader.GetDeviceSelector</c> (reader hot-plug) and
///       <c>SmartCardReader.CardAdded/CardRemoved</c> per reader: instant updates;</item>
/// <item>a 2-second poll as a safety net (missed WinRT events, mute cards, the Smart Card service restarting).</item>
/// </list>
/// <see cref="Changed"/> fires on a thread-pool thread, only when the snapshot changed.
/// TODO(WIN-03): toast on reader connect/disconnect (AppNotificationManager), honoring AppSettings.ReaderToasts.
/// </summary>
public sealed class ReaderWatcher : IDisposable
{
    private static readonly TimeSpan s_pollInterval = TimeSpan.FromSeconds(2);

    private readonly object _gate = new();
    private readonly ReaderGenerationTracker _tracker = new();
    private readonly Dictionary<string, SmartCardReader> _readers = new(StringComparer.Ordinal);
    private DeviceWatcher? _watcher;
    private Timer? _poll;
    private IReadOnlyList<ReaderSlot>? _last;

    /// <summary>Every reader with its card state and generation, after each change.</summary>
    public event EventHandler<IReadOnlyList<ReaderSlot>>? Changed;

    public void Start()
    {
        if (_watcher is not null) return;
        try
        {
            _watcher = DeviceInformation.CreateWatcher(SmartCardReader.GetDeviceSelector(SmartCardReaderKind.Any));
            _watcher.Added += OnReaderAdded;
            _watcher.Removed += OnReaderRemoved;
            _watcher.EnumerationCompleted += OnEnumerationCompleted;
            _watcher.Start();
        }
        catch (Exception e)
        {
            // The poll below still works without the WinRT triggers.
            Debug.WriteLine($"ReaderWatcher: DeviceWatcher unavailable: {e.Message}");
        }
        _poll = new Timer(_ => Poll(force: false), null, TimeSpan.Zero, s_pollInterval);
    }

    /// <summary>Publishes the current snapshot even if unchanged (after "Recitește cardul" or a card operation).</summary>
    public void Refresh() => ThreadPool.QueueUserWorkItem(_ => Poll(force: true));

    public void Dispose()
    {
        _poll?.Dispose();
        _poll = null;
        if (_watcher is { } watcher)
        {
            watcher.Added -= OnReaderAdded;
            watcher.Removed -= OnReaderRemoved;
            watcher.EnumerationCompleted -= OnEnumerationCompleted;
            if (watcher.Status is DeviceWatcherStatus.Started or DeviceWatcherStatus.EnumerationCompleted)
                watcher.Stop();
            _watcher = null;
        }
        lock (_gate)
        {
            foreach (var reader in _readers.Values) Detach(reader);
            _readers.Clear();
        }
    }

    private async void OnReaderAdded(DeviceWatcher sender, DeviceInformation info)
    {
        try
        {
            var reader = await SmartCardReader.FromIdAsync(info.Id);
            if (reader is not null)
            {
                reader.CardAdded += OnCardAdded;
                reader.CardRemoved += OnCardRemoved;
                lock (_gate) _readers[info.Id] = reader;
            }
        }
        catch (Exception e)
        {
            Debug.WriteLine($"ReaderWatcher: cannot open {info.Name}: {e.Message}");
        }
        Poll(force: false);
    }

    private void OnReaderRemoved(DeviceWatcher sender, DeviceInformationUpdate update)
    {
        lock (_gate)
        {
            if (_readers.Remove(update.Id, out var reader)) Detach(reader);
        }
        Poll(force: false);
    }

    private void OnEnumerationCompleted(DeviceWatcher sender, object args) => Poll(force: false);

    private void OnCardAdded(SmartCardReader sender, CardAddedEventArgs args) => Poll(force: false);

    private void OnCardRemoved(SmartCardReader sender, CardRemovedEventArgs args) => Poll(force: false);

    private void Detach(SmartCardReader reader)
    {
        reader.CardAdded -= OnCardAdded;
        reader.CardRemoved -= OnCardRemoved;
    }

    /// <summary>One PC/SC snapshot → generations → <see cref="Changed"/>. Serialized: triggers arrive on any thread.</summary>
    private void Poll(bool force)
    {
        lock (_gate)
        {
            IReadOnlyList<ReaderStatus> states;
            try
            {
                states = WinSCardTransport.GetReaderStates();
            }
            catch (CardException e)
            {
                Debug.WriteLine($"ReaderWatcher: {e.Message}");
                states = [];
            }

            var slots = _tracker.Update(states);
            if (!force && _last is not null && _last.SequenceEqual(slots)) return;
            _last = slots;
            try
            {
                Changed?.Invoke(this, slots);
            }
            catch (Exception e)
            {
                Debug.WriteLine($"ReaderWatcher subscriber failed: {e}");
            }
        }
    }
}
