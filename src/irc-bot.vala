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


public class IRCBot : Object {

    public string host { public get; private set; }
    public uint16 port { public get; private set; }

    public string nick { public get; private set; }
    public string pass { public get; private set; }
    public string name { public get; private set; }

    private DataInputStream input;
    private DataOutputStream output;
    private SocketConnection conn;

    private Cond who_cond = Cond ();
    private Mutex who_mutex = Mutex ();
    private string who_nick;
    private string who_flags;

    public virtual signal void privmsg_received (string sender, string receiver, string message) {
        var sender_nick = get_nick_from_address (sender);
        string[] args;
        string msg, send_to;

        if (message.has_prefix ("%s:".printf (nick)) && receiver[0] == '#') {
            msg = message["%s:".printf (nick).length:message.length];
            send_to = receiver;
        } else if (receiver == nick) {
            msg = message;
            send_to = sender_nick;
        } else {
            return;
        }

        try {
            Shell.parse_argv (msg, out args);
        } catch (Error e) {
            return;
        }

        if (args[0] == "quit") {
            quit (args.length > 1? args[1] : "Signing off!");

            return;
        } else if (args[0] == "join") {
            for (var i = 1; i < args.length; i++) {
                join_channel (args[i]);
            }

            return;
        } else if (args[0] == "leave") {
            for (var i = 1; i < args.length; i++) {
                leave_channel (args[i]);
            }

            return;
        } else if (args[0] == "do") {
            try {
                send_data (args[1]);
            } catch (IOError e) {
                stderr.printf ("Error: %s\n", e.message);
            }

            return;
        } else if (args[0] == "say") {
            var recipient = args[1];
            var say_msg = args[2];

            send_msg (recipient, say_msg);

            return;
        } else if (args[0] == "act") {
            var recipient = args[1];
            var action = args[2];

            send_msg (recipient, "\x01" + "ACTION " + action + "\x01");

            return;
        } else if (args[0] == "announce") {
            var recipients = new string[0];
            var announce_msgs = new string[0];
            var notify = true;

            for (var i = 1; i < args.length; i++) {
                if (args[i] == "-m") {
                    if (i + 1 >= args.length) {
                        send_msg (send_to, "Argument for -m is missing");

                        return;
                    }

                    announce_msgs += args[++i];
                } else if (args[i] == "-N") {
                    notify = true;
                } else if (args[i] == "-n") {
                    notify = false;
                } else {
                    recipients += args[i];
                }
            }

            if (announce_msgs.length == 0) {
                send_msg (send_to, "Message missing. Specify a message to announce using -m option.");

                return;
            }

            foreach (var recipient in recipients) {
                if (notify) {
                    send_msg (recipient, "Message from %s:".printf (send_to));
                }

                foreach (var announce_msg in announce_msgs) {
                    send_msg (recipient, announce_msg);
                }
            }

            return;
        }
    }

    public virtual signal void nick_joined (string channel, string nick) {
    }

    public virtual signal void closed () {
    }

    public IRCBot () {
    }

    public async new bool connect (string host, uint16 port, string nick, string pass, string name) {
        this.host = host;
        this.port = port;
        this.nick = nick;
        this.pass = pass;
        this.name = name;

        List<InetAddress> addresses;

        try {
            // Resolve hostname to IP address
            var resolver = Resolver.get_default ();
            addresses = resolver.lookup_by_name (host, null);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            return false;
        }

        foreach (var address in addresses) {
            try {
                // Connect
                var client = new SocketClient ();
                conn = client.connect (new InetSocketAddress (address, port));

                if (conn != null) {
                    break;
                }
            } catch (Error e) {
                stderr.printf ("Error: %s\n", e.message);
            }
        }

        input = new DataInputStream (conn.input_stream);
        output = new DataOutputStream (conn.output_stream);

        try {
            // Set nickname
            send_data ("NICK %s".printf (nick));

            // Set full name
            send_data ("USER %s 0 * :%s".printf (nick, name));

            if (pass != null && pass != "") {
                // Identify with NickServ
                send_msg ("NickServ", "IDENTIFY %s".printf (pass));
            }
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            return false;
        }

        new Thread<void*> ("read", run);

        return true;
    }

