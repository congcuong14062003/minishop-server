package com.minishop.server.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "password_reset_codes", schema = "minishop")
public class PasswordResetCodeEntity {
    @Id
    @Column(columnDefinition = "text")
    private String email;
    @Column(name = "code_hash", nullable = false, columnDefinition = "text")
    private String codeHash;
    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;
    @Column(name = "sent_at", nullable = false)
    private Instant sentAt;
    @Column(name = "failed_attempts", nullable = false)
    private int failedAttempts;

    protected PasswordResetCodeEntity() {}

    public PasswordResetCodeEntity(String email, String codeHash, Instant expiresAt, Instant sentAt) {
        this.email = email;
        this.codeHash = codeHash;
        this.expiresAt = expiresAt;
        this.sentAt = sentAt;
    }

    public String getCodeHash() { return codeHash; }
    public Instant getExpiresAt() { return expiresAt; }
    public Instant getSentAt() { return sentAt; }
    public int getFailedAttempts() { return failedAttempts; }
    public void incrementFailedAttempts() { failedAttempts++; }
    public void replace(String hash, Instant expires, Instant sent) {
        codeHash = hash;
        expiresAt = expires;
        sentAt = sent;
        failedAttempts = 0;
    }
}
