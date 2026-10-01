package com.minishop.server;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.server.servlet.context.ServletWebServerApplicationContext;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class MinishopServerApplication {
	private static final Logger log = LoggerFactory.getLogger(MinishopServerApplication.class);

	public static void main(String[] args) {
		var context = SpringApplication.run(MinishopServerApplication.class, args);
		int port = ((ServletWebServerApplicationContext) context).getWebServer().getPort();
		String contextPath = context.getEnvironment().getProperty("server.servlet.context-path", "");
		String baseUrl = "http://localhost:" + port + ("/".equals(contextPath) ? "" : contextPath);
		log.info("MiniShop API (local): {}", baseUrl);
		log.info("Health endpoint: {}/api/v1/health", baseUrl);
	}

}
