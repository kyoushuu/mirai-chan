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
        } catch (Error e) {
            return false;
        }

        return true;
    }

    public void send_data (string data) throws IOError {
        output.put_string ("%s\r\n".printf (data));
    }

}
