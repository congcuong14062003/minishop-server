package com.minishop.server.service;

import com.minishop.server.common.exception.ApiException;
import com.minishop.server.dto.request.ResetPasswordRequest;
import com.minishop.server.entity.PasswordResetCodeEntity;
import com.minishop.server.entity.UserEntity;
import com.minishop.server.repository.PasswordResetCodeRepository;
import com.minishop.server.repository.RefreshTokenRepository;
import com.minishop.server.repository.UserRepository;
import com.minishop.server.security.VerificationCodeHasher;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Locale;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PasswordResetService {
    private final UserRepository users;
    private final PasswordResetCodeRepository codes;
    private final RefreshTokenRepository refreshTokens;
    private final PasswordEncoder encoder;
    private final VerificationCodeHasher hasher;
    private final VerificationEmailService emailService;
    private final long codeMinutes;
    private final long cooldownSeconds;
    private final int maxAttempts;
    private final SecureRandom random = new SecureRandom();

    public PasswordResetService(UserRepository users, PasswordResetCodeRepository codes,
                                RefreshTokenRepository refreshTokens, PasswordEncoder encoder,
                                VerificationCodeHasher hasher, VerificationEmailService emailService,
                                @Value("${app.auth.verification-code-minutes}") long codeMinutes,
                                @Value("${app.auth.resend-cooldown-seconds}") long cooldownSeconds,
                                @Value("${app.auth.max-verification-attempts}") int maxAttempts) {
        this.users = users;
        this.codes = codes;
        this.refreshTokens = refreshTokens;
        this.encoder = encoder;
        this.hasher = hasher;
        this.emailService = emailService;
        this.codeMinutes = codeMinutes;
        this.cooldownSeconds = cooldownSeconds;
        this.maxAttempts = maxAttempts;
    }

    @Transactional
    public void requestCode(String rawEmail) {
        String email = normalize(rawEmail);
        Optional<UserEntity> user = users.findByEmailIgnoreCase(email);
        if (user.isEmpty() || !"active".equals(user.get().getStatus())) return;
        Instant now = Instant.now();
        Optional<PasswordResetCodeEntity> existing = codes.findLockedByEmail(email);
        if (existing.isPresent() && existing.get().getSentAt().plusSeconds(cooldownSeconds).isAfter(now)) return;
        String code = String.format(Locale.ROOT, "%06d", random.nextInt(1_000_000));
        String hash = hasher.hash("reset:" + email, code);
        Instant expires = now.plus(codeMinutes, ChronoUnit.MINUTES);
        if (existing.isPresent()) existing.get().replace(hash, expires, now);
        else codes.save(new PasswordResetCodeEntity(email, hash, expires, now));
        emailService.sendPasswordResetCode(email, code, codeMinutes);
    }

    @Transactional
    public boolean reset(ResetPasswordRequest request) {
        if (request.newPassword().getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new ApiException(HttpStatus.BAD_REQUEST, 400, "Mật khẩu quá dài.");
        }
        String email = normalize(request.email());
        Optional<PasswordResetCodeEntity> found = codes.findLockedByEmail(email);
        if (found.isEmpty()) return false;
        PasswordResetCodeEntity challenge = found.get();
        Instant now = Instant.now();
        if (!challenge.getExpiresAt().isAfter(now) || challenge.getFailedAttempts() >= maxAttempts) {
            codes.delete(challenge);
            return false;
        }
        if (!hasher.matches("reset:" + email, request.code(), challenge.getCodeHash())) {
            challenge.incrementFailedAttempts();
            return false;
        }
        Optional<UserEntity> user = users.findByEmailIgnoreCase(email);
        if (user.isEmpty() || !"active".equals(user.get().getStatus())) {
            codes.delete(challenge);
            return false;
        }
        user.get().changePassword(encoder.encode(request.newPassword()));
        refreshTokens.revokeAllForUser(user.get().getId(), now);
        codes.delete(challenge);
        return true;
    }

    private String normalize(String email) { return email.strip().toLowerCase(Locale.ROOT); }
}
