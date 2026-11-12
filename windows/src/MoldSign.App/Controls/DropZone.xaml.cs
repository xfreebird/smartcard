using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.ApplicationModel.DataTransfer;

namespace MoldSign.App.Controls;

/// <summary>Drop or pick files; raises <see cref="FilesChosen"/> with local paths.</summary>
public sealed partial class DropZone : UserControl
{
    private Brush? _idleStroke;

    public DropZone()
    {
        InitializeComponent();
    }

    public event EventHandler<IReadOnlyList<string>>? FilesChosen;
    public IFileSelectionProvider? FileSelection { get; set; }

    /// <summary>Compact one-row zone (≈ 56 epx) under a document list; large (≈ 170 epx) otherwise.</summary>
    public bool IsCompact
    {
        get => CompactContent.Visibility == Visibility.Visible;
        set
        {
            LargeContent.Visibility = value ? Visibility.Collapsed : Visibility.Visible;
            CompactContent.Visibility = value ? Visibility.Visible : Visibility.Collapsed;
            MinHeight = value ? 56 : 170;
        }
    }

    /// <summary>Picker filter, e.g. ".pdf", ".xml"; empty = all files.</summary>
    public IList<string> Extensions { get; } = [];

    private void OnDragOver(object sender, DragEventArgs e)
    {
        if (FileSelection?.AcceptsDrops != true || !e.DataView.Contains(StandardDataFormats.StorageItems)) return;
        e.AcceptedOperation = DataPackageOperation.Copy;
        e.Handled = true;
        SetHover(true);
    }

    private void OnDragLeave(object sender, DragEventArgs e) => SetHover(false);

    private async void OnDrop(object sender, DragEventArgs e)
    {
        SetHover(false);
        e.Handled = true;
        if (FileSelection is not { } selection) return;
        if (!selection.AcceptsDrops)
        {
            Failure.Message = selection.DropUnavailableMessage; Failure.IsOpen = true; return;
        }
        var deferral = e.GetDeferral();
        try
        {
            Failure.IsOpen = false;
            var paths = await selection.ReadDropAsync(e.DataView);
            if (paths.Count > 0) FilesChosen?.Invoke(this, paths);
        }
        catch (Exception error)
        {
            Failure.Message = selection.DescribeFailure(error);
            Failure.IsOpen = true;
        }
        finally
        {
            deferral.Complete();
        }
    }

    private async void OnBrowseClick(object sender, RoutedEventArgs e)
    {
        if (FileSelection is not { } selection) return;
        try
        {
            Failure.IsOpen = false;
            var paths = await selection.PickAsync(XamlRoot, [.. Extensions]);
            if (paths.Count > 0) FilesChosen?.Invoke(this, paths);
        }
        catch (Exception error)
        {
            Failure.Message = selection.DescribeFailure(error);
            Failure.IsOpen = true;
        }
    }

    private void SetHover(bool hover)
    {
        _idleStroke ??= Outline.Stroke;
        Outline.Fill = hover ? ControlTheme.Brush("BrandSoftBrush") : ControlTheme.Brush("SubtleFillColorSecondaryBrush");
        Outline.Stroke = hover ? ControlTheme.Brush("BrandBrush") : _idleStroke;
    }
}
