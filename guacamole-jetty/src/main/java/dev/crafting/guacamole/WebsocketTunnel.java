package dev.crafting.guacamole;

import java.util.Arrays;

import javax.websocket.EndpointConfig;
import javax.websocket.Session;
import org.apache.guacamole.GuacamoleException;
import org.apache.guacamole.net.GuacamoleTunnel;
import org.apache.guacamole.net.GuacamoleSocket;
import org.apache.guacamole.net.InetGuacamoleSocket;
import org.apache.guacamole.net.SimpleGuacamoleTunnel;
import org.apache.guacamole.protocol.ConfiguredGuacamoleSocket;
import org.apache.guacamole.protocol.GuacamoleConfiguration;
import org.apache.guacamole.websocket.GuacamoleWebSocketTunnelEndpoint;

public class WebsocketTunnel extends GuacamoleWebSocketTunnelEndpoint {
    @Override
    protected GuacamoleTunnel createTunnel(Session session,
            EndpointConfig endpointConfig) throws GuacamoleException {

        GuacamoleConfiguration config = new GuacamoleConfiguration();
        config.setProtocol("rdp");
        config.setParameter("hostname", "localhost");
        config.setParameter("ignore-cert", "true");
        config.setParameter("resize-method", "display-update");
        config.setParameter("enable-font-smoothing", "true");
        config.setParameter("force-lossless", "true");
        // get other params from url querystring
        String[] allowedParams = new String[] { "username", "password", "width", "height" };
        String queryString = session.getRequestURI().getQuery();
        String[] params = queryString.split("&");
        for (String param : params) {
            String[] parts = param.split("=");
            if (parts.length == 2 && Arrays.asList(allowedParams).contains(parts[0])) {
                config.setParameter(parts[0], parts[1]);
            }
        }

        // Connect to guacd - everything is hard-coded here.
        GuacamoleSocket socket = new ConfiguredGuacamoleSocket(
                new InetGuacamoleSocket("localhost", 4822),
                config
        );

        return new SimpleGuacamoleTunnel(socket);
    }
}