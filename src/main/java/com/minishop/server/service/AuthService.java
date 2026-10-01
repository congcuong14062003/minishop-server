package com.minishop.server.service;

import com.minishop.server.common.exception.ApiException;
import com.minishop.server.dto.request.LoginRequest;
import com.minishop.server.dto.request.RegisterRequest;
import com.minishop.server.dto.request.VerifyEmailRequest;
import com.minishop.server.dto.response.TokenResponse;
import com.minishop.server.dto.response.UserResponse;
import com.minishop.server.entity.EmailRegistrationCodeEntity;
import com.minishop.server.entity.RefreshTokenEntity;
import com.minishop.server.entity.UserEntity;
import com.minishop.server.repository.EmailRegistrationCodeRepository;
import com.minishop.server.repository.RefreshTokenRepository;
import com.minishop.server.repository.UserRepository;
import com.minishop.server.security.TokenHashing;
import com.minishop.server.security.VerificationCodeHasher;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {
    private final UserRepository users;
    private final EmailRegistrationCodeRepository codes;
    private final RefreshTokenRepository refreshTokens;
    private final PasswordEncoder passwordEncoder;
    private final VerificationCodeHasher codeHasher;
    private final VerificationEmailService emailService;
    private final TokenService tokenService;
    private final long codeMinutes;
    private final long cooldownSeconds;
    private final int maxAttempts;
    private final SecureRandom random = new SecureRandom();
    private final String dummyPasswordHash;

    public AuthService(UserRepository users, EmailRegistrationCodeRepository codes,
            RefreshTokenRepository refreshTokens, PasswordEncoder passwordEncoder,
            VerificationCodeHasher codeHasher, VerificationEmailService emailService,
            TokenService tokenService,
            @Value("${app.auth.verification-code-minutes}") long codeMinutes,
            @Value("${app.auth.resend-cooldown-seconds}") long cooldownSeconds,
            @Value("${app.auth.max-verification-attempts}") int maxAttempts) {
        this.users = users;
        this.codes = codes;
        this.refreshTokens = refreshTokens;
        this.passwordEncoder = passwordEncoder;
        this.codeHasher = codeHasher;
        this.emailService = emailService;
        this.tokenService = tokenService;
        this.codeMinutes = codeMinutes;
        this.cooldownSeconds = cooldownSeconds;
        this.maxAttempts = maxAttempts;
        this.dummyPasswordHash = passwordEncoder.encode(UUID.randomUUID().toString());
    }

    @Transactional
    public void requestRegistrationCode(RegisterRequest request) {
        String email = normalizeEmail(request.email());
        boolean exists = users.existsByEmailIgnoreCase(email);

        System.out.printf(
                "[REGISTER] email=[%s], exists=%s%n",
                email,
                exists);

        if (exists) {
            throw new ApiException(
                    HttpStatus.CONFLICT,
                    409,
                    "Email đã được sử dụng.");
        }
        if (request.password().getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new ApiException(HttpStatus.BAD_REQUEST, 400, "Mật khẩu quá dài.");
        }
        String passwordHash = passwordEncoder.encode(request.password());
        Instant now = Instant.now();
        Optional<EmailRegistrationCodeEntity> existing = codes.findLockedByEmail(email);
        if (existing.isPresent() && existing.get().getSentAt().plusSeconds(cooldownSeconds).isAfter(now))
            return;

        String code = String.format(Locale.ROOT, "%06d", random.nextInt(1_000_000));
        String hash = codeHasher.hash(email, code);
        String fullName = request.fullName().strip();
        Instant expiresAt = now.plus(codeMinutes, ChronoUnit.MINUTES);
        if (existing.isPresent()) {
            existing.get().replace(fullName, passwordHash, hash, expiresAt, now);
        } else {
            codes.save(new EmailRegistrationCodeEntity(email, fullName, passwordHash, hash, expiresAt, now));
        }
        emailService.sendRegistrationCode(email, code, codeMinutes);
    }

    @Transactional
    public Optional<TokenResponse> verifyRegistration(VerifyEmailRequest request) {
        String email = normalizeEmail(request.email());
        Optional<EmailRegistrationCodeEntity> found = codes.findLockedByEmail(email);
        if (found.isEmpty())
            return Optional.empty();
        EmailRegistrationCodeEntity challenge = found.get();
        Instant now = Instant.now();
        if (!challenge.getExpiresAt().isAfter(now) || challenge.getFailedAttempts() >= maxAttempts) {
            codes.delete(challenge);
            return Optional.empty();
        }
        if (!codeHasher.matches(email, request.code(), challenge.getCodeHash())) {
            challenge.incrementFailedAttempts();
            return Optional.empty();
        }
        if (users.existsByEmailIgnoreCase(email)) {
            codes.delete(challenge);
            return Optional.empty();
        }
        UserEntity user = users.save(new UserEntity(email, challenge.getFullName(), challenge.getPasswordHash()));
        codes.delete(challenge);
        return Optional.of(tokenService.newSession(user));
    }

    @Transactional
    public TokenResponse login(LoginRequest request) {
        Optional<UserEntity> found = users.findByEmailIgnoreCase(normalizeEmail(request.email()));
        String hash = found.map(UserEntity::getPasswordHash).orElse(null);
        boolean matches = passwordEncoder.matches(request.password(), hash == null ? dummyPasswordHash : hash);
        if (!matches || found.isEmpty() || !"active".equals(found.get().getStatus())) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, 401, "Email hoặc mật khẩu không đúng.");
        }
        return tokenService.newSession(found.get());
    }

    @Transactional
    public TokenResponse loginAdmin(LoginRequest request) {
        Optional<UserEntity> found = users.findByEmailIgnoreCase(normalizeEmail(request.email()));
        String hash = found.map(UserEntity::getPasswordHash).orElse(null);
        boolean matches = passwordEncoder.matches(request.password(), hash == null ? dummyPasswordHash : hash);
        if (!matches || found.isEmpty() || !users.hasActiveRole(found.get().getId(), "ADMIN")) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, 401, "Thông tin đăng nhập quản trị không hợp lệ.");
        }
        return tokenService.newSession(found.get());
    }

    @Transactional
    public Optional<TokenResponse> refresh(String rawToken) {
        Optional<RefreshTokenEntity> found = refreshTokens.findLockedByTokenHash(TokenHashing.sha256(rawToken));
        if (found.isEmpty())
            return Optional.empty();
        RefreshTokenEntity token = found.get();
        Instant now = Instant.now();
        if (token.getRevokedAt() != null || !token.getExpiresAt().isAfter(now)) {
            refreshTokens.revokeFamily(token.getFamilyId(), now);
            return Optional.empty();
        }
        Optional<UserEntity> foundUser = users.findById(token.getUserId());
        if (foundUser.isEmpty() || !"active".equals(foundUser.get().getStatus())) {
            refreshTokens.revokeFamily(token.getFamilyId(), now);
            return Optional.empty();
        }
        token.revoke(now);
        return Optional.of(tokenService.rotate(foundUser.get(), token.getFamilyId(), token.getExpiresAt()));
    }

    @Transactional
    public void logout(String rawToken) {
        refreshTokens.findLockedByTokenHash(TokenHashing.sha256(rawToken))
                .ifPresent(token -> refreshTokens.revokeFamily(token.getFamilyId(), Instant.now()));
    }

    @Transactional(readOnly = true)
    public UserResponse me(String subject) {
        UUID userId;
        try {
            userId = UUID.fromString(subject);
        } catch (IllegalArgumentException error) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, 401, "Token không hợp lệ.");
        }
        UserEntity user = users.findById(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, 401, "Token không hợp lệ."));
        if (!"active".equals(user.getStatus())) {
            throw new ApiException(HttpStatus.FORBIDDEN, 403, "Tài khoản đã bị khóa.");
        }
        return UserResponse.from(user);
    }

    private String normalizeEmail(String email) {
        return email.strip().toLowerCase(Locale.ROOT);
    }
}
