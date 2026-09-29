package com.minishop.server.common.exception;

import com.minishop.server.common.api.ApiResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.HttpRequestMethodNotSupportedException;

@RestControllerAdvice
public class GlobalExceptionHandler {
    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ApiResponse<Void>> handleApiException(ApiException error) {
        return error(error.status(), error.code(), error.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidation(MethodArgumentNotValidException error) {
        String message = error.getBindingResult().getFieldErrors().stream()
                .findFirst()
                .map(field -> field.getField() + ": " + field.getDefaultMessage())
                .orElse("Dữ liệu không hợp lệ.");
        return error(HttpStatus.BAD_REQUEST, 400, message);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResponse<Void>> handleInvalidJson(HttpMessageNotReadableException error) {
        return error(HttpStatus.BAD_REQUEST, 400, "Nội dung yêu cầu không hợp lệ.");
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiResponse<Void>> handleMethodNotAllowed(HttpRequestMethodNotSupportedException error) {
        return error(HttpStatus.METHOD_NOT_ALLOWED, 405, "Phương thức không được hỗ trợ.");
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleUnexpected(Exception error) {
        log.error("Unhandled API error", error);
        return error(HttpStatus.INTERNAL_SERVER_ERROR, 500, "Lỗi hệ thống.");
    }

    private ResponseEntity<ApiResponse<Void>> error(HttpStatus status, int code, String message) {
        return ResponseEntity.status(status).body(ApiResponse.of(status.value(), code, message, null));
    }
}
