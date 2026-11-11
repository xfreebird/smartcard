package md.moldsign.app

/** Vendor-compatible encrypted samples with a synthetic test password. */
internal object LegacyProtectionFixtures {
    val encryptedSamples=listOf(
            "3_KeyTripleDES_CBC" to "MIACAQAwgAYJKoZIhvcNAQcBMBwGCiqGSIb3DQEMAQMwDgQIEnVHu4fZVY0CAicQoIAEGIhFojiCJLjZ5fb5VuF7tJd/X58HlH1jwQAAAAAAAA==",
            "DES_CBC" to "MIACAQAwgAYJKoZIhvcNAQcBMBsGCSqGSIb3DQEFAzAOBAixC3OQDq1IfQICJxCggAQYZxqb7mexTIJwrru5tWJgkRYd59V/+h+9AAAAAAAA",
            "RC2_CBC" to "MIACAQAwgAYJKoZIhvcNAQcBMBwGCiqGSIb3DQEMAQYwDgQITttOkXZ2v04CAicQoIAEGOk8wJWNdNeO+1j1caYFcOY0Tz99L43lgAAAAAAAAA=="
            )
}
