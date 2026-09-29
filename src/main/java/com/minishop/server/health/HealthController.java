package com.minishop.server.health;

import com.minishop.server.common.api.ApiResponse;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/health")
public class HealthController {
    private final HealthService healthService;

    public HealthController(HealthService healthService) {
        this.healthService = healthService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, String>>> health() {
        if (!healthService.databaseIsUp()) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(ApiResponse.of(503, 503, "Không kết nối được cơ sở dữ liệu.",
                            Map.of("service", "UP", "database", "DOWN")));
        }
        return ResponseEntity.ok(ApiResponse.success(Map.of("service", "UP", "database", "UP")));
    }
}
