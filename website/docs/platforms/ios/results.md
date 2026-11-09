---
title: "Understand verification results — iPhone"
sidebar_label: "Understand verification results"
description: "Distinguish invalid signatures, unconfirmed trust and unsigned files."
pagination_prev: "platforms/ios/verification"
pagination_next: "platforms/ios/documents"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Understand verification results — iPhone

[Platform overview](../ios.md) · [Installation and reader setup](./setup.md)

Distinguish invalid signatures, unconfirmed trust and unsigned files.

## Understand an unexpected verification result

Invalid means a signature or document-integrity check failed. Unconfirmed trust means the embedded chain is not confirmed; it is different from a proven altered document. Unsigned or unrecognized means no supported signature was found. Do not treat the filename or a green file icon as proof. An inaccessible saved file is unavailable, not necessarily unsigned.

<GuideScreenshot src="/img/guide/iphone/en/invalid.png" alt="Read the failed checks; obtain the correct signed file or unchanged original from its sender." steps={[{"text": "Read the failed checks; obtain the correct signed file or unchanged original from its sender.", "x": 14, "y": 41}]} />
<GuideScreenshot src="/img/guide/iphone/en/untrusted.png" alt="Read the trust warning separately from integrity and signature checks." steps={[{"text": "Read the trust warning separately from integrity and signature checks.", "x": 14, "y": 41}]} />
<GuideScreenshot src="/img/guide/iphone/en/unsigned.png" alt="Confirm that you chose the signed output, then inspect whether any supported signature was found." steps={[{"text": "Confirm that you chose the signed output, then inspect whether any supported signature was found.", "x": 14, "y": 41}]} />
