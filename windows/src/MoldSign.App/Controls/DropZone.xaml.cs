using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using MoldSign.App.Services;
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
        if (!e.DataView.Contains(StandardDataFormats.StorageItems)) return;
        e.AcceptedOperation = DataPackageOperation.Copy;
        SetHover(true);
    }

    private void OnDragLeave(object sender, DragEventArgs e) => SetHover(false);

    private async void OnDrop(object sender, DragEventArgs e)
    {
        SetHover(false);
        var deferral = e.GetDeferral();
        try
        {
            var paths = await WindowHelpers.DroppedPathsAsync(e.DataView);
            if (paths.Count > 0) FilesChosen?.Invoke(this, paths);
        }
        finally
        {
            deferral.Complete();
        }
    }

    private async void OnBrowseClick(object sender, RoutedEventArgs e)
    {
        if (XamlRoot is null) return;
        var paths = await WindowHelpers.PickFilesAsync(XamlRoot, [.. Extensions]);
        if (paths.Count > 0) FilesChosen?.Invoke(this, paths);
    }

    private void SetHover(bool hover)
    {
        _idleStroke ??= Outline.Stroke;
        Outline.Fill = hover ? WindowHelpers.ThemeBrush("BrandSoftBrush") : new SolidColorBrush(Microsoft.UI.Colors.Transparent);
        Outline.Stroke = hover ? WindowHelpers.ThemeBrush("BrandBrush") : _idleStroke;
        Outline.StrokeDashArray = hover ? null : new DoubleCollection { 4, 3 };
    }
}
