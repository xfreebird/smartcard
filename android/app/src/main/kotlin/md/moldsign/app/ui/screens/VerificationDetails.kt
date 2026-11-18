package md.moldsign.app.ui.screens

import md.moldsign.app.hostActivity
import md.moldsign.app.ui.components.signatureLabels
import md.moldsign.app.ui.components.CertificateLabels
import androidx.annotation.StringRes
import androidx.compose.foundation.relocation.BringIntoViewRequester
import androidx.compose.foundation.relocation.bringIntoViewRequester
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.ExpandLess
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.WarningAmber
import androidx.compose.material3.Surface
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import md.moldsign.app.application.VerifyOutcome
import md.moldsign.app.R
import md.moldsign.app.ui.theme.LocalStatusColors
import md.moldsign.app.ui.theme.Tokens
import md.moldsign.core.ValidationReport
import md.moldsign.core.Verdict
import java.text.DateFormat

/** docs/10 VerdictBadge: a large icon and the verdict in words (color is never the only signal). */
@Composable
internal fun VerdictBadge(outcome: VerifyOutcome) {
    val captureIntent = LocalContext.current.hostActivity()?.intent
    val captureTarget = md.moldsign.app.DemoMode.screenshotCapture(captureIntent) &&
        captureIntent?.getStringExtra("demo")?.startsWith("verify-") == true &&
        captureIntent.getStringExtra("demo") != "verify-xml-missing" && captureIntent.getStringExtra("capture_expand") == null
    val capturePosition = remember { BringIntoViewRequester() }
    LaunchedEffect(captureTarget) {
        if (captureTarget) {
            androidx.compose.runtime.withFrameNanos { }
            capturePosition.bringIntoView()
            android.util.Log.i("MoldSignDemo", "capture-scroll-ready:verify")
        }
    }
    val colors = LocalStatusColors.current
    val (icon, tint, title, body) = when (outcome.verdict) {
        Verdict.Valid -> Verdict4(Icons.Outlined.CheckCircle, colors.success, R.string.verdict_valid, R.string.verdict_valid_body)
        Verdict.Invalid -> Verdict4(Icons.Outlined.ErrorOutline, colors.danger, R.string.verdict_invalid, R.string.verdict_invalid_body)
        Verdict.Unconfirmed -> Verdict4(
            Icons.Outlined.WarningAmber, colors.warning, R.string.verdict_unconfirmed,
            if (outcome.missingDocuments.isNotEmpty()) R.string.verdict_unconfirmed_documents else R.string.verdict_unconfirmed_chain,
        )
        Verdict.NoSignature -> Verdict4(Icons.Outlined.Info, MaterialTheme.colorScheme.onSurfaceVariant, R.string.verdict_none, R.string.verdict_none_body)
    }
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        shape = RoundedCornerShape(Tokens.RadiusCard),
        modifier = Modifier.fillMaxWidth().bringIntoViewRequester(capturePosition),
    ) {
        Row(Modifier.padding(Tokens.S4), horizontalArrangement = Arrangement.spacedBy(Tokens.S3), verticalAlignment = Alignment.CenterVertically) {
            Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(40.dp))
            Column {
                Text(stringResource(title), style = MaterialTheme.typography.titleLarge)
                Text(stringResource(body), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

private data class Verdict4(val icon: ImageVector, val tint: Color, @StringRes val title: Int, @StringRes val body: Int)

/** A detached XAdES signature names the file it signed: the user picks it (the document is matched by file name). */
@Composable
internal fun MissingDocuments(names: List<String>, onPick: () -> Unit) {
    val captureIntent = LocalContext.current.hostActivity()?.intent
    val captureTarget = md.moldsign.app.DemoMode.screenshotCapture(captureIntent) && captureIntent?.getStringExtra("demo") == "verify-xml-missing"
    val capturePosition = remember { BringIntoViewRequester() }
    LaunchedEffect(captureTarget) {
        if (captureTarget) {
            androidx.compose.runtime.withFrameNanos { }
            capturePosition.bringIntoView()
            android.util.Log.i("MoldSignDemo", "capture-scroll-ready:verify")
        }
    }
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        shape = RoundedCornerShape(Tokens.RadiusCard),
        modifier = Modifier.fillMaxWidth().bringIntoViewRequester(capturePosition),
    ) {
        Column(Modifier.padding(Tokens.S4), verticalArrangement = Arrangement.spacedBy(Tokens.S3)) {
            Text(stringResource(R.string.verify_needs_document, names.joinToString()), style = MaterialTheme.typography.bodyMedium)
            FilledTonalButton(onClick = onPick) { Text(stringResource(R.string.verify_add_document)) }
        }
    }
}

/** docs/10 SignatureCard: signer, times and level, the three check chips and a technical-details disclosure. */
@OptIn(ExperimentalLayoutApi::class, androidx.compose.ui.ExperimentalComposeUiApi::class)
@Composable
internal fun SignatureCard(report: ValidationReport) {
    val captureIntent = LocalContext.current.hostActivity()?.intent
    val captureExpand = if (md.moldsign.app.DemoMode.screenshotCapture(captureIntent)) captureIntent?.getStringExtra("capture_expand") else null
    var certificateExpanded by remember(report, captureExpand) { mutableStateOf(captureExpand == "certificate") }
    var details by remember(report, captureExpand) { mutableStateOf(captureExpand == "technical") }
    val expandedState = stringResource(R.string.state_expanded)
    val collapsedState = stringResource(R.string.state_collapsed)
    val locale = androidx.compose.ui.platform.LocalConfiguration.current.locales.get(0)
    val dateTime = remember(locale) { DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT, locale) }
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        shape = RoundedCornerShape(Tokens.RadiusCard),
        modifier = Modifier.fillMaxWidth().semantics { testTagsAsResourceId = true },
    ) {
        Column(Modifier.padding(Tokens.S4), verticalArrangement = Arrangement.spacedBy(Tokens.S2)) {
            Text(stringResource(R.string.sig_author, report.signerName ?: stringResource(R.string.sig_unknown_signer)), style = MaterialTheme.typography.titleMedium)
            report.signerIdnp?.let { Text("IDNP: $it") }
            report.level?.let { Text(signatureLabels(it), style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant) }
            report.signingTime?.let { Text(stringResource(R.string.sig_signed_at, dateTime.format(it)), style = MaterialTheme.typography.bodyMedium) }
            report.timestampTime?.let { Text(stringResource(R.string.sig_timestamp, dateTime.format(it)), style = MaterialTheme.typography.bodyMedium) }
            FlowRow(horizontalArrangement = Arrangement.spacedBy(Tokens.S2), verticalArrangement = Arrangement.spacedBy(Tokens.S2)) {
                CheckChip(R.string.sig_integrity, if (report.missingDocuments.isNotEmpty()) null else report.integrityOk)
                CheckChip(R.string.sig_signature, report.signatureOk)
                CheckChip(R.string.sig_chain, report.chainOk)
            }
            if (report.certificateDetails.isNotEmpty()) {
                HorizontalDivider()
                DisclosureButton(R.string.sig_certificate_details, certificateExpanded, "verify.certificateToggle",
                    if (certificateExpanded) expandedState else collapsedState) { certificateExpanded = !certificateExpanded }
                if (certificateExpanded) Column(Modifier.testTag("verify.certificateContents")) {
                    report.certificateDetails.forEach { (key, value) ->
                        Text("${CertificateLabels.label(key)}: $value", style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
            if (report.details.isNotEmpty()) {
                HorizontalDivider()
                DisclosureButton(R.string.sig_details, details, "verify.technicalToggle",
                    if (details) expandedState else collapsedState) { details = !details }
                if (details) {
                    Text(signatureLabels(report.details.joinToString("\n")), modifier = Modifier.testTag("verify.technicalContents"), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}

@Composable
private fun DisclosureButton(@StringRes label: Int, expanded: Boolean, tag: String, state: String, onClick: () -> Unit) {
    TextButton(onClick = onClick, modifier = Modifier.fillMaxWidth().testTag(tag).semantics { stateDescription = state },
        contentPadding = PaddingValues(horizontal = 0.dp)) {
        Text(stringResource(label), modifier = Modifier.weight(1f))
        Icon(if (expanded) Icons.Outlined.ExpandLess else Icons.Outlined.ExpandMore, null)
    }
}

/** [ok] `null` = could not be checked (unknown chain, missing document): a warning, not a failure. */
@Composable
private fun CheckChip(@StringRes label: Int, ok: Boolean?) {
    val colors = LocalStatusColors.current
    val (icon, tint) = when (ok) {
        true -> Icons.Outlined.CheckCircle to colors.success
        false -> Icons.Outlined.ErrorOutline to colors.danger
        null -> Icons.Outlined.WarningAmber to colors.warning
    }
    val state = stringResource(when (ok) { true -> R.string.check_pass; false -> R.string.check_fail; null -> R.string.check_unavailable })
    Surface(shape = RoundedCornerShape(8.dp), color = tint.copy(alpha = .09f)) {
        Row(Modifier.semantics(mergeDescendants = true) { stateDescription = state }
            .padding(horizontal = 8.dp, vertical = 5.dp), verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(5.dp)) {
            Icon(icon, null, tint = tint, modifier = Modifier.size(16.dp))
            Text(stringResource(label), style = MaterialTheme.typography.labelMedium)
        }
    }
}

/**
 * Independent saved-output library and clearable activity history. Only history is pruned on resume;
 * unavailable saved outputs remain visible and report the access error in their details sheet.
 */
