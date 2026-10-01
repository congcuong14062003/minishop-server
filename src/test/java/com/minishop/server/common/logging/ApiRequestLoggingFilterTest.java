package com.minishop.server.common.logging;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class ApiRequestLoggingFilterTest {
    @Test
    void logsStatusAndRequestIdWithoutQueryOrAuthorization() throws Exception {
        ApiRequestLoggingFilter filter = new ApiRequestLoggingFilter();
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/v1/auth/login");
        request.setServletPath("/api/v1/auth/login");
        request.setQueryString("password=secret-in-query");
        request.addHeader("Authorization", "Bearer secret-token");
        MockHttpServletResponse response = new MockHttpServletResponse();
        Logger logger = (Logger) LoggerFactory.getLogger(ApiRequestLoggingFilter.class);
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        logger.addAppender(appender);
        try {
            filter.doFilter(request, response, (req, res) -> {
                assertNotNull(MDC.get("requestId"));
                ((MockHttpServletResponse) res).setStatus(401);
            });
            String requestId = response.getHeader("X-Request-Id");
            UUID.fromString(requestId);
            assertNull(MDC.get("requestId"));
            assertEquals(1, appender.list.size());
            String message = appender.list.get(0).getFormattedMessage();
            assertTrue(message.contains("method=POST"));
            assertTrue(message.contains("path=/api/v1/auth/login"));
            assertTrue(message.contains("status=401"));
            assertFalse(message.contains("secret-in-query"));
            assertFalse(message.contains("secret-token"));
            assertEquals(requestId, appender.list.get(0).getMDCPropertyMap().get("requestId"));
        } finally {
            logger.detachAppender(appender);
            appender.stop();
        }
    }
}
