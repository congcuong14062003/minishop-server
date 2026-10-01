package com.minishop.server.controller;

import com.minishop.server.common.api.ApiResponse;
import com.minishop.server.common.exception.ApiException;
import com.minishop.server.dto.request.LoginRequest;
import com.minishop.server.dto.request.EmailRequest;
import com.minishop.server.dto.request.RefreshTokenRequest;
import com.minishop.server.dto.request.RegisterRequest;
import com.minishop.server.dto.request.ResetPasswordRequest;
import com.minishop.server.dto.request.VerifyEmailRequest;
import com.minishop.server.dto.response.TokenResponse;
import com.minishop.server.dto.response.UserResponse;
import com.minishop.server.service.AuthService;
import com.minishop.server.service.PasswordResetService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    private final AuthService authService;
    private final PasswordResetService passwordResetService;

    public AuthController(AuthService authService, PasswordResetService passwordResetService) {
        this.authService = authService;
        this.passwordResetService = passwordResetService;
    }

    @PostMapping("/register/request-code")
    public ApiResponse<Void> requestCode(@Valid @RequestBody RegisterRequest request) {
        authService.requestRegistrationCode(request);
        return ApiResponse.of(200, 200, "Nếu email chưa đăng ký, mã xác minh đã được gửi.", null);
    }

    @PostMapping("/register/verify")
    public ApiResponse<TokenResponse> verify(@Valid @RequestBody VerifyEmailRequest request) {
        TokenResponse tokens = authService.verifyRegistration(request)
                .orElseThrow(() -> new ApiException(HttpStatus.BAD_REQUEST, 400, "Mã xác minh không hợp lệ hoặc đã hết hạn."));
        return ApiResponse.success(tokens);
    }

    @PostMapping("/login")
    public ApiResponse<TokenResponse> login(@Valid @RequestBody LoginRequest request) {
        return ApiResponse.success(authService.login(request));
    }

    @PostMapping("/admin/login")
    public ApiResponse<TokenResponse> loginAdmin(@Valid @RequestBody LoginRequest request) {
        return ApiResponse.success(authService.loginAdmin(request));
    }

    @PostMapping("/password/forgot")
    public ApiResponse<Void> forgotPassword(@Valid @RequestBody EmailRequest request) {
        passwordResetService.requestCode(request.email());
        return ApiResponse.of(200, 200, "Nếu email đã có tài khoản, mã khôi phục đã được gửi.", null);
    }

    @PostMapping("/password/reset")
    public ApiResponse<Void> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        if (!passwordResetService.reset(request)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, 400, "Mã khôi phục không hợp lệ hoặc đã hết hạn.");
        }
        return ApiResponse.success(null);
    }

    @PostMapping("/refresh")
    public ApiResponse<TokenResponse> refresh(@Valid @RequestBody RefreshTokenRequest request) {
        TokenResponse tokens = authService.refresh(request.refreshToken())
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, 401, "Refresh token không hợp lệ."));
        return ApiResponse.success(tokens);
    }

    @PostMapping("/logout")
    public ApiResponse<Void> logout(@Valid @RequestBody RefreshTokenRequest request) {
        authService.logout(request.refreshToken());
        return ApiResponse.success(null);
    }

    @GetMapping("/me")
    public ApiResponse<UserResponse> me(@AuthenticationPrincipal Jwt jwt) {
        return ApiResponse.success(authService.me(jwt.getSubject()));
    }
}
