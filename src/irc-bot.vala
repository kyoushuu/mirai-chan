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
    public string name { public get; private set; }

    private DataInputStream input;
    private DataOutputStream output;
    private SocketConnection conn;

    public IRCBot () {
    }

    public async new bool connect (string host, uint16 port, string nick, string name) {
        this.host = host;
        this.port = port;
        this.nick = nick;
        this.name = name;

        try {
            // Resolve hostname to IP address
            var resolver = Resolver.get_default ();
            var addresses = resolver.lookup_by_name (host, null);
            var address = addresses.nth_data (0);

            // Connect
            var client = new SocketClient ();
            conn = client.connect (new InetSocketAddress (address, port));

            input = new DataInputStream (conn.input_stream);
            output = new DataOutputStream (conn.output_stream);

            // Set nickname
            send_data ("NICK %s".printf (nick));

            // Set full name
            send_data ("USER %s 0 * :%s".printf (nick, name));

            new Thread<void*> ("read", run);
        } catch (Error e) {
            return false;
        }

        return true;
    }

    public void send_data (string data) throws IOError {
        output.put_string ("%s\r\n".printf (data));
    }

    public void join_channel (string channel) {
        try {
            send_data ("JOIN #%s".printf (channel));
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
                }

                var msg = line.strip ().split (" ", 3);

                if (line[0] != ':') {
                    command = msg[0];

                    if (command == "PING") {
                        var sender = msg[1] != null? msg[1][1:msg[1].length] : null;
                        send_data ("PONG %s".printf (sender));
                    }
                } else {
                    command = msg[1];
                }
            } catch (IOError e) {
                stderr.printf ("Error: %s\n", e.message);
            }
        }

        return null;
    }

}
