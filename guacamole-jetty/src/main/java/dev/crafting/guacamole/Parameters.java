package dev.crafting.guacamole;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.Map;

import org.apache.guacamole.protocol.GuacamoleConfiguration;

public class Parameters {

    // The protocol for guacd to connect.
    public String protocol;

    // The hostname of the remote server that guacd should connect.
    public String hostname;

    // The username for authentication.
    public String username;

    // The password for authentication.
    public String password;

    private static Parameters _shared = new Parameters();

    private Parameters() {
        protocol = "rdp";
        hostname = "localhost";
    }

    private Parameters(Parameters from) {
        protocol = from.protocol;
        hostname = from.hostname;
        username = from.username;
        password = from.password;
    }

    public static Parameters replica() {
        synchronized(Parameters.class) {
            return new Parameters(_shared);
        }
    }

    public static void update(Map<String, String> params) {
        synchronized(Parameters.class) {
            _shared.protocol = paramNotEmpty(params, "protocol", _shared.protocol);
            _shared.hostname = paramNotEmpty(params, "hostname", _shared.hostname);
            _shared.username = paramEmptyAsNull(params, "username", _shared.username);
            _shared.password = paramEmptyAsNull(params, "password", _shared.password);
        }
    }

    private static String paramNotEmpty(Map<String, String> params, String key, String defaultValue) {
        String value = params.getOrDefault(key, defaultValue);
        if (value != null && value.isEmpty()) {
            return defaultValue;
        }
        return value;
    }

    private static String paramEmptyAsNull(Map<String, String> params, String key, String defaultValue) {
        String value = params.getOrDefault(key, defaultValue);
        if (value != null && value.isEmpty()) {
            return null;
        }
        return value;
    }

    public void apply(GuacamoleConfiguration config) {
        config.setProtocol(protocol);
        config.setParameter("hostname", hostname);
        if (username != null) {
            config.setParameter("username", username);
        }
        if (password != null) {
            config.setParameter("password", password);
        }
    }

    public String formData() throws UnsupportedEncodingException {
        StringBuilder result = new StringBuilder();
        result.append("protocol=");
        result.append(URLEncoder.encode(protocol, "UTF-8"));
        result.append("&hostname=");
        result.append(URLEncoder.encode(hostname, "UTF-8"));
        if (username != null) {
            result.append("&username=");
            result.append(URLEncoder.encode(username, "UTF-8"));
        }
        if (password != null) {
            result.append("&password=");
            result.append(URLEncoder.encode("*", "UTF-8"));
        }
        return result.toString();
    }

}
