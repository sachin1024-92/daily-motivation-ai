package io.github.sachin102492.floatnote.ui

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.View
import android.widget.TextView
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.ItemTouchHelper
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.floatingactionbutton.ExtendedFloatingActionButton
import com.google.android.material.materialswitch.MaterialSwitch
import com.google.android.material.snackbar.Snackbar
import io.github.sachin102492.floatnote.R
import io.github.sachin102492.floatnote.data.NoteRepository
import io.github.sachin102492.floatnote.notes
import io.github.sachin102492.floatnote.overlay.FloatingService
import io.github.sachin102492.floatnote.util.padForSystemBars

class MainActivity : AppCompatActivity(), NoteRepository.Listener {

    private lateinit var root: View
    private lateinit var bubbleSwitch: MaterialSwitch
    private lateinit var bubbleStatus: TextView
    private lateinit var emptyView: View
    private lateinit var fab: ExtendedFloatingActionButton
    private val adapter = NotesAdapter { openEditor(it.id) }

    private var awaitingOverlayPermission = false
    private var askedForNotifications = false
    private var syncingSwitch = false

    private val notificationPermission =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { startBubble() }

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        root = findViewById(R.id.root)
        root.padForSystemBars()

        bubbleSwitch = findViewById(R.id.bubble_switch)
        bubbleStatus = findViewById(R.id.bubble_status)
        emptyView = findViewById(R.id.empty_view)
        fab = findViewById(R.id.fab_new)

        val list = findViewById<RecyclerView>(R.id.notes_list)
        list.layoutManager = LinearLayoutManager(this)
        list.adapter = adapter
        list.addOnScrollListener(object : RecyclerView.OnScrollListener() {
            override fun onScrolled(recyclerView: RecyclerView, dx: Int, dy: Int) {
                if (dy > 0) fab.shrink() else if (dy < 0) fab.extend()
            }
        })
        ItemTouchHelper(SwipeToDelete()).attachToRecyclerView(list)

        fab.setOnClickListener { openEditor(NoteRepository.NO_ID) }
        findViewById<View>(R.id.bubble_card).setOnClickListener { bubbleSwitch.toggle() }
        bubbleSwitch.setOnCheckedChangeListener { _, checked ->
            if (syncingSwitch) return@setOnCheckedChangeListener
            if (checked) {
                requestBubble()
            } else {
                FloatingService.stop(this)
                showBubbleState(false)
            }
        }

        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        notes.addListener(this)
        refreshNotes()
        if (awaitingOverlayPermission && Settings.canDrawOverlays(this)) {
            awaitingOverlayPermission = false
            requestBubble()
        } else {
            showBubbleState(FloatingService.running)
        }
    }

    override fun onPause() {
        notes.removeListener(this)
        super.onPause()
    }

    override fun onNotesChanged() = refreshNotes()

    private fun handleIntent(intent: Intent) {
        if (intent.getBooleanExtra(EXTRA_START_BUBBLE, false)) {
            intent.removeExtra(EXTRA_START_BUBBLE)
            requestBubble()
        }
    }

    private fun refreshNotes() {
        val visible = notes.all.filterNot { it.isBlank }
        adapter.submitList(visible)
        emptyView.visibility = if (visible.isEmpty()) View.VISIBLE else View.GONE
    }

    private fun requestBubble() {
        if (!Settings.canDrawOverlays(this)) {
            showBubbleState(false)
            // Prominent disclosure before sending the user to the system permission screen.
            MaterialAlertDialogBuilder(this)
                .setIcon(R.drawable.ic_bubble)
                .setTitle(R.string.overlay_permission_title)
                .setMessage(R.string.overlay_permission_message)
                .setPositiveButton(R.string.overlay_permission_grant) { _, _ ->
                    awaitingOverlayPermission = true
                    startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName"),
                        ),
                    )
                }
                .setNegativeButton(R.string.not_now, null)
                .show()
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !askedForNotifications &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            askedForNotifications = true
            notificationPermission.launch(Manifest.permission.POST_NOTIFICATIONS)
            return
        }
        startBubble()
    }

    private fun startBubble() {
        FloatingService.start(this)
        showBubbleState(true)
    }

    private fun showBubbleState(on: Boolean) {
        syncingSwitch = true
        bubbleSwitch.isChecked = on
        syncingSwitch = false
        bubbleStatus.setText(if (on) R.string.bubble_on else R.string.bubble_off)
    }

    private fun openEditor(id: Long) {
        startActivity(EditorActivity.intent(this, id))
    }

    private inner class SwipeToDelete :
        ItemTouchHelper.SimpleCallback(0, ItemTouchHelper.LEFT or ItemTouchHelper.RIGHT) {

        override fun onMove(
            recyclerView: RecyclerView,
            viewHolder: RecyclerView.ViewHolder,
            target: RecyclerView.ViewHolder,
        ) = false

        override fun onSwiped(viewHolder: RecyclerView.ViewHolder, direction: Int) {
            val note = adapter.currentList.getOrNull(viewHolder.bindingAdapterPosition) ?: return
            val removed = notes.delete(note.id) ?: return
            Snackbar.make(root, R.string.note_deleted, Snackbar.LENGTH_LONG)
                .setAnchorView(fab)
                .setAction(R.string.undo) { notes.restore(removed) }
                .show()
        }
    }

    companion object {
        const val EXTRA_START_BUBBLE = "start_bubble"
    }
}
