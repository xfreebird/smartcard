using System.Text.Json;
namespace MoldSign.Core.Tests;

public sealed class ExtendedSecureChannelTests
{
    [Fact]
    public void Independent_extended_vectors()
    {
        var directory = new DirectoryInfo(AppContext.BaseDirectory);
        while (directory != null && !File.Exists(Path.Combine(directory.FullName,"spec/vectors/encryption/extended-sm.json"))) directory = directory.Parent;
        Assert.NotNull(directory);
        using var document = JsonDocument.Parse(File.ReadAllText(Path.Combine(directory.FullName,"spec/vectors/encryption/extended-sm.json")));
        var fixture = document.RootElement;
        byte[] Read(JsonElement item,string key) => Convert.FromHexString(item.GetProperty(key).GetString()!);
        foreach (var vector in fixture.GetProperty("vectors").EnumerateArray())
        {
            var channel = new SecureChannel(Read(fixture,"enc"),Read(fixture,"mac"),Read(fixture,"ssc"));
            Assert.Equal(Read(vector,"wrapped"),channel.Wrap(Read(vector,"command")));
        }
    }
    [Fact]
    public void Malformed_commands_do_not_consume_counter()
    {
        byte[][] commands = [Convert.FromHexString("002a80860001"),Convert.FromHexString("002a808600000301020000"),
            Convert.FromHexString("002a80860201"),[..Convert.FromHexString("002a808600ffff"),..new byte[65535]]];
        foreach (var command in commands)
        {
            var channel = new SecureChannel(new byte[32],new byte[32],new byte[16]);
            Assert.Throws<ArgumentException>(() => channel.Wrap(command));
            Assert.Equal(new byte[16],channel.Ssc);
        }
    }
}
