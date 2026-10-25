/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.squareup.moshi.JsonAdapter
 *  com.squareup.moshi.Moshi
 *  com.squareup.moshi.Moshi$Builder
 *  okhttp3.MediaType
 *  okhttp3.OkHttpClient
 *  okhttp3.OkHttpClient$Builder
 *  okhttp3.Request
 *  okhttp3.Request$Builder
 *  okhttp3.RequestBody
 *  okhttp3.Response
 *  okhttp3.ResponseBody
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package cargo;

import com.squareup.moshi.JsonAdapter;
import com.squareup.moshi.Moshi;
import java.io.IOException;
import java.util.concurrent.TimeUnit;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okhttp3.ResponseBody;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class DartApi {
    private static final Logger logger = LoggerFactory.getLogger(DartApi.class);
    private static final MediaType JSON = MediaType.get((String)"application/json");
    private static final Moshi moshi = new Moshi.Builder().build();
    private static final OkHttpClient client = new OkHttpClient.Builder().connectTimeout(8L, TimeUnit.SECONDS).readTimeout(128L, TimeUnit.SECONDS).writeTimeout(12L, TimeUnit.SECONDS).build();

    private DartApi() {
    }

    /*
     * Enabled aggressive exception aggregation
     */
    public static <T1, T2> T2 doHttpCall(String api, T1 post, Class<T1> reqClass, Class<T2> respClass) {
        JsonAdapter reqAdapter = moshi.adapter(reqClass);
        JsonAdapter respAdapter = moshi.adapter(respClass);
        String json = reqAdapter.toJson(post);
        RequestBody body = RequestBody.create((String)json, (MediaType)JSON);
        Request request = new Request.Builder().url("https://renewal.pki.md/renewal/" + api).post(body).build();
        try (Response response = client.newCall(request).execute();){
            Object object;
            block24: {
                Object respJson;
                ResponseBody respBody;
                block22: {
                    T2 T2;
                    block23: {
                        block20: {
                            T2 T22;
                            block21: {
                                if (!response.isSuccessful()) {
                                    logger.error("HTTP request failed: {} - {}", (Object)response.code(), (Object)response.message());
                                    T2 T23 = null;
                                    return T23;
                                }
                                respBody = response.body();
                                try {
                                    if (respBody != null) break block20;
                                    logger.error("HTTP empty response body");
                                    T22 = null;
                                    if (respBody == null) break block21;
                                }
                                catch (Throwable throwable) {
                                    if (respBody != null) {
                                        try {
                                            respBody.close();
                                        }
                                        catch (Throwable throwable2) {
                                            throwable.addSuppressed(throwable2);
                                        }
                                    }
                                    throw throwable;
                                }
                                respBody.close();
                            }
                            return T22;
                        }
                        respJson = respAdapter.fromJson(respBody.source());
                        if (respJson != null) break block22;
                        logger.error("HTTP failed to parse JSON");
                        T2 = null;
                        if (respBody == null) break block23;
                        respBody.close();
                    }
                    return T2;
                }
                object = respJson;
                if (respBody == null) break block24;
                respBody.close();
            }
            return (T2)object;
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
            return null;
        }
    }
}

