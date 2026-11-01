package com.onething

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * AppWidget for the Today screen: 3 tasks with checkboxes + counter.
 * Data is read from the shared preferences written by the Flutter side
 * via the home_widget package.
 */
class OneThingWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        val views = RemoteViews(context.packageName, R.layout.one_thing_widget)

        val dateLabel = prefs.getString("widget.date", "") ?: ""
        views.setTextViewText(R.id.widget_date, dateLabel)

        val rawTasks = prefs.getString("widget.tasks", "") ?: ""
        val tasks = if (rawTasks.isEmpty()) emptyList() else rawTasks.split(";;")

        val rowIds = arrayOf(
            R.id.widget_task_0,
            R.id.widget_task_1,
            R.id.widget_task_2
        )
        val checkIds = arrayOf(
            R.id.widget_check_0,
            R.id.widget_check_1,
            R.id.widget_check_2
        )
        val titleIds = arrayOf(
            R.id.widget_title_0,
            R.id.widget_title_1,
            R.id.widget_title_2
        )

        for (slot in 0..2) {
            if (slot < tasks.size) {
                val parts = tasks[slot].split("|", limit = 3)
                val taskId = parts.getOrNull(0) ?: ""
                val isDone = parts.getOrNull(1) == "1"
                val title = parts.getOrNull(2) ?: ""

                views.setTextViewText(titleIds[slot], title)
                views.setInt(
                    titleIds[slot],
                    "setTextColor",
                    if (isDone) 0xFF6E6E73.toInt() else 0xFF1C1C1E.toInt()
                )
                views.setImageViewResource(
                    checkIds[slot],
                    if (isDone) R.drawable.ic_check_on else R.drawable.ic_check_off
                )

                val toggleIntent = Intent(context, OneThingWidgetProvider::class.java).apply {
                    action = "com.onething.action.TOGGLE_TASK"
                    putExtra("taskId", taskId)
                    putExtra("appWidgetId", appWidgetId)
                }
                val pendingToggle = PendingIntent.getBroadcast(
                    context,
                    appWidgetId * 10 + slot,
                    toggleIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(rowIds[slot], pendingToggle)
            } else {
                views.setTextViewText(titleIds[slot], "—")
                views.setImageViewResource(checkIds[slot], R.drawable.ic_check_off)
                views.setOnClickPendingIntent(rowIds[slot], null)
            }
        }

        val counter = prefs.getString("widget.counter", "") ?: ""
        views.setTextViewText(R.id.widget_counter, counter)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action == "com.onething.action.TOGGLE_TASK") {
            val taskId = intent.getStringExtra("taskId") ?: return
            val appWidgetId = intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )

            val prefs = context.getSharedPreferences(
                "one_thing_widget_actions", Context.MODE_PRIVATE
            )
            prefs.edit().putString("pending_toggle", taskId).apply()

            val widgetPrefs = HomeWidgetPlugin.getData(context)
            val raw = widgetPrefs.getString("widget.tasks", "") ?: ""
            if (raw.isNotEmpty()) {
                val updated = raw.split(";;").map { entry ->
                    val parts = entry.split("|", limit = 3)
                    if (parts.getOrNull(0) == taskId) {
                        val isDone = parts.getOrNull(1) == "1"
                        listOf(parts[0], if (isDone) "0" else "1", parts.getOrNull(2) ?: "")
                            .joinToString("|")
                    } else {
                        entry
                    }
                }.joinToString(";;")
                widgetPrefs.edit().putString("widget.tasks", updated).apply()
            }

            if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                updateAppWidget(
                    context,
                    AppWidgetManager.getInstance(context),
                    appWidgetId
                )
            }
        }
    }
}
