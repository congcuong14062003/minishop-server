package com.minishop.server.common.logging;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.servlet.HandlerMapping;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class ApiRequestLoggingFilter extends OncePerRequestFilter {
    private static final Logger log = LoggerFactory.getLogger(ApiRequestLoggingFilter.class);
    private static final String REQUEST_ID = "requestId";

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getServletPath().startsWith("/api/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String requestId = UUID.randomUUID().toString();
        long started = System.nanoTime();
        boolean failed = false;
        response.setHeader("X-Request-Id", requestId);
        MDC.put(REQUEST_ID, requestId);
        try {
            chain.doFilter(request, response);
        } catch (ServletException | IOException | RuntimeException | Error error) {
            failed = true;
            throw error;
        } finally {
            try {
                int status = failed && response.getStatus() < 500 ? 500 : response.getStatus();
                long durationMs = (System.nanoTime() - started) / 1_000_000;
                Object pattern = request.getAttribute(HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE);
                String path = pattern instanceof String ? (String) pattern : safePath(request.getServletPath());
                if (status >= 500) {
                    log.warn("API request method={} path={} status={} durationMs={}",
                            request.getMethod(), path, status, durationMs);
                } else {
                    log.info("API request method={} path={} status={} durationMs={}",
                            request.getMethod(), path, status, durationMs);
                }
            } finally {
                MDC.remove(REQUEST_ID);
            }
        }
    }

    private static String safePath(String path) {
        if (path.length() > 200) return "<long-path>";
        return path.replace('\r', '_').replace('\n', '_');
    }
}
