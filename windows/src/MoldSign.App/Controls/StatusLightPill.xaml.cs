using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;

namespace MoldSign.App.Controls;

public sealed partial class StatusLightPill : UserControl
{
    public StatusLightPill() => InitializeComponent();

    public static readonly DependencyProperty LabelProperty = DependencyProperty.Register(
        nameof(Label), typeof(string), typeof(StatusLightPill), new PropertyMetadata(""));
    public string Label { get => (string)GetValue(LabelProperty); set => SetValue(LabelProperty, value); }

    public static readonly DependencyProperty DotBrushProperty = DependencyProperty.Register(
        nameof(DotBrush), typeof(Brush), typeof(StatusLightPill), new PropertyMetadata(null));
    public Brush? DotBrush { get => (Brush?)GetValue(DotBrushProperty); set => SetValue(DotBrushProperty, value); }

    public static readonly DependencyProperty DotVisibilityProperty = DependencyProperty.Register(
        nameof(DotVisibility), typeof(Visibility), typeof(StatusLightPill), new PropertyMetadata(Visibility.Collapsed));
    public Visibility DotVisibility { get => (Visibility)GetValue(DotVisibilityProperty); set => SetValue(DotVisibilityProperty, value); }
}
