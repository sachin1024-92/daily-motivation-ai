package io.github.sachin102492.floatnote.ui

import android.text.format.DateUtils
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import io.github.sachin102492.floatnote.R
import io.github.sachin102492.floatnote.data.Note

class NotesAdapter(
    private val onClick: (Note) -> Unit,
) : ListAdapter<Note, NotesAdapter.Holder>(Diff) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): Holder =
        Holder(LayoutInflater.from(parent.context).inflate(R.layout.item_note, parent, false))

    override fun onBindViewHolder(holder: Holder, position: Int) = holder.bind(getItem(position))

    inner class Holder(view: View) : RecyclerView.ViewHolder(view) {
        private val title: TextView = view.findViewById(R.id.note_title)
        private val preview: TextView = view.findViewById(R.id.note_preview)
        private val time: TextView = view.findViewById(R.id.note_time)
        private var note: Note? = null

        init {
            view.setOnClickListener { note?.let(onClick) }
        }

        fun bind(note: Note) {
            this.note = note
            title.text = note.displayTitle.ifEmpty { itemView.context.getString(R.string.untitled) }
            preview.text = note.preview
            preview.visibility = if (note.preview.isEmpty()) View.GONE else View.VISIBLE
            time.text = DateUtils.getRelativeTimeSpanString(
                note.updatedAt,
                System.currentTimeMillis(),
                DateUtils.MINUTE_IN_MILLIS,
            )
        }
    }

    private object Diff : DiffUtil.ItemCallback<Note>() {
        override fun areItemsTheSame(oldItem: Note, newItem: Note) = oldItem.id == newItem.id
        override fun areContentsTheSame(oldItem: Note, newItem: Note) = oldItem == newItem
    }
}
