package dev.crafting.guacamole;

import java.net.URI;
import java.util.Arrays;

import javax.websocket.server.ServerEndpointConfig;    
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.ServerConnector;
import org.eclipse.jetty.server.Handler;
import org.eclipse.jetty.server.handler.ResourceHandler;
import org.eclipse.jetty.server.handler.HandlerList;
import org.eclipse.jetty.servlet.ServletContextHandler;
import org.eclipse.jetty.websocket.javax.server.config.JavaxWebSocketServletContainerInitializer;

public class WebServer {
    public static void main(String[] args) throws Exception
    {
        WebServer server = new WebServer();
        server.setPort(8080);
        server.start();
        server.join();
    }
    
    private final Server server;
    private final ServerConnector connector;
    
    public WebServer()
    {
        server = new Server();
        connector = new ServerConnector(server);
        server.addConnector(connector);

        String indexFileInResource = getClass().getClassLoader().getResource("index.html").toString();

        ResourceHandler resourceHandler = new ResourceHandler();
        resourceHandler.setDirectoriesListed(false);
        resourceHandler.setResourceBase(indexFileInResource.substring(0, indexFileInResource.length()-10));


        // Setup the basic application "context" for this application at "/"
        // This is also known as the handler tree (in jetty speak)
        ServletContextHandler context = new ServletContextHandler(ServletContextHandler.SESSIONS);
        context.setContextPath("/");

        HandlerList handlers = new HandlerList();
        handlers.setHandlers(new Handler[] { resourceHandler, context});
        server.setHandler(handlers);

        // Initialize javax.websocket layer
        JavaxWebSocketServletContainerInitializer.configure(context, (servletContext, wsContainer) -> {
            // This lambda will be called at the appropriate place in the
            // ServletContext initialization phase where you can initialize
            // and configure  your websocket container.

            // Configure defaults for container
            wsContainer.setDefaultMaxTextMessageBufferSize(65535);

            ServerEndpointConfig config = ServerEndpointConfig.Builder.create(WebsocketTunnel.class, "/rdp")
                .subprotocols(Arrays.asList(new String[]{"guacamole"}))
                .build();
            wsContainer.addEndpoint(config);
        });
    }
    
    public void setPort(int port)
    {
        connector.setPort(port);
    }
    
    public void start() throws Exception
    {
        server.start();
    }
    
    public URI getURI()
    {
        return server.getURI();
    }
    
    public void stop() throws Exception
    {
        server.stop();
    }
    
    public void join() throws InterruptedException
    {
        System.out.println("Use Ctrl+C to stop server");
        server.join();
    }
}
