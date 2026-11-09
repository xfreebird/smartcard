package md.moldsign.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import md.moldsign.app.AppShortcuts
import md.moldsign.app.MainActivity
import md.moldsign.app.MoldSignApp
import md.moldsign.app.R
import md.moldsign.core.ActivityEntry

/** Explicit activity intents carry library IDs only. No documents or credentials leave the app. */
class DocumentsWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) = refresh(context)
    companion object {
        const val SHOW_RECENTS = "widget_show_recent_documents"
        const val DOCUMENT_ID = "widget_document_id"
        fun showsRecents(context: Context) = context.getSharedPreferences("settings", Context.MODE_PRIVATE)
            .getBoolean(SHOW_RECENTS, false)

        fun refresh(context: Context, documents: List<ActivityEntry>? = null) {
            val app = context.applicationContext as? MoldSignApp ?: return
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, DocumentsWidget::class.java))
            if (ids.isEmpty()) return
            val enabled = showsRecents(context) && !app.demoModeEnabled
            val recent = if (enabled) (documents ?: app.container.activity.signedDocuments.value)
                .filter { it.signedOutput && it.ok && it.documentUri != null }
                .sortedByDescending { it.timeMillis }.take(2) else emptyList()
            val language = context.getSharedPreferences("settings", Context.MODE_PRIVATE).getString("widget_language", "system")
            val configuration = android.content.res.Configuration(context.resources.configuration)
            if (language in setOf("en", "ro", "ru")) configuration.setLocales(android.os.LocaleList.forLanguageTags(language))
            val localized = context.createConfigurationContext(configuration)
            val views = RemoteViews(context.packageName, R.layout.documents_widget)
            views.setTextViewText(R.id.widget_verify, localized.getString(R.string.shortcut_verify_pdf))
            views.setTextViewText(R.id.widget_documents, localized.getString(R.string.shortcut_documents))
            views.setOnClickPendingIntent(R.id.widget_verify, action(context, "verify", AppShortcuts.Destination.Verify))
            views.setOnClickPendingIntent(R.id.widget_documents, action(context, "documents", AppShortcuts.Destination.Documents))
            views.setViewVisibility(R.id.widget_empty, if (recent.isEmpty()) View.VISIBLE else View.GONE)
            views.setTextViewText(R.id.widget_empty, localized.getString(if (enabled) R.string.widget_no_documents else R.string.widget_private))
            listOf(R.id.widget_recent_one, R.id.widget_recent_two).forEachIndexed { index, view ->
                val doc = recent.getOrNull(index)
                views.setViewVisibility(view, if (doc == null) View.GONE else View.VISIBLE)
                views.setTextViewText(view, doc?.title?.take(200).orEmpty())
                if (doc != null) views.setOnClickPendingIntent(view, action(context, doc.id, AppShortcuts.Destination.Documents, doc.id))
            }
            ids.forEach { manager.updateAppWidget(it, views) }
        }

        private fun action(context: Context, key: String, destination: AppShortcuts.Destination, documentID: String? = null): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).setAction(AppShortcuts.ACTION)
                .setData(android.net.Uri.Builder().scheme("esemnbun").authority("widget").appendPath(key).build())
                .putExtra(AppShortcuts.FEATURE, destination.id)
                .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            if (documentID != null) intent.putExtra(DOCUMENT_ID, documentID)
            return PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }
    }
}
