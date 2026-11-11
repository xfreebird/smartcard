using MoldSign.Desktop;

namespace MoldSign.Core.Tests;

public sealed class PasswordFileProcessorTests
{
    [Fact]
    public void RoundTripPreservesInputAndRestoresBytes()
    {
        WithDirectory(root =>
        {
            var source = Path.Combine(root, "source.txt");
            var envelope = Path.Combine(root, "source.symmetric.p7m");
            var bytes = "Synthetic contract"u8.ToArray();
            File.WriteAllBytes(source, bytes);
            IPasswordFileProcessor processor = new PasswordFileProcessor();
            var encrypted = processor.Process(source, FileProtectionOperation.Encrypt, "test-password");
            Assert.NotNull(encrypted);
            File.WriteAllBytes(envelope, encrypted);
            Assert.Equal(bytes, processor.Process(envelope, FileProtectionOperation.Decrypt, "test-password"));
            Assert.Equal(bytes, File.ReadAllBytes(source));
            Assert.Equal(encrypted, File.ReadAllBytes(envelope));
        });
    }

    [Fact]
    public void InvalidOperationIsRejectedBeforeReadingInput()
    {
        IPasswordFileProcessor processor = new PasswordFileProcessor();
        Assert.Throws<ArgumentOutOfRangeException>(() => processor.Process("missing", (FileProtectionOperation)99, "test"));
    }

    [Fact]
    public void MalformedInputFailsWithoutChangingIt()
    {
        WithDirectory(root =>
        {
            var source = Path.Combine(root, "invalid");
            var bytes = "not an envelope"u8.ToArray();
            File.WriteAllBytes(source, bytes);
            var processor = new PasswordFileProcessor();
            Assert.ThrowsAny<Exception>(() => processor.Process(source, FileProtectionOperation.Decrypt, "test"));
            Assert.Equal(bytes, File.ReadAllBytes(source));
        });
    }

    private static void WithDirectory(Action<string> test)
    {
        var root = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(root);
        try { test(root); }
        finally { Directory.Delete(root, true); }
    }
}