    public void send_data (string data) throws IOError {
        output.put_string ("%s\r\n".printf (data));
        stdout.printf ("< %s\n", data);
    }

    public void send_msg (string recipient, string message) {
        try {
            send_data ("PRIVMSG %s :%s".printf(recipient, message));
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
    }

    public void send_notice (string recipient, string message) {
        try {
            send_data ("NOTICE %s :%s".printf(recipient, message));
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
    }

    public void join_channel (string channel) {
        try {
            send_data ("JOIN #%s".printf (channel));
        } catch (IOError e) {
            stderr.printf ("Error: %s\n", e.message);
        }
    }

    public void leave_channel (string channel) {
        try {
            send_data ("PART #%s".printf (channel));
        } catch (IOError e) {
            stderr.printf ("Error: %s\n", e.message);
        }
    }

    public void kick_from_channel (string channel, string recipient, string? reason = null) {
        try {
            send_data ("KICK #%s %s :%s".printf (channel, recipient, reason));
        } catch (IOError e) {
            stderr.printf ("Error: %s\n", e.message);
        }
    }

    public void quit (string reason) {
        try {
            send_data ("QUIT :%s".printf (reason));
        } catch (IOError e) {
            stderr.printf ("Error: %s\n", e.message);
        }
    }

    private void* run () {
        string? line, command;

        line = null;

        while (true) {
            try {
                lock (input) {
                    if (input.is_closed ()) {
                        break;
                    }

                    line = input.read_line (null);

                    if (line == null) {
                        Idle.add (() => {
                            closed ();

                            return false;
                        });

                        return null;
                    }
                }
                stdout.printf ("> %s\n", line);

                var msg = line.strip ().split (" ", 3);

                if (line[0] != ':') {
                    command = msg[0];

                    if (command == "PING") {
                        var sender = msg[1] != null? msg[1][1:msg[1].length] : null;
                        send_data ("PONG %s".printf (sender));
                    }
                } else {
                    command = msg[1];

                    if (command == "PRIVMSG") {
                        msg = line.strip ().split (" ", 4);

                        var sender = msg[0] != null? msg[0][1:msg[0].length] : null;
                        var receiver = msg[2];
                        var content = msg[3] != null? msg[3][1:msg[3].length] : null;

                        Idle.add (() => {
                            privmsg_received (sender, receiver, content);

                            return false;
                        });
                    } else if (command == "JOIN") {
                        msg = line.strip ().split (" ", 4);

                        var sender = msg[0];
                        var channel = msg[2] != null? msg[2][1:msg[2].length] : null;

                        Idle.add (() => {
                            nick_joined (channel, sender);

                            return false;
                        });
                    } else if (command == "352") {
                        who_mutex.lock ();

                        msg = line.strip ().split (" ", 10);

                        who_nick = msg[7];
                        who_flags = msg[8];

                        who_cond.broadcast ();
                        who_mutex.unlock ();
                    }
                }
            } catch (IOError e) {
                stderr.printf ("Error: %s\n", e.message);
            }
        }

        return null;
    }

    public static string get_nick_from_address (string address) {
        return address.split("!")[0];
    }

    public async bool has_identified (string nickname) {
        SourceFunc callback = has_identified.callback;
        var flags = "";

        ThreadFunc<Error?> run = () => {
            who_mutex.lock ();
            while (who_nick != nickname) {
                who_cond.wait (who_mutex);
            }
            flags = who_flags;
            who_mutex.unlock ();

            Idle.add((owned) callback);
            return null;
        };
        var thread = new Thread<Error?> ("has_identified", run);

        try {
            send_data ("WHO %s".printf (nickname));
        } catch (IOError e) {
            stderr.printf ("Error: %s\n", e.message);
        }

        yield;
        thread.join ();

        return flags.contains ("r");
    }

}
