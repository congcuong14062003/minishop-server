package com.minishop.server.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.minishop.server.common.exception.ApiException;
import com.minishop.server.dto.request.LoginRequest;
import com.minishop.server.dto.request.VerifyEmailRequest;
import com.minishop.server.dto.response.TokenResponse;
import com.minishop.server.entity.EmailRegistrationCodeEntity;
import com.minishop.server.entity.RefreshTokenEntity;
import com.minishop.server.entity.UserEntity;
import com.minishop.server.repository.EmailRegistrationCodeRepository;
import com.minishop.server.repository.RefreshTokenRepository;
import com.minishop.server.repository.UserRepository;
import com.minishop.server.security.TokenHashing;
import com.minishop.server.security.VerificationCodeHasher;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.password.PasswordEncoder;

class AuthServiceTest {
    private final UserRepository users = mock(UserRepository.class);
    private final EmailRegistrationCodeRepository codes = mock(EmailRegistrationCodeRepository.class);
    private final RefreshTokenRepository refreshTokens = mock(RefreshTokenRepository.class);
    private final PasswordEncoder passwordEncoder = mock(PasswordEncoder.class);
    private final VerificationEmailService emailService = mock(VerificationEmailService.class);
    private final TokenService tokenService = mock(TokenService.class);
    private final VerificationCodeHasher codeHasher = new VerificationCodeHasher(
            Base64.getEncoder().encodeToString(new byte[32]));
    private final AuthService service = new AuthService(users, codes, refreshTokens, passwordEncoder,
            codeHasher, emailService, tokenService, 10, 60, 5);

    @Test
    void wrongVerificationCodeConsumesAnAttempt() {
        String email = "test@example.invalid";
        EmailRegistrationCodeEntity challenge = new EmailRegistrationCodeEntity(email, "Test", "hash",
                codeHasher.hash(email, "123456"), Instant.now().plusSeconds(600), Instant.now());
        when(codes.findLockedByEmail(email)).thenReturn(Optional.of(challenge));

        assertTrue(service.verifyRegistration(new VerifyEmailRequest(email, "654321")).isEmpty());
        assertEquals(1, challenge.getFailedAttempts());
    }

    @Test
    void validCodeCreatesUserAndTokens() {
        String email = "test@example.invalid";
        EmailRegistrationCodeEntity challenge = new EmailRegistrationCodeEntity(email, "Test", "hash",
                codeHasher.hash(email, "123456"), Instant.now().plusSeconds(600), Instant.now());
        when(codes.findLockedByEmail(email)).thenReturn(Optional.of(challenge));
        when(users.save(any(UserEntity.class))).thenAnswer(call -> call.getArgument(0));
        TokenResponse tokens = new TokenResponse("access", "refresh", "Bearer", 900);
        when(tokenService.newSession(any(UserEntity.class))).thenReturn(tokens);

        assertEquals(tokens, service.verifyRegistration(new VerifyEmailRequest(email, "123456")).orElseThrow());
        verify(codes).delete(challenge);
    }

    @Test
    void replayedRefreshTokenRevokesItsFamily() {
        String rawToken = "old-token";
        UUID familyId = UUID.randomUUID();
        RefreshTokenEntity token = new RefreshTokenEntity(UUID.randomUUID(), familyId,
                TokenHashing.sha256(rawToken), Instant.now().plusSeconds(3600));
        token.revoke(Instant.now());
        when(refreshTokens.findLockedByTokenHash(TokenHashing.sha256(rawToken))).thenReturn(Optional.of(token));

        assertTrue(service.refresh(rawToken).isEmpty());
        verify(refreshTokens).revokeFamily(eq(familyId), any(Instant.class));
    }

    @Test
    void customerCannotCreateAdminSession() {
        UserEntity user = new UserEntity("customer@example.invalid", "Customer", "hash");
        when(users.findByEmailIgnoreCase(user.getEmail())).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("correct-password", "hash")).thenReturn(true);
        when(users.hasActiveRole(user.getId(), "ADMIN")).thenReturn(false);

        ApiException error = assertThrows(ApiException.class,
                () -> service.loginAdmin(new LoginRequest(user.getEmail(), "correct-password")));

        assertEquals(401, error.status().value());
        verify(tokenService, never()).newSession(any(UserEntity.class));
    }

    @Test
    void adminCanCreateSession() {
        UserEntity user = new UserEntity("admin@example.invalid", "Admin", "hash");
        TokenResponse tokens = new TokenResponse("access", "refresh", "Bearer", 900);
        when(users.findByEmailIgnoreCase(user.getEmail())).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("correct-password", "hash")).thenReturn(true);
        when(users.hasActiveRole(user.getId(), "ADMIN")).thenReturn(true);
        when(tokenService.newSession(user)).thenReturn(tokens);

        assertEquals(tokens, service.loginAdmin(new LoginRequest(user.getEmail(), "correct-password")));
    }
}
