using Microsoft.UI.Xaml;
using Windows.ApplicationModel.DataTransfer;

namespace MoldSign.App.Controls;

/// <summary>Host-supplied file selection. Controls do not know about live or demo services.</summary>
public interface IFileSelectionProvider
{
    bool AcceptsDrops { get; }
    string DropUnavailableMessage { get; }
    Task<IReadOnlyList<string>> PickAsync(XamlRoot? root, string[] extensions);
    Task<IReadOnlyList<string>> ReadDropAsync(DataPackageView data);
    string DescribeFailure(Exception error);
}
