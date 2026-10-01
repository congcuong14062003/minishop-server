package com.minishop.server.dto.response;

import com.minishop.server.entity.UserEntity;
import java.util.UUID;

public record UserResponse(UUID id, String email, String fullName) {
    public static UserResponse from(UserEntity user) {
        return new UserResponse(user.getId(), user.getEmail(), user.getFullName());
    }
}
