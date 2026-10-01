package com.minishop.server.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.minishop.server.dto.request.ResetPasswordRequest;
import com.minishop.server.entity.PasswordResetCodeEntity;
import com.minishop.server.entity.UserEntity;
import com.minishop.server.repository.PasswordResetCodeRepository;
import com.minishop.server.repository.RefreshTokenRepository;
import com.minishop.server.repository.UserRepository;
import com.minishop.server.security.VerificationCodeHasher;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.password.PasswordEncoder;

class PasswordResetServiceTest {
    private final UserRepository users = mock(UserRepository.class);
    private final PasswordResetCodeRepository codes = mock(PasswordResetCodeRepository.class);
    private final RefreshTokenRepository refreshTokens = mock(RefreshTokenRepository.class);
    private final PasswordEncoder encoder = mock(PasswordEncoder.class);
    private final VerificationEmailService email = mock(VerificationEmailService.class);
    private final VerificationCodeHasher hasher = new VerificationCodeHasher(
            Base64.getEncoder().encodeToString(new byte[32]));
    private final PasswordResetService service = new PasswordResetService(
            users, codes, refreshTokens, encoder, hasher, email, 10, 60, 5);

    @Test
    void wrongCodeConsumesAttemptWithoutChangingPassword() {
        String address = "test@example.invalid";
        PasswordResetCodeEntity challenge = new PasswordResetCodeEntity(address,
                hasher.hash("reset:" + address, "123456"), Instant.now().plusSeconds(600), Instant.now());
        when(codes.findLockedByEmail(address)).thenReturn(Optional.of(challenge));

        assertFalse(service.reset(new ResetPasswordRequest(address, "654321", "newPassword123")));
        assertEquals(1, challenge.getFailedAttempts());
    }

    @Test
    void validCodeChangesPasswordAndRevokesExistingSessions() {
        String address = "test@example.invalid";
        UserEntity user = new UserEntity(address, "Test", "old-hash");
        PasswordResetCodeEntity challenge = new PasswordResetCodeEntity(address,
                hasher.hash("reset:" + address, "123456"), Instant.now().plusSeconds(600), Instant.now());
        when(codes.findLockedByEmail(address)).thenReturn(Optional.of(challenge));
        when(users.findByEmailIgnoreCase(address)).thenReturn(Optional.of(user));
        when(encoder.encode("newPassword123")).thenReturn("new-hash");

        assertTrue(service.reset(new ResetPasswordRequest(address, "123456", "newPassword123")));
        assertEquals("new-hash", user.getPasswordHash());
        verify(refreshTokens).revokeAllForUser(eq(user.getId()), any(Instant.class));
        verify(codes).delete(challenge);
    }
}
