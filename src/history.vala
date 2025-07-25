// SPDX-FileCopyrightText: 2010-2025 Mahjongg Contributors
// SPDX-FileCopyrightText: 2010-2013 Robert Ancell
// SPDX-License-Identifier: GPL-2.0-or-later

public class History {
    public string filename;
    private HistoryEntry[] entries;

    public int length {
        get { return entries.length; }
    }

    public History (string filename) {
        this.filename = filename;
    }

    public void load () {
        var contents = "";
        try {
            FileUtils.get_contents (filename, out contents);
        }
        catch (FileError e) {
            if (!(e is FileError.NOENT))
                warning ("Failed to load history: %s", e.message);
            return;
        }

        foreach (unowned var line in contents.split ("\n")) {
            var tokens = line.split (" ", 4);
            if (tokens.length < 3)
                continue;

            var date = new DateTime.from_iso8601 (tokens[0], null);
            if (date == null)
                continue;
            var name = tokens[1];
            var duration = int.parse (tokens[2]);
            string player;
            if (tokens.length >= 4)
                player = tokens[3];
            else
                player = Environment.get_real_name ();

            entries += new HistoryEntry (date, name, duration, player);
        }
    }

    public void save () {
        var builder = new StringBuilder ();
        foreach (unowned var entry in entries) {
            var line = "%s %s %u %s\n".printf (entry.date.to_string (), entry.name, entry.duration, entry.player);
            builder.append (line);
        }

        try {
            DirUtils.create_with_parents (Path.get_dirname (filename), 0775);
            FileUtils.set_contents (filename, builder.str);
        }
        catch (FileError e) {
            warning ("Failed to save history: %s", e.message);
        }
    }

    public HistoryEntry add (DateTime date, string name, uint duration, string player) {
        var entry = new HistoryEntry (date, name, duration, player);
        entries += entry;
        save ();
        return entry;
    }

    public void clear () {
        entries = null;
        save ();
    }

    public Iterator iterator () {
        return new Iterator (this);
    }

    public class Iterator {
        private int index;
        private History history;

        public Iterator (History history) {
            this.history = history;
        }

        public bool next () {
            return index < history.length;
        }

        public unowned HistoryEntry get () {
            return history.entries[index++];
        }
    }
}

public class HistoryEntry : Object {
    public DateTime date;
    public string name;
    public uint duration;
    public string player;
    public uint rank;

    public HistoryEntry (DateTime date, string name, uint duration, string player) {
        this.date = date;
        this.name = name;
        this.duration = duration;
        this.player = player;
    }
}
