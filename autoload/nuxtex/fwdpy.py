import dbus
import urllib.parse
import sys


class ForwardEvince:
    def __init__(self):
        self.daemon_obj = "org.gnome.evince.Daemon"
        self.daemon_obj_path = "/org/gnome/evince/Daemon"
        self.daemon_obj_interface = "org.gnome.evince.Daemon"

        self.app_obj_path = '/org/gnome/evince/Evince'
        self.app_obj_interface = 'org.gnome.evince.Application'

        self.win_obj_interface = 'org.gnome.evince.Window'

    def get_interface(self, obj, path, interface):
        # Setting up object
        bus = dbus.SessionBus()
        the_object = bus.get_object(obj, path)
        the_interface = dbus.Interface(the_object, interface)

        return the_interface

    def sync_view(self, pdf_path, source_path, line, col):
        # Setting up Daemon object
        the_interface = self.get_interface(self.daemon_obj,
                                           self.daemon_obj_path,
                                           self.daemon_obj_interface)

        pdf_uri = 'file://' + urllib.parse.quote(pdf_path)
        # ,safe="/\!#$&'()-=^[]{}@`+_")

        # Getting object path of openning target document
        reply = the_interface.FindDocument(pdf_uri, True)

        # Setting up window object.
        the_app_interface = self.get_interface(reply,
                                               self.app_obj_path,
                                               self.app_obj_interface)

        # Getting object path of window list
        window_list = the_app_interface.GetWindowList()
        target_window = window_list[0]

        # Setting up Syncview object
        the_window_interface = self.get_interface(reply,
                                                  target_window,
                                                  self.win_obj_interface)

        # Call Evince window via SyncView
        the_window_interface.SyncView(source_path, (line, col), 0)


class ForwardAtril(ForwardEvince):
    def __init__(self):
        self.daemon_obj = "org.mate.atril.Daemon"
        self.daemon_obj_path = "/org/mate/atril/Daemon"
        self.daemon_obj_interface = "org.mate.atril.Daemon"

        self.app_obj_path = '/org/mate/atril/Atril'
        self.app_obj_interface = 'org.mate.atril.Application'

        self.win_obj_interface = 'org.mate.atril.Window'


class ForwardXreader(ForwardEvince):
    def __init__(self):
        self.daemon_obj = "org.x.reader.Daemon"
        self.daemon_obj_path = "/org/x/reader/Daemon"
        self.daemon_obj_interface = "org.x.reader.Daemon"

        self.app_obj_path = '/org/x/reader/Xreader'
        self.app_obj_interface = 'org.x.reader.Application'

        self.win_obj_interface = 'org.x.reader.Window'


viewer = sys.argv[1]
src = sys.argv[2].split(':', 2)
pdf_path = sys.argv[3]
# @line:@col:@tex
line = int(src[0])
col = int(src[1])
source_path = src[2]
if viewer == 'evince':
    DbusForward = ForwardEvince()
elif viewer == 'atril':
    DbusForward = ForwardAtril()
elif viewer == 'xreader':
    DbusForward = ForwardXreader()

DbusForward.sync_view(pdf_path, source_path, line, col)
