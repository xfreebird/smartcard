using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media;

namespace MoldSign.App.Controls;

internal static class ControlTheme
{
    internal static Brush Brush(string key) =>
        Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush
            ? brush : new SolidColorBrush(Microsoft.UI.Colors.Gray);
}
