/*
 * mirai-chan - e-Sim IRC bot
 * Copyright (C) 2013 Arnel A. Borja <kyoushuu@yahoo.com>
 *
 * This is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


int main (string[] args)
{
    var main_loop = new MainLoop (null, false);

    try {
        var key_file = new KeyFile ();
        var key_path = Path.build_filename (Environment.get_user_config_dir (), "mirai-chan", "settings.conf");
        key_file.load_from_file (key_path, KeyFileFlags.NONE);

        var irc_host = key_file.get_string ("IRC", "host");
        var irc_port = (uint16) key_file.get_integer ("IRC", "port");
        var irc_pass = key_file.get_string ("IRC", "pass");
        var irc_nickname = key_file.get_string ("IRC", "nickname");
        var irc_realname = key_file.get_string ("IRC", "realname");
        var irc_nspass = key_file.get_string ("IRC", "nspass");
        var irc_channels = key_file.get_string_list ("IRC", "channels");

        var bot = new IRCBot (irc_host, irc_port, irc_pass);
        if (irc_nspass != null && irc_nspass != "") {
            bot.notice_received.connect ((sender, receiver, message) => {
                if (sender.has_prefix ("NickServ!") &&
                    message == "Password accepted - you are now recognized.") {
                    foreach (var channel in irc_channels) {
                        bot.join_channel (channel);
                    }
                }
            });
        }
        bot.closed.connect (() => {
            main_loop.quit ();
        });

        bot.connect.begin (irc_nickname, irc_realname, (obj, res) => {
            if (!bot.connect.end (res)) {
                return;
            }

            if (irc_nspass != null && irc_nspass != "") {
                bot.send_msg ("NickServ", "IDENTIFY %s".printf (irc_nspass));
            } else {
                foreach (var channel in irc_channels) {
                    bot.join_channel (channel);
                }
            }
        });
    } catch (Error e) {
        stderr.printf ("Error: %s\n", e.message);
    }

    main_loop.run ();

    return 0;
}
