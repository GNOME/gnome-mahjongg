/*
 * Copyright (C) 2010-2013 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 2 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

namespace Gtk
{
    /* See https://bugzilla.gnome.org/show_bug.cgi?id=669386 */
    void color_button_get_rgba (Gtk.ColorButton button, out Gdk.RGBA rgba);
}
