/*
* Copyright (c) 2019 Raí B. Toffoletto (https://toffoletto.me)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Raí B. Toffoletto <rai@toffoletto.me>
*/

public class Adstruo.Temps : Wingpanel.Indicator {
    private Gtk.Box display_widget;
    private Gtk.Box popover_widget;
    private Adstruo.Utilities adstruo;
    private GLib.Settings settings;
    private Gtk.Label temperature;
    private Wingpanel.Widgets.Switch fahrenheit_switch;

    public Temps () {
        Object (
            code_name : "adstruo-20-temps"
        );
    }

    construct {
        visible = false;
        adstruo = new Adstruo.Utilities ();
        settings = adstruo.temp_settings;

        var icon = new Gtk.Image.from_icon_name ("temperature", Gtk.IconSize.SMALL_TOOLBAR);
        temperature = new Gtk.Label ("N/A");

        display_widget = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        display_widget.valign = Gtk.Align.CENTER;
        display_widget.pack_start (icon, false, false);
        display_widget.pack_end (temperature, false, false);

        fahrenheit_switch = new Wingpanel.Widgets.Switch (_("Use Fahrenheit"));

        popover_widget = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        popover_widget.add (fahrenheit_switch);

        activate_indicator (settings.get_boolean ("status"));

        settings.change_event.connect (() => {
            activate_indicator (settings.get_boolean ("status"));
        });

        fahrenheit_switch.notify["active"].connect (() => {
            settings.set_boolean ("unit-fahrenheit", fahrenheit_switch.active ? true : false);
        });
    }

    public override Gtk.Widget get_display_widget () {
        return display_widget;
    }

    public override Gtk.Widget? get_widget () {
        return popover_widget;
    }

    public override void opened () {}

    public override void closed () {}

    public void activate_indicator (bool enable = false) {
        visible = enable;
        fahrenheit_switch.active = settings.get_boolean ("unit-fahrenheit");
        if (update_temp ()) {
            Timeout.add_full (Priority.DEFAULT, 2500, update_temp);
        }
    }

    private bool update_temp () {
    	try {
            var dir = GLib.Dir.open ("/sys/class/hwmon/", 0);
            string? dirname = null;
            string name, temp_raw;

            while ((dirname = dir.read_name ()) != null) {
                if (FileUtils.test ("/sys/class/hwmon/"+dirname+"/temp1_input", FileTest.EXISTS)) {
                    FileUtils.get_contents("/sys/class/hwmon/"+dirname+"/name", out name);
                    if (settings.get_string ("temperature-source") == name.strip ()) {
                        FileUtils.get_contents("/sys/class/hwmon/"+dirname+"/temp1_input", out temp_raw);
                        temperature.label = adstruo.convert_temp (temp_raw, settings.get_boolean ("unit-fahrenheit"));
                    }
                }
            }
        } catch (FileError e) {
    		stdout.printf ("Error: %s\n", e.message);
	        return false;
	    }

	    return settings.get_boolean ("status");
    }
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    debug (_("Activating Temperature Indicator"));
    if (server_type != Wingpanel.IndicatorManager.ServerType.SESSION) {
        return null;
    }

    return new Adstruo.Temps ();
}
