
import dbus
import dbus.service
import urllib.parse

from dbus.mainloop.glib import DBusGMainLoop
# from dbus.mainloop.glib import threads_init
from gi.repository import GLib


class evince:
    def __init__(self):
        self.viewer = 'evince'
        self.interface = 'org.gnome.evince.Window'

    def signal(self):
        return 'SyncSource'

    def callback(self, uri, point, timestamp):
        path = urllib.parse.unquote(uri.replace('file://', ''))
        line = str(point[0])
        col = str(point[1])
        self.Out(path, line, col)

    def Out(self, path, line, col):
        print(path + '|' + line + '|' + col + '|' + self.viewer, flush=True)
        # print(path + '|' + line + '|' + col, flush=True)


class atril(evince):
    def __init__(self):
        self.viewer = 'atril'
        self.interface = 'org.mate.atril.Window'


class xreader(evince):
    def __init__(self):
        self.viewer = 'xreader'
        self.interface = 'org.x.reader.Window'


class zathura(evince):
    def __init__(self):
        self.viewer = 'zathura'
        self.interface = 'org.pwmt.zathura'

    def signal(self):
        return 'Edit'

    def callback(self, path, line_num, col_num):
        line = str(line_num)
        col = str(col_num)
        self.Out(path, line, col)


# threads_init()
dbus_loop1 = DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus(mainloop=dbus_loop1)

sender = [evince(), atril(), xreader(), zathura()]
for s in sender:
    bus.add_signal_receiver(
            s.callback,
            signal_name=s.signal(),
            dbus_interface=s.interface)

GLib.MainLoop().run()
