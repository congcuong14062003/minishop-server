package com.minishop.server.dto.response;

public record TokenResponse(String accessToken, String refreshToken,
                            String tokenType, long expiresInSeconds) {}
