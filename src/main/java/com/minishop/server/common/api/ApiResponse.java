package com.minishop.server.common.api;

/** Response envelope dùng chung cho API của MiniShop. */
public record ApiResponse<T>(int status, int code, String message, T data) {
    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(200, 200, "Thành công.", data);
    }

    public static <T> ApiResponse<T> of(int status, int code, String message, T data) {
        return new ApiResponse<>(status, code, message, data);
    }
}
