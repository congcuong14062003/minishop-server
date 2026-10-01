package com.minishop.server.service;

import com.minishop.server.repository.EmailRegistrationCodeRepository;
import com.minishop.server.repository.PasswordResetCodeRepository;
import com.minishop.server.repository.RefreshTokenRepository;
import java.time.Instant;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthCleanupJob {
    private final EmailRegistrationCodeRepository codes;
    private final PasswordResetCodeRepository resetCodes;
    private final RefreshTokenRepository refreshTokens;

    public AuthCleanupJob(EmailRegistrationCodeRepository codes, PasswordResetCodeRepository resetCodes,
                          RefreshTokenRepository refreshTokens) {
        this.codes = codes;
        this.resetCodes = resetCodes;
        this.refreshTokens = refreshTokens;
    }

    @Scheduled(fixedDelayString = "${app.auth.cleanup-interval-ms:3600000}")
    @Transactional
    public void deleteExpiredRecords() {
        Instant now = Instant.now();
        codes.deleteExpired(now);
        resetCodes.deleteExpired(now);
        refreshTokens.deleteExpired(now);
    }
}
