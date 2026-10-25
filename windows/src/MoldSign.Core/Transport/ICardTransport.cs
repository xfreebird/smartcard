namespace MoldSign.Core;

/// <summary>
/// Raw APDU in, raw response INCLUDING SW1 SW2 out (docs/09-architecture.md §3.1).
/// No GET RESPONSE handling here: <see cref="CosmoXCard"/> loops on <c>61xx</c> itself.
/// </summary>
public interface ICardTransport : IDisposable
{
    string ReaderName { get; }

    byte[] Transmit(byte[] apdu);
}
