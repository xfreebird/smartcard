package md.moldsign.app

import android.app.Activity
import android.app.Instrumentation
import android.os.Bundle
import android.util.Base64
import md.moldsign.core.protection.PasswordFileProtection

/** Runs inside Android's runtime: legacy-provider support cannot be inferred from JVM tests. */
class FileProtectionInstrumentation : Instrumentation() {
    override fun onCreate(arguments: Bundle?) { super.onCreate(arguments); start() }
    override fun onStart() {
        val result=Bundle()
        try {
            val plain=ByteArray(17){(it*37).toByte()}
            val fixtures=listOf(
            "3_KeyTripleDES_CBC" to "MIACAQAwgAYJKoZIhvcNAQcBMBwGCiqGSIb3DQEMAQMwDgQIEnVHu4fZVY0CAicQoIAEGIhFojiCJLjZ5fb5VuF7tJd/X58HlH1jwQAAAAAAAA==",
            "DES_CBC" to "MIACAQAwgAYJKoZIhvcNAQcBMBsGCSqGSIb3DQEFAzAOBAixC3OQDq1IfQICJxCggAQYZxqb7mexTIJwrru5tWJgkRYd59V/+h+9AAAAAAAA",
            "RC2_CBC" to "MIACAQAwgAYJKoZIhvcNAQcBMBwGCiqGSIb3DQEMAQYwDgQITttOkXZ2v04CAicQoIAEGOk8wJWNdNeO+1j1caYFcOY0Tz99L43lgAAAAAAAAA=="
            )
            for((name,base64) in fixtures) {
                check(PasswordFileProtection.decrypt(Base64.decode(base64,Base64.DEFAULT),"Legacy-Test-2026".toCharArray()).contentEquals(plain)){"Legacy provider failed: $name"}
            }
            val password="Test-șț-🔐-2026".toCharArray()
            val encrypted=PasswordFileProtection.encrypt(plain,password)
            check(PasswordFileProtection.decrypt(encrypted,password).contentEquals(plain))
            password.fill('\u0000')
            result.putString("result","PASS: Android AES and all three legacy vendor fixtures")
            finish(Activity.RESULT_OK,result)
        } catch(error:Throwable) {
            result.putString("result","FAIL: "+error.javaClass.simpleName+": "+error.message)
            finish(Activity.RESULT_CANCELED,result)
        }
    }
}
