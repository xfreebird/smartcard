/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.netUtil.Dns
 *  kotlin.Metadata
 *  kotlin.Unit
 *  kotlin.coroutines.Continuation
 *  kotlin.coroutines.CoroutineContext
 *  kotlin.coroutines.intrinsics.IntrinsicsKt
 *  kotlin.jvm.functions.Function1
 *  kotlin.jvm.functions.Function2
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.StringsKt
 *  kotlinx.coroutines.BuildersKt
 *  kotlinx.coroutines.CoroutineScope
 *  kotlinx.coroutines.Dispatchers
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.util;

import dorkbox.netUtil.Dns;
import java.io.InputStream;
import java.security.SecureRandom;
import java.security.cert.X509Certificate;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import kotlin.Metadata;
import kotlin.Unit;
import kotlin.coroutines.Continuation;
import kotlin.coroutines.CoroutineContext;
import kotlin.coroutines.intrinsics.IntrinsicsKt;
import kotlin.jvm.functions.Function1;
import kotlin.jvm.functions.Function2;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.StringsKt;
import kotlinx.coroutines.BuildersKt;
import kotlinx.coroutines.CoroutineScope;
import kotlinx.coroutines.Dispatchers;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000J\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u000b\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u000f\n\u0002\u0010\u0002\n\u0002\b\u0002\n\u0002\u0010\u0011\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\n\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0010\u0010\f\u001a\u0004\u0018\u00010\u00042\u0006\u0010\r\u001a\u00020\u0004J\u0010\u0010\u000e\u001a\u0004\u0018\u00010\u00042\u0006\u0010\r\u001a\u00020\u0004J\u000e\u0010\u000f\u001a\u00020\u00042\u0006\u0010\r\u001a\u00020\u0004J\u0018\u0010\u0010\u001a\u00020\u00042\u0006\u0010\r\u001a\u00020\u00042\b\b\u0002\u0010\u0011\u001a\u00020\u0006J\u000e\u0010\u0012\u001a\u00020\u00042\u0006\u0010\r\u001a\u00020\u0004J\u000e\u0010\u0013\u001a\u00020\u00042\u0006\u0010\r\u001a\u00020\u0004J\u000e\u0010\u0014\u001a\u00020\u00042\u0006\u0010\u0015\u001a\u00020\u0004J\b\u0010\u0016\u001a\u00020\bH\u0002Jw\u0010\u0017\u001a\u00020\u00182\u0006\u0010\u0019\u001a\u00020\u00042\u0006\u0010\u0015\u001a\u00020\u00042\u0012\u0010\u001a\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00040\u001b\"\u00020\u00042\b\b\u0002\u0010\u001c\u001a\u00020\u001d2\u0012\u0010\u001e\u001a\u000e\u0012\u0004\u0012\u00020\u0004\u0012\u0004\u0012\u00020\u00180\u001f2\"\u0010 \u001a\u001e\b\u0001\u0012\u0004\u0012\u00020\"\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u00180#\u0012\u0006\u0012\u0004\u0018\u00010\u00010!H\u0086@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010$J\u0006\u0010%\u001a\u00020\u0018J\u0010\u0010&\u001a\u0004\u0018\u00010\u00042\u0006\u0010\r\u001a\u00020\u0004J\u000e\u0010'\u001a\u00020\u00062\u0006\u0010\r\u001a\u00020\u0004J\u0010\u0010(\u001a\u00020\u00062\b\u0010)\u001a\u0004\u0018\u00010\u0004J\u0012\u0010*\u001a\u0004\u0018\u00010\u00042\b\u0010\r\u001a\u0004\u0018\u00010\u0004J\u000e\u0010+\u001a\u00020\u00182\u0006\u0010,\u001a\u00020\u0004R\u000e\u0010\u0003\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0006X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0016\u0010\u0007\u001a\n \t*\u0004\u0018\u00010\b0\bX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\n\u001a\u00020\u0004X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000b\u001a\u00020\bX\u0082\u000e\u00a2\u0006\u0002\n\u0000\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006-"}, d2={"Ldorkbox/util/WebUtil;", "", "()V", "GOOD_IRI_CHAR", "", "MARK_URL_PATTERN_DIRTY", "", "SECOND_LEVEL_DOMAIN_PATTERN", "Ljava/util/regex/Pattern;", "kotlin.jvm.PlatformType", "TOP_LEVEL_DOMAIN_STR_FOR_WEB_URL", "WEB_URL", "cleanupAndGetNextLevelDomain", "fullDomainName", "cleanupAndGetSecondLevelDomain", "cleanupAndGetThirdLevelDomain", "cleanupAndPreservePath", "removeQueryString", "cleanupAndRemovePath", "cleanupAndRemoveWwwAndPath", "cleanupFileUri", "domain", "compileWebUrl", "fetchData", "", "scheme", "paths", "", "retryCount", "", "onError", "Lkotlin/Function1;", "onSuccess", "Lkotlin/Function2;", "Ljava/io/InputStream;", "Lkotlin/coroutines/Continuation;", "(Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;ILkotlin/jvm/functions/Function1;Lkotlin/jvm/functions/Function2;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "forceAcceptAllTlsCertificates", "getNextLevelDomain", "isSubDomain", "isValidUrl", "url", "removeWww", "updateWebUrlRegex", "topLeveDomainUrls", "Utilities"})
public final class WebUtil {
    @NotNull
    public static final WebUtil INSTANCE = new WebUtil();
    private static final Pattern SECOND_LEVEL_DOMAIN_PATTERN = Pattern.compile("^(https?:\\/\\/)?([\\dA-Za-z\\.-]+)\\.([a-z\\.]{2,6})([\\w \\.-]*)*$");
    @NotNull
    private static volatile String TOP_LEVEL_DOMAIN_STR_FOR_WEB_URL = "((aaa|aarp|abarth|abb|abbott|abbvie|abc|able|abogado|abudhabi|academy|accenture|accountant|accountants|aco|actor|adac|ads|adult|aeg|aero|aetna|afamilycompany|afl|africa|agakhan|agency|aig|airbus|airforce|airtel|akdn|alfaromeo|alibaba|alipay|allfinanz|allstate|ally|alsace|alstom|amazon|americanexpress|americanfamily|amex|amfam|amica|amsterdam|analytics|android|anquan|anz|aol|apartments|app|apple|aquarelle|arab|aramco|archi|army|arpa|art|arte|asda|asia|associates|athleta|attorney|auction|audi|audible|audio|auspost|author|auto|autos|avianca|aws|axa|azure|a[cdefgilmoqrstuwxz])|(baby|baidu|banamex|bananarepublic|band|bank|bar|barcelona|barclaycard|barclays|barefoot|bargains|baseball|basketball|bauhaus|bayern|bbc|bbt|bbva|bcg|bcn|beats|beauty|beer|bentley|berlin|best|bestbuy|bet|bharti|bible|bid|bike|bing|bingo|bio|biz|black|blackfriday|blockbuster|blog|bloomberg|blue|bms|bmw|bnpparibas|boats|boehringer|bofa|bom|bond|boo|book|booking|bosch|bostik|boston|bot|boutique|box|bradesco|bridgestone|broadway|broker|brother|brussels|budapest|bugatti|build|builders|business|buy|buzz|bzh|b[abdefghijmnorstvwyz])|(cab|cafe|cal|call|calvinklein|cam|camera|camp|cancerresearch|canon|capetown|capital|capitalone|car|caravan|cards|care|career|careers|cars|casa|case|caseih|cash|casino|cat|catering|catholic|cba|cbn|cbre|cbs|ceb|center|ceo|cern|cfa|cfd|chanel|channel|charity|chase|chat|cheap|chintai|christmas|chrome|church|cipriani|circle|cisco|citadel|citi|citic|city|cityeats|claims|cleaning|click|clinic|clinique|clothing|cloud|club|clubmed|coach|codes|coffee|college|cologne|com|comcast|commbank|community|company|compare|computer|comsec|condos|construction|consulting|contact|contractors|cooking|cookingchannel|cool|coop|corsica|country|coupon|coupons|courses|cpa|credit|creditcard|creditunion|cricket|crown|crs|cruise|cruises|csc|cuisinella|cymru|cyou|c[acdfghiklmnoruvwxyz])|(dabur|dad|dance|data|date|dating|datsun|day|dclk|dds|deal|dealer|deals|degree|delivery|dell|deloitte|delta|democrat|dental|dentist|desi|design|dev|dhl|diamonds|diet|digital|direct|directory|discount|discover|dish|diy|dnp|docs|doctor|dog|domains|dot|download|drive|dtv|dubai|duck|dunlop|dupont|durban|dvag|dvr|d[ejkmoz])|(earth|eat|eco|edeka|edu|education|email|emerck|energy|engineer|engineering|enterprises|epson|equipment|ericsson|erni|esq|estate|etisalat|eurovision|eus|events|exchange|expert|exposed|express|extraspace|e[cegrstu])|(fage|fail|fairwinds|faith|family|fan|fans|farm|farmers|fashion|fast|fedex|feedback|ferrari|ferrero|fiat|fidelity|fido|film|final|finance|financial|fire|firestone|firmdale|fish|fishing|fit|fitness|flickr|flights|flir|florist|flowers|fly|foo|food|foodnetwork|football|ford|forex|forsale|forum|foundation|fox|free|fresenius|frl|frogans|frontdoor|frontier|ftr|fujitsu|fujixerox|fun|fund|furniture|futbol|fyi|f[ijkmor])|(gal|gallery|gallo|gallup|game|games|gap|garden|gay|gbiz|gdn|gea|gent|genting|george|ggee|gift|gifts|gives|giving|glade|glass|gle|global|globo|gmail|gmbh|gmo|gmx|godaddy|gold|goldpoint|golf|goo|goodyear|goog|google|gop|got|gov|grainger|graphics|gratis|green|gripe|grocery|group|guardian|gucci|guge|guide|guitars|guru|g[abdefghilmnpqrstuwy])|(hair|hamburg|hangout|haus|hbo|hdfc|hdfcbank|health|healthcare|help|helsinki|here|hermes|hgtv|hiphop|hisamitsu|hitachi|hiv|hkt|hockey|holdings|holiday|homedepot|homegoods|homes|homesense|honda|horse|hospital|host|hosting|hot|hoteles|hotels|hotmail|house|how|hsbc|hughes|hyatt|hyundai|h[kmnrtu])|(ibm|icbc|ice|icu|ieee|ifm|ikano|imamat|imdb|immo|immobilien|inc|industries|infiniti|info|ing|ink|institute|insurance|insure|int|intel|international|intuit|investments|ipiranga|irish|ismaili|ist|istanbul|itau|itv|iveco|i[delmnoqrst])|(jaguar|java|jcb|jcp|jeep|jetzt|jewelry|jio|jll|jmp|jnj|jobs|joburg|jot|joy|jpmorgan|jprs|juegos|juniper|j[emop])|(kaufen|kddi|kerryhotels|kerrylogistics|kerryproperties|kfh|kia|kim|kinder|kindle|kitchen|kiwi|koeln|komatsu|kosher|kpmg|kpn|krd|kred|kuokgroup|kyoto|k[eghimnprwyz])|(lacaixa|lamborghini|lamer|lancaster|lancia|land|landrover|lanxess|lasalle|lat|latino|latrobe|law|lawyer|lds|lease|leclerc|lefrak|legal|lego|lexus|lgbt|lidl|life|lifeinsurance|lifestyle|lighting|like|lilly|limited|limo|lincoln|linde|link|lipsy|live|living|lixil|llc|llp|loan|loans|locker|locus|loft|lol|london|lotte|lotto|love|lpl|lplfinancial|ltd|ltda|lundbeck|lupin|luxe|luxury|l[abcikrstuvy])|(macys|madrid|maif|maison|makeup|man|management|mango|map|market|marketing|markets|marriott|marshalls|maserati|mattel|mba|mckinsey|med|media|meet|melbourne|meme|memorial|men|menu|merckmsd|miami|microsoft|mil|mini|mint|mit|mitsubishi|mlb|mls|mma|mobi|mobile|moda|moe|moi|mom|monash|money|monster|mormon|mortgage|moscow|moto|motorcycles|mov|movie|msd|mtn|mtr|museum|mutual|m[acdeghklmnopqrstuvwxyz])|(nab|nagoya|name|nationwide|natura|navy|nba|nec|net|netbank|netflix|network|neustar|new|newholland|news|next|nextdirect|nexus|nfl|ngo|nhk|nico|nike|nikon|ninja|nissan|nissay|nokia|northwesternmutual|norton|now|nowruz|nowtv|nra|nrw|ntt|nyc|n[acefgilopruz])|(obi|observer|off|office|okinawa|olayan|olayangroup|oldnavy|ollo|omega|one|ong|onl|online|onyourside|ooo|open|oracle|orange|org|organic|origins|osaka|otsuka|ott|ovh|om)|(page|panasonic|paris|pars|partners|parts|party|passagens|pay|pccw|pet|pfizer|pharmacy|phd|philips|phone|photo|photography|photos|physio|pics|pictet|pictures|pid|pin|ping|pink|pioneer|pizza|place|play|playstation|plumbing|plus|pnc|pohl|poker|politie|porn|post|pramerica|praxi|press|prime|pro|prod|productions|prof|progressive|promo|properties|property|protection|pru|prudential|pub|pwc|p[aefghklmnrstwy])|(qpon|quebec|quest|qvc|qa)|(racing|radio|raid|read|realestate|realtor|realty|recipes|red|redstone|redumbrella|rehab|reise|reisen|reit|reliance|ren|rent|rentals|repair|report|republican|rest|restaurant|review|reviews|rexroth|rich|richardli|ricoh|ril|rio|rip|rmit|rocher|rocks|rodeo|rogers|room|rsvp|rugby|ruhr|run|rwe|ryukyu|r[eosuw])|(saarland|safe|safety|sakura|sale|salon|samsclub|samsung|sandvik|sandvikcoromant|sanofi|sap|sarl|sas|save|saxo|sbi|sbs|sca|scb|schaeffler|schmidt|scholarships|school|schule|schwarz|science|scjohnson|scot|search|seat|secure|security|seek|select|sener|services|ses|seven|sew|sex|sexy|sfr|shangrila|sharp|shaw|shell|shia|shiksha|shoes|shop|shopping|shouji|show|showtime|shriram|silk|sina|singles|site|ski|skin|sky|skype|sling|smart|smile|sncf|soccer|social|softbank|software|sohu|solar|solutions|song|sony|soy|space|sport|spot|spreadbetting|srl|stada|staples|star|statebank|statefarm|stc|stcgroup|stockholm|storage|store|stream|studio|study|style|sucks|supplies|supply|support|surf|surgery|suzuki|swatch|swiftcover|swiss|sydney|systems|s[abcdeghijklmnorstuvxyz])|(tab|taipei|talk|taobao|target|tatamotors|tatar|tattoo|tax|taxi|tci|tdk|team|tech|technology|tel|temasek|tennis|teva|thd|theater|theatre|tiaa|tickets|tienda|tiffany|tips|tires|tirol|tjmaxx|tjx|tkmaxx|tmall|today|tokyo|tools|top|toray|toshiba|total|tours|town|toyota|toys|trade|trading|training|travel|travelchannel|travelers|travelersinsurance|trust|trv|tube|tui|tunes|tushu|tvs|t[cdfghjklmnortvwz])|(ubank|ubs|unicom|university|uno|uol|ups|u[agksyz])|(vacations|vana|vanguard|vegas|ventures|verisign|versicherung|vet|viajes|video|vig|viking|villas|vin|vip|virgin|visa|vision|viva|vivo|vlaanderen|vodka|volkswagen|volvo|vote|voting|voto|voyage|vuelos|v[aceginu])|(wales|walmart|walter|wang|wanggou|watch|watches|weather|weatherchannel|webcam|weber|website|wed|wedding|weibo|weir|whoswho|wien|wiki|williamhill|win|windows|wine|winners|wme|wolterskluwer|woodside|work|works|world|wow|wtc|wtf|w[fs])|(xbox|xerox|xfinity|xihuan|xin|xn\\-\\-11b4c3d|xn\\-\\-1ck2e1b|xn\\-\\-1qqw23a|xn\\-\\-2scrj9c|xn\\-\\-30rr7y|xn\\-\\-3bst00m|xn\\-\\-3ds443g|xn\\-\\-3e0b707e|xn\\-\\-3hcrj9c|xn\\-\\-3oq18vl8pn36a|xn\\-\\-3pxu8k|xn\\-\\-42c2d9a|xn\\-\\-45br5cyl|xn\\-\\-45brj9c|xn\\-\\-45q11c|xn\\-\\-4gbrim|xn\\-\\-54b7fta0cc|xn\\-\\-55qw42g|xn\\-\\-55qx5d|xn\\-\\-5su34j936bgsg|xn\\-\\-5tzm5g|xn\\-\\-6frz82g|xn\\-\\-6qq986b3xl|xn\\-\\-80adxhks|xn\\-\\-80ao21a|xn\\-\\-80aqecdr1a|xn\\-\\-80asehdb|xn\\-\\-80aswg|xn\\-\\-8y0a063a|xn\\-\\-90a3ac|xn\\-\\-90ae|xn\\-\\-90ais|xn\\-\\-9dbq2a|xn\\-\\-9et52u|xn\\-\\-9krt00a|xn\\-\\-b4w605ferd|xn\\-\\-bck1b9a5dre4c|xn\\-\\-c1avg|xn\\-\\-c2br7g|xn\\-\\-cck2b3b|xn\\-\\-cckwcxetd|xn\\-\\-cg4bki|xn\\-\\-clchc0ea0b2g2a9gcd|xn\\-\\-czr694b|xn\\-\\-czrs0t|xn\\-\\-czru2d|xn\\-\\-d1acj3b|xn\\-\\-d1alf|xn\\-\\-e1a4c|xn\\-\\-eckvdtc9d|xn\\-\\-efvy88h|xn\\-\\-fct429k|xn\\-\\-fhbei|xn\\-\\-fiq228c5hs|xn\\-\\-fiq64b|xn\\-\\-fiqs8s|xn\\-\\-fiqz9s|xn\\-\\-fjq720a|xn\\-\\-flw351e|xn\\-\\-fpcrj9c3d|xn\\-\\-fzc2c9e2c|xn\\-\\-fzys8d69uvgm|xn\\-\\-g2xx48c|xn\\-\\-gckr3f0f|xn\\-\\-gecrj9c|xn\\-\\-gk3at1e|xn\\-\\-h2breg3eve|xn\\-\\-h2brj9c|xn\\-\\-h2brj9c8c|xn\\-\\-hxt814e|xn\\-\\-i1b6b1a6a2e|xn\\-\\-imr513n|xn\\-\\-io0a7i|xn\\-\\-j1aef|xn\\-\\-j1amh|xn\\-\\-j6w193g|xn\\-\\-jlq480n2rg|xn\\-\\-jlq61u9w7b|xn\\-\\-jvr189m|xn\\-\\-kcrx77d1x4a|xn\\-\\-kprw13d|xn\\-\\-kpry57d|xn\\-\\-kput3i|xn\\-\\-l1acc|xn\\-\\-lgbbat1ad8j|xn\\-\\-mgb9awbf|xn\\-\\-mgba3a3ejt|xn\\-\\-mgba3a4f16a|xn\\-\\-mgba7c0bbn0a|xn\\-\\-mgbaakc7dvf|xn\\-\\-mgbaam7a8h|xn\\-\\-mgbab2bd|xn\\-\\-mgbah1a3hjkrd|xn\\-\\-mgbai9azgqp6j|xn\\-\\-mgbayh7gpa|xn\\-\\-mgbbh1a|xn\\-\\-mgbbh1a71e|xn\\-\\-mgbc0a9azcg|xn\\-\\-mgbca7dzdo|xn\\-\\-mgbcpq6gpa1a|xn\\-\\-mgberp4a5d4ar|xn\\-\\-mgbgu82a|xn\\-\\-mgbi4ecexp|xn\\-\\-mgbpl2fh|xn\\-\\-mgbt3dhd|xn\\-\\-mgbtx2b|xn\\-\\-mgbx4cd0ab|xn\\-\\-mix891f|xn\\-\\-mk1bu44c|xn\\-\\-mxtq1m|xn\\-\\-ngbc5azd|xn\\-\\-ngbe9e0a|xn\\-\\-ngbrx|xn\\-\\-node|xn\\-\\-nqv7f|xn\\-\\-nqv7fs00ema|xn\\-\\-nyqy26a|xn\\-\\-o3cw4h|xn\\-\\-ogbpf8fl|xn\\-\\-otu796d|xn\\-\\-p1acf|xn\\-\\-p1ai|xn\\-\\-pgbs0dh|xn\\-\\-pssy2u|xn\\-\\-q7ce6a|xn\\-\\-q9jyb4c|xn\\-\\-qcka1pmc|xn\\-\\-qxa6a|xn\\-\\-qxam|xn\\-\\-rhqv96g|xn\\-\\-rovu88b|xn\\-\\-rvc1e0am3e|xn\\-\\-s9brj9c|xn\\-\\-ses554g|xn\\-\\-t60b56a|xn\\-\\-tckwe|xn\\-\\-tiq49xqyj|xn\\-\\-unup4y|xn\\-\\-vermgensberater\\-ctb|xn\\-\\-vermgensberatung\\-pwb|xn\\-\\-vhquv|xn\\-\\-vuq861b|xn\\-\\-w4r85el8fhu5dnra|xn\\-\\-w4rs40l|xn\\-\\-wgbh1c|xn\\-\\-wgbl6a|xn\\-\\-xhq521b|xn\\-\\-xkc2al3hye2a|xn\\-\\-xkc2dl3a5ee0h|xn\\-\\-y9a3aq|xn\\-\\-yfro4i67o|xn\\-\\-ygbi2ammx|xn\\-\\-zfr164b|xxx|xyz)|(yachts|yahoo|yamaxun|yandex|yodobashi|yoga|yokohama|you|youtube|yun|y[et])|(zappos|zara|zero|zip|zone|zuerich|z[amw])))";
    @NotNull
    public static final String GOOD_IRI_CHAR = "a-zA-Z0-9\u00a0-\ud7ff\uf900-\ufdcf\ufdf0-\uffef";
    private static volatile boolean MARK_URL_PATTERN_DIRTY;
    @NotNull
    private static volatile Pattern WEB_URL;

    private WebUtil() {
    }

    public final void updateWebUrlRegex(@NotNull String topLeveDomainUrls) {
        Intrinsics.checkNotNullParameter((Object)topLeveDomainUrls, (String)"topLeveDomainUrls");
        TOP_LEVEL_DOMAIN_STR_FOR_WEB_URL = topLeveDomainUrls;
        MARK_URL_PATTERN_DIRTY = true;
    }

    private final Pattern compileWebUrl() {
        Pattern pattern = Pattern.compile("((?:(http|https|Http|Https|rtsp|Rtsp):\\/\\/(?:(?:[a-zA-Z0-9\\$\\-\\_\\.\\+\\!\\*\\'\\(\\)\\,\\;\\?\\&\\=]|(?:\\%[a-fA-F0-9]{2})){1,64}(?:\\:(?:[a-zA-Z0-9\\$\\-\\_\\.\\+\\!\\*\\'\\(\\)\\,\\;\\?\\&\\=]|(?:\\%[a-fA-F0-9]{2})){1,25})?\\@)?)?((?:(?:[a-zA-Z0-9\u00a0-\ud7ff\uf900-\ufdcf\ufdf0-\uffef][a-zA-Z0-9\u00a0-\ud7ff\uf900-\ufdcf\ufdf0-\uffef\\-]{0,64}\\.)+" + TOP_LEVEL_DOMAIN_STR_FOR_WEB_URL + "|(?:(?:25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9])\\.(?:25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\\.(?:25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\\.(?:25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[0-9])))(?:\\:\\d{1,5})?)(\\/(?:(?:[a-zA-Z0-9\\;\\/\\?\\:\\@\\&\\=\\#\\~\\-\\.\\+\\!\\*\\'\\(\\)\\,\\_])|(?:\\%[a-fA-F0-9]{2}))*)?(?:\\b|$)");
        Intrinsics.checkNotNullExpressionValue((Object)pattern, (String)"compile(\n            \"((\u2026           + \"(?:\\\\b|$)\")");
        return pattern;
    }

    @NotNull
    public final String cleanupAndRemovePath(@NotNull String fullDomainName) {
        int question;
        int ampersand;
        int percent;
        int colon;
        Intrinsics.checkNotNullParameter((Object)fullDomainName, (String)"fullDomainName");
        int start = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"://", (int)0, (boolean)false, (int)6, null);
        start = start == -1 ? 0 : (start += 3);
        int end = fullDomainName.length();
        int slash = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"/", (int)(start + 3), (boolean)false, (int)4, null);
        if (slash > -1 && slash < end) {
            end = slash;
        }
        if ((colon = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)":", (int)(start + 3), (boolean)false, (int)4, null)) > -1 && colon < end) {
            end = colon;
        }
        if ((percent = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"%", (int)start, (boolean)false, (int)4, null)) > -1 && percent < end) {
            end = percent;
        }
        if ((ampersand = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"&", (int)start, (boolean)false, (int)4, null)) > -1 && ampersand < end) {
            end = ampersand;
        }
        if ((question = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"?", (int)start, (boolean)false, (int)4, null)) > -1 && question < end) {
            end = question;
        }
        String string = fullDomainName.substring(0, end);
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
        return string;
    }

    @NotNull
    public final String cleanupAndRemoveWwwAndPath(@NotNull String fullDomainName) {
        int question;
        int ampersand;
        int percent;
        int colon;
        int star;
        Intrinsics.checkNotNullParameter((Object)fullDomainName, (String)"fullDomainName");
        int start = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"://", (int)0, (boolean)false, (int)6, null);
        start = start == -1 ? 0 : (start += 3);
        int www = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"www.", (int)start, (boolean)false, (int)4, null);
        if (www > -1 && www <= 8) {
            start = www + 4;
        }
        if ((star = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"*.", (int)start, (boolean)false, (int)4, null)) > -1) {
            start = star + 2;
        }
        int end = fullDomainName.length();
        int slash = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"/", (int)(start + 3), (boolean)false, (int)4, null);
        if (slash > -1 && slash < end) {
            end = slash;
        }
        if ((colon = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)":", (int)(start + 3), (boolean)false, (int)4, null)) > -1 && colon < end) {
            end = colon;
        }
        if ((percent = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"%", (int)start, (boolean)false, (int)4, null)) > -1 && percent < end) {
            end = percent;
        }
        if ((ampersand = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"&", (int)start, (boolean)false, (int)4, null)) > -1 && ampersand < end) {
            end = ampersand;
        }
        if ((question = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"?", (int)start, (boolean)false, (int)4, null)) > -1 && question < end) {
            end = question;
        }
        String string = fullDomainName.substring(start, end);
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
        return string;
    }

    @NotNull
    public final String cleanupAndPreservePath(@NotNull String fullDomainName, boolean removeQueryString) {
        int end;
        int n;
        int star;
        Intrinsics.checkNotNullParameter((Object)fullDomainName, (String)"fullDomainName");
        int start = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"://", (int)0, (boolean)false, (int)6, null);
        start = start == -1 ? 0 : (start += 3);
        int www = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"www.", (int)start, (boolean)false, (int)4, null);
        if (www > -1 && www <= 8) {
            start = www + 4;
        }
        if ((star = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"*.", (int)start, (boolean)false, (int)4, null)) > -1) {
            start = star + 2;
        }
        if (removeQueryString) {
            int question;
            int ampersand;
            int end2 = fullDomainName.length();
            int percent = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"%", (int)start, (boolean)false, (int)4, null);
            if (percent > -1 && percent < end2) {
                end2 = percent;
            }
            if ((ampersand = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"&", (int)start, (boolean)false, (int)4, null)) > -1 && ampersand < end2) {
                end2 = ampersand;
            }
            if ((question = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"?", (int)start, (boolean)false, (int)4, null)) > -1 && question < end2) {
                end2 = question;
            }
            n = end2;
        } else {
            n = end = fullDomainName.length();
        }
        if (end - 1 >= 0 && fullDomainName.charAt(end - 1) == '/') {
            --end;
        }
        String string = fullDomainName.substring(start, end);
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
        return string;
    }

    public static /* synthetic */ String cleanupAndPreservePath$default(WebUtil webUtil, String string, boolean bl, int n, Object object) {
        if ((n & 2) != 0) {
            bl = true;
        }
        return webUtil.cleanupAndPreservePath(string, bl);
    }

    @Nullable
    public final String removeWww(@Nullable String fullDomainName) {
        int percent;
        int end;
        if (fullDomainName == null) {
            return null;
        }
        int start = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"www.", (int)0, (boolean)false, (int)6, null);
        start = start > -1 ? (start += 4) : 0;
        int star = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"*.", (int)start, (boolean)false, (int)4, null);
        if (star > -1) {
            start = star + 2;
        }
        if ((end = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"/", (int)(start + 3), (boolean)false, (int)4, null)) == -1) {
            if (start == 0) {
                return fullDomainName;
            }
            end = fullDomainName.length();
        }
        if ((percent = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"%", (int)start, (boolean)false, (int)4, null)) > -1 && percent < end) {
            end = percent;
        }
        String string = fullDomainName.substring(start, end);
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
        return string;
    }

    public final boolean isValidUrl(@Nullable String url) {
        boolean bl;
        CharSequence charSequence = url;
        if (charSequence == null || charSequence.length() == 0) {
            bl = false;
        } else {
            if (MARK_URL_PATTERN_DIRTY) {
                WEB_URL = this.compileWebUrl();
                MARK_URL_PATTERN_DIRTY = false;
            }
            Matcher m = WEB_URL.matcher(url);
            bl = m.matches();
        }
        return bl;
    }

    public final boolean isSubDomain(@NotNull String fullDomainName) {
        int end;
        Intrinsics.checkNotNullParameter((Object)fullDomainName, (String)"fullDomainName");
        int start = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"://", (int)0, (boolean)false, (int)6, null);
        start = start == -1 ? 0 : (start += 3);
        if (StringsKt.contains$default((CharSequence)fullDomainName, (CharSequence)"www.", (boolean)false, (int)2, null)) {
            start += 4;
        }
        if ((end = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"/", (int)(start + 3), (boolean)false, (int)4, null)) == -1) {
            end = fullDomainName.length();
        }
        String string = fullDomainName.substring(start, end);
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
        String substring = string;
        CharSequence $this$count$iv = substring;
        boolean $i$f$count = false;
        int count$iv = 0;
        for (int i = 0; i < $this$count$iv.length(); ++i) {
            char element$iv;
            char it = element$iv = $this$count$iv.charAt(i);
            boolean bl = false;
            if (!(it == '.')) continue;
            ++count$iv;
        }
        int dots = count$iv;
        return dots > 1;
    }

    @Nullable
    public final String cleanupAndGetNextLevelDomain(@NotNull String fullDomainName) {
        String substring;
        int end;
        Intrinsics.checkNotNullParameter((Object)fullDomainName, (String)"fullDomainName");
        int start = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"://", (int)0, (boolean)false, (int)6, null);
        start = start == -1 ? 0 : (start += 3);
        if (StringsKt.contains$default((CharSequence)fullDomainName, (CharSequence)"www.", (boolean)false, (int)2, null)) {
            start += 4;
        }
        if ((end = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"/", (int)(start + 3), (boolean)false, (int)4, null)) == -1) {
            end = fullDomainName.length();
        }
        String string = fullDomainName.substring(start, end);
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
        String last = substring = string;
        int nextDot = StringsKt.indexOf$default((CharSequence)substring, (String)".", (int)0, (boolean)false, (int)6, null);
        if (nextDot == -1) {
            return null;
        }
        String string2 = substring.substring(nextDot + 1);
        Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"this as java.lang.String).substring(startIndex)");
        substring = string2;
        if (Dns.INSTANCE.isTLD(substring)) {
            substring = last;
        }
        return substring;
    }

    @Nullable
    public final String getNextLevelDomain(@NotNull String fullDomainName) {
        Intrinsics.checkNotNullParameter((Object)fullDomainName, (String)"fullDomainName");
        int nextDot = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)".", (int)0, (boolean)false, (int)6, null);
        if (nextDot == -1) {
            return null;
        }
        String string = fullDomainName.substring(nextDot + 1);
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String).substring(startIndex)");
        return string;
    }

    @Nullable
    public final String cleanupAndGetSecondLevelDomain(@NotNull String fullDomainName) {
        Intrinsics.checkNotNullParameter((Object)fullDomainName, (String)"fullDomainName");
        if (StringsKt.startsWith((String)fullDomainName, (String)"file://", (boolean)true)) {
            return null;
        }
        int start = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"://", (int)0, (boolean)false, (int)6, null);
        start = start == -1 ? 0 : (start += 3);
        int end = StringsKt.indexOf$default((CharSequence)fullDomainName, (String)"/", (int)(start + 3), (boolean)false, (int)4, null);
        if (end == -1) {
            if (start == 0) {
                return Dns.INSTANCE.extractSLD(fullDomainName);
            }
            end = fullDomainName.length();
        }
        String string = fullDomainName.substring(start, end);
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
        String substring = string;
        return Dns.INSTANCE.extractSLD(substring);
    }

    @NotNull
    public final String cleanupAndGetThirdLevelDomain(@NotNull String fullDomainName) {
        Intrinsics.checkNotNullParameter((Object)fullDomainName, (String)"fullDomainName");
        String cleanDomain = this.cleanupAndRemoveWwwAndPath(fullDomainName);
        CharSequence $this$count$iv = cleanDomain;
        boolean $i$f$count = false;
        int count$iv = 0;
        for (int i = 0; i < $this$count$iv.length(); ++i) {
            char element$iv;
            char it = element$iv = $this$count$iv.charAt(i);
            boolean bl = false;
            if (!(it == '.')) continue;
            ++count$iv;
        }
        int periodCount = count$iv;
        if (periodCount <= 2) {
            return cleanDomain;
        }
        for (int x = periodCount; 2 < x; --x) {
            int nextDot = StringsKt.indexOf$default((CharSequence)cleanDomain, (String)".", (int)0, (boolean)false, (int)6, null);
            Intrinsics.checkNotNullExpressionValue((Object)cleanDomain.substring(nextDot + 1), (String)"this as java.lang.String).substring(startIndex)");
        }
        return cleanDomain;
    }

    @NotNull
    public final String cleanupFileUri(@NotNull String domain) {
        Intrinsics.checkNotNullParameter((Object)domain, (String)"domain");
        int lastSlashIndex = StringsKt.lastIndexOf$default((CharSequence)domain, (String)"/", (int)0, (boolean)false, (int)6, null);
        if (lastSlashIndex == -1) {
            return domain;
        }
        String string = domain.substring(lastSlashIndex + 1);
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String).substring(startIndex)");
        return string;
    }

    public final void forceAcceptAllTlsCertificates() {
        TrustManager[] trustManagerArray = new TrustManager[]{new X509TrustManager(){

            @Nullable
            public X509Certificate[] getAcceptedIssuers() {
                return null;
            }

            public void checkClientTrusted(@NotNull X509Certificate[] certs, @NotNull String authType) {
                Intrinsics.checkNotNullParameter((Object)certs, (String)"certs");
                Intrinsics.checkNotNullParameter((Object)authType, (String)"authType");
            }

            public void checkServerTrusted(@NotNull X509Certificate[] certs, @NotNull String authType) {
                Intrinsics.checkNotNullParameter((Object)certs, (String)"certs");
                Intrinsics.checkNotNullParameter((Object)authType, (String)"authType");
            }
        }};
        TrustManager[] trustAllCerts2 = trustManagerArray;
        SSLContext sc = SSLContext.getInstance("SSL");
        sc.init(null, trustAllCerts2, new SecureRandom());
        HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
        HostnameVerifier allHostsValid = WebUtil::forceAcceptAllTlsCertificates$lambda$2;
        HttpsURLConnection.setDefaultHostnameVerifier(allHostsValid);
    }

    @Nullable
    public final Object fetchData(@NotNull String scheme, @NotNull String domain, @NotNull String[] paths, int retryCount, @NotNull Function1<? super String, Unit> onError, @NotNull Function2<? super InputStream, ? super Continuation<? super Unit>, ? extends Object> onSuccess, @NotNull Continuation<? super Unit> $completion) {
        Object object = BuildersKt.withContext((CoroutineContext)((CoroutineContext)Dispatchers.getIO()), (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super Unit>, Object>(paths, scheme, domain, retryCount, onError, onSuccess, null){
            Object L$0;
            Object L$1;
            int label;
            final /* synthetic */ String[] $paths;
            final /* synthetic */ String $scheme;
            final /* synthetic */ String $domain;
            final /* synthetic */ int $retryCount;
            final /* synthetic */ Function1<String, Unit> $onError;
            final /* synthetic */ Function2<InputStream, Continuation<? super Unit>, Object> $onSuccess;
            {
                this.$paths = $paths;
                this.$scheme = $scheme;
                this.$domain = $domain;
                this.$retryCount = $retryCount;
                this.$onError = $onError;
                this.$onSuccess = $onSuccess;
                super(2, $completion);
            }

            /*
             * Exception decompiling
             */
            @Nullable
            public final Object invokeSuspend(@NotNull Object var1_1) {
                /*
                 * This method has failed to decompile.  When submitting a bug report, please provide this stack trace, and (if you hold appropriate legal rights) the relevant class file.
                 * 
                 * org.benf.cfr.reader.util.ConfusedCFRException: Tried to end blocks [0[TRYBLOCK]], but top level block is 11[CASE]
                 *     at org.benf.cfr.reader.bytecode.analysis.opgraph.Op04StructuredStatement.processEndingBlocks(Op04StructuredStatement.java:435)
                 *     at org.benf.cfr.reader.bytecode.analysis.opgraph.Op04StructuredStatement.buildNestedBlocks(Op04StructuredStatement.java:484)
                 *     at org.benf.cfr.reader.bytecode.analysis.opgraph.Op03SimpleStatement.createInitialStructuredBlock(Op03SimpleStatement.java:736)
                 *     at org.benf.cfr.reader.bytecode.CodeAnalyser.getAnalysisInner(CodeAnalyser.java:850)
                 *     at org.benf.cfr.reader.bytecode.CodeAnalyser.getAnalysisOrWrapFail(CodeAnalyser.java:278)
                 *     at org.benf.cfr.reader.bytecode.CodeAnalyser.getAnalysis(CodeAnalyser.java:201)
                 *     at org.benf.cfr.reader.entities.attributes.AttributeCode.analyse(AttributeCode.java:94)
                 *     at org.benf.cfr.reader.entities.Method.dump(Method.java:598)
                 *     at org.benf.cfr.reader.entities.classfilehelpers.ClassFileDumperAnonymousInner.dumpWithArgs(ClassFileDumperAnonymousInner.java:87)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.ConstructorInvokationAnonymousInner.dumpInner(ConstructorInvokationAnonymousInner.java:82)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.AbstractExpression.dumpWithOuterPrecedence(AbstractExpression.java:142)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.CastExpression.dumpInner(CastExpression.java:114)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.AbstractExpression.dumpWithOuterPrecedence(AbstractExpression.java:139)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.CastExpression.dumpInner(CastExpression.java:114)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.AbstractExpression.dumpWithOuterPrecedence(AbstractExpression.java:142)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.AbstractExpression.dump(AbstractExpression.java:98)
                 *     at org.benf.cfr.reader.state.TypeUsageCollectingDumper.dump(TypeUsageCollectingDumper.java:194)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.StaticFunctionInvokation.dumpInner(StaticFunctionInvokation.java:143)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.AbstractExpression.dumpWithOuterPrecedence(AbstractExpression.java:142)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.AbstractExpression.dump(AbstractExpression.java:98)
                 *     at org.benf.cfr.reader.state.TypeUsageCollectingDumper.dump(TypeUsageCollectingDumper.java:194)
                 *     at org.benf.cfr.reader.bytecode.analysis.structured.statement.StructuredAssignment.dump(StructuredAssignment.java:69)
                 *     at org.benf.cfr.reader.state.TypeUsageCollectingDumper.dump(TypeUsageCollectingDumper.java:194)
                 *     at org.benf.cfr.reader.bytecode.analysis.opgraph.Op04StructuredStatement.dump(Op04StructuredStatement.java:220)
                 *     at org.benf.cfr.reader.bytecode.analysis.structured.statement.Block.dump(Block.java:564)
                 *     at org.benf.cfr.reader.state.TypeUsageCollectingDumper.dump(TypeUsageCollectingDumper.java:194)
                 *     at org.benf.cfr.reader.bytecode.analysis.opgraph.Op04StructuredStatement.dump(Op04StructuredStatement.java:220)
                 *     at org.benf.cfr.reader.entities.attributes.AttributeCode.dump(AttributeCode.java:135)
                 *     at org.benf.cfr.reader.state.TypeUsageCollectingDumper.dump(TypeUsageCollectingDumper.java:194)
                 *     at org.benf.cfr.reader.entities.Method.dump(Method.java:627)
                 *     at org.benf.cfr.reader.entities.classfilehelpers.AbstractClassFileDumper.dumpMethods(AbstractClassFileDumper.java:211)
                 *     at org.benf.cfr.reader.entities.classfilehelpers.ClassFileDumperNormal.dump(ClassFileDumperNormal.java:70)
                 *     at org.benf.cfr.reader.entities.ClassFile.dump(ClassFile.java:1167)
                 *     at org.benf.cfr.reader.entities.ClassFile.analyseTop(ClassFile.java:952)
                 *     at org.benf.cfr.reader.Driver.doJarVersionTypes(Driver.java:257)
                 *     at org.benf.cfr.reader.Driver.doJar(Driver.java:139)
                 *     at org.benf.cfr.reader.CfrDriverImpl.analyse(CfrDriverImpl.java:76)
                 *     at org.benf.cfr.reader.Main.main(Main.java:54)
                 */
                throw new IllegalStateException("Decompilation failed");
            }

            @NotNull
            public final Continuation<Unit> create(@Nullable Object value, @NotNull Continuation<?> $completion) {
                return (Continuation)new /* invalid duplicate definition of identical inner class */;
            }

            @Nullable
            public final Object invoke(@NotNull CoroutineScope p1, @Nullable Continuation<? super Unit> p2) {
                return (this.create(p1, p2)).invokeSuspend(Unit.INSTANCE);
            }
        }), $completion);
        if (object == IntrinsicsKt.getCOROUTINE_SUSPENDED()) {
            return object;
        }
        return Unit.INSTANCE;
    }

    public static /* synthetic */ Object fetchData$default(WebUtil webUtil, String string, String string2, String[] stringArray, int n, Function1 function1, Function2 function2, Continuation continuation, int n2, Object object) {
        if ((n2 & 8) != 0) {
            n = 10;
        }
        return webUtil.fetchData(string, string2, stringArray, n, (Function1<? super String, Unit>)function1, (Function2<? super InputStream, ? super Continuation<? super Unit>, ? extends Object>)function2, (Continuation<? super Unit>)continuation);
    }

    private static final boolean forceAcceptAllTlsCertificates$lambda$2(String string, SSLSession sSLSession) {
        return true;
    }

    static {
        WEB_URL = INSTANCE.compileWebUrl();
    }
}

