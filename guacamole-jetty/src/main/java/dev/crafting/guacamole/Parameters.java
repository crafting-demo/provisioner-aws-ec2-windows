package dev.crafting.guacamole;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.Map;
import java.util.Properties;

import org.apache.guacamole.protocol.GuacamoleConfiguration;

public class Parameters {
    private static final String CONFIG = "/guacamole/config.properties";

    private static final String PROTOCOL = "rdp";

    // The hostname of the remote server that guacd should connect.
    public String hostname;

    // The username for authentication.
    public String username;

    // The password for authentication.
    public String password;

    private static Parameters _shared = new Parameters();

    private Parameters() {
        Properties properties = new Properties();
        try {            
            // Load properties from file
            FileInputStream fis = new FileInputStream(CONFIG);
            properties.load(fis);
            fis.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
        hostname = properties.getProperty("hostname", "localhost");
        username = properties.getProperty("username", "Administrator");
        password = properties.getProperty("password");
    }

    private Parameters(Parameters from) {
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
            _shared.hostname = paramNotEmpty(params, "hostname", _shared.hostname);
            _shared.username = paramEmptyAsNull(params, "username", _shared.username);
            _shared.password = paramEmptyAsNull(params, "password", _shared.password);

            try {
                Properties properties = new Properties();
                properties.setProperty("hostname", _shared.hostname);
                properties.setProperty("username", _shared.username);
                properties.setProperty("password", _shared.password);
    
                FileOutputStream fos = new FileOutputStream(CONFIG);
                properties.store(fos, "parameters");
                fos.close();
            } catch (IOException e) {
                e.printStackTrace();
            }            
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
        config.setProtocol(PROTOCOL);
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
        result.append(URLEncoder.encode(PROTOCOL, "UTF-8"));
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
