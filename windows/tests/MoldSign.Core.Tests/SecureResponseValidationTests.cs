namespace MoldSign.Core.Tests;

public sealed class SecureResponseValidationTests
{
    private static readonly byte[] Enc=Enumerable.Repeat((byte)1,32).ToArray();
    private static readonly byte[] Mac=Enumerable.Repeat((byte)2,32).ToArray();
    private static byte[] ResponseSsc=>[..new byte[15],1];
    private static SecureChannel Channel()=>new(Enc,Mac,new byte[16]);
    private static byte[] Authenticated(byte[] body,ushort outer=0x9000)=>
        [..body,..SecureChannel.BuildTlv(0x8e,Cmac.Compute(Mac,Iso9797.Pad([..ResponseSsc,..body])).AsSpan(0,8)),(byte)(outer>>8),(byte)outer];

    [Theory]
    [InlineData(0x6282)]
    [InlineData(0x6b00)]
    [InlineData(0x6982)]
    public void Mirrored_status_is_authenticated_and_returned(int status)
    {
        var channel=Channel();
        var result=channel.Unwrap(Authenticated([0x99,2,(byte)(status>>8),(byte)status],(ushort)status));
        Assert.Empty(result.Data);Assert.Equal(status,(int)result.StatusWord);Assert.Equal(ResponseSsc,channel.Ssc);
    }
    [Fact]
    public void Final_EOF_chunk_retains_its_plaintext_zero_and_80_bytes()
    {
        byte[] plain=[0x11,0x80,0,0];
        var ciphertext=AesPrimitives.EncryptCbc(Enc,AesPrimitives.EncryptEcb(Enc,ResponseSsc),Iso9797.Pad(plain));
        var body=SecureChannel.BuildTlv(0x87,[1,..ciphertext]);
        var result=Channel().Unwrap(Authenticated([..body,0x99,2,0x62,0x82],0x6282));
        Assert.Equal(plain,result.Data);Assert.Equal(0x6282,result.StatusWord);
    }
    [Fact]
    public void Missing_tampered_duplicate_or_conflicting_status_and_MAC_are_rejected()
    {
        var tampered=Authenticated([0x99,2,0x62,0x82],0x6282);tampered[^3]^=1;
        byte[][] cases=[ [0x90,0], [0x99,2,0x62,0x82,0x62,0x82], tampered,
            Authenticated([]),Authenticated([0x99,2,0x90,0],0x6282),
            Authenticated([0x99,2,0x90,0,0x99,2,0x90,0]),
            Authenticated([0x87,2,1,0,0x99,2,0x90,0]) ];
        foreach(var response in cases)
            Assert.Equal(CardErrorKind.SmOutOfSync,Assert.Throws<CardException>(()=>Channel().Unwrap(response)).Kind);
    }
    [Fact]
    public void Valid_MAC_does_not_admit_invalid_encrypted_padding()
    {
        var ciphertext=AesPrimitives.EncryptCbc(Enc,AesPrimitives.EncryptEcb(Enc,ResponseSsc),new byte[16]);
        var body=SecureChannel.BuildTlv(0x87,[1,..ciphertext]);
        Assert.Throws<CardException>(()=>Channel().Unwrap(Authenticated([..body,0x99,2,0x90,0])));
    }
}
