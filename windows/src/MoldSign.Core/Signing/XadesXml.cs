using System.Security.Cryptography;
using System.Security.Cryptography.Xml;
using System.Xml;

namespace MoldSign.Core;

internal static class XadesXml
{
    internal const string Ds = "http://www.w3.org/2000/09/xmldsig#";
    internal const string Xades = "http://uri.etsi.org/01903/v1.3.2#";
    internal const string C14n = "http://www.w3.org/TR/2001/REC-xml-c14n-20010315";
    internal const string Sha256 = "http://www.w3.org/2001/04/xmlenc#sha256";
    internal const string Sha1 = Ds + "sha1";
    internal const string RsaSha1 = Ds + "rsa-sha1";
    internal const string RsaSha256 = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256";

    internal static XmlDocument Parse(byte[] xml)
    {
        var document = new XmlDocument { PreserveWhitespace = true, XmlResolver = null };
        using var input = new MemoryStream(xml);
        using var reader = XmlReader.Create(input, new XmlReaderSettings
        {
            DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null, MaxCharactersInDocument = 64 * 1024 * 1024,
        });
        document.Load(reader);
        return document;
    }

    internal static XmlElement Add(XmlElement parent, string prefix, string name, string? text = null)
    {
        var child = parent.OwnerDocument!.CreateElement(prefix, name, prefix == "ds" ? Ds : Xades);
        parent.AppendChild(child);
        if (text is not null) child.InnerText = text;
        return child;
    }

    internal static byte[] Canonical(XmlElement element, bool comments = false)
    {
        var document = new XmlDocument { PreserveWhitespace = true, XmlResolver = null };
        var root = (XmlElement)document.ImportNode(element, true);
        document.AppendChild(root);
        var seen = new HashSet<string>(StringComparer.Ordinal);
        for (XmlElement? ancestor = element; ancestor is not null; ancestor = ancestor.ParentNode as XmlElement)
        {
            foreach (XmlAttribute attribute in ancestor.Attributes)
            {
                if (attribute.NamespaceURI == "http://www.w3.org/2000/xmlns/" && seen.Add(attribute.Name))
                    root.SetAttribute(attribute.Name, attribute.Value);
                // Inclusive canonicalization also inherits xml:lang, xml:space and xml:base.
                if (attribute.NamespaceURI == "http://www.w3.org/XML/1998/namespace" && seen.Add(attribute.Name))
                {
                    var inherited = document.CreateAttribute("xml", attribute.LocalName, attribute.NamespaceURI);
                    inherited.Value = attribute.Value;
                    root.Attributes.SetNamedItem(inherited);
                }
            }
        }
        var transform = new XmlDsigC14NTransform(comments);
        transform.LoadInput(document);
        using var output = (Stream)transform.GetOutput(typeof(Stream));
        using var buffer = new MemoryStream();
        output.CopyTo(buffer);
        return buffer.ToArray();
    }

    internal static byte[] Hash(byte[] bytes, string algorithm) => algorithm switch
    {
        Sha256 => SHA256.HashData(bytes),
        Sha1 => SHA1.HashData(bytes),
        _ => throw new CardException(CardErrorKind.Format, "Unsupported XML digest algorithm"),
    };

    internal static IEnumerable<XmlElement> Children(XmlElement parent, string name, string ns = Ds) =>
        parent.ChildNodes.OfType<XmlElement>().Where(e => e.LocalName == name && e.NamespaceURI == ns);
    internal static XmlElement Child(XmlElement parent, string name, string ns = Ds) =>
        Children(parent, name, ns).Single();
}
