package com.minishop.server.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "email_registration_codes", schema = "minishop")
public class EmailRegistrationCodeEntity {
    @Id
    @Column(columnDefinition = "text")
    private String email;
    @Column(name = "full_name", nullable = false, columnDefinition = "text")
    private String fullName;
    @Column(name = "password_hash", nullable = false, columnDefinition = "text")
    private String passwordHash;
    @Column(name = "code_hash", nullable = false, columnDefinition = "text")
    private String codeHash;
    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;
    @Column(name = "sent_at", nullable = false)
    private Instant sentAt;
    @Column(name = "failed_attempts", nullable = false)
    private int failedAttempts;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected EmailRegistrationCodeEntity() {}

    public EmailRegistrationCodeEntity(String email, String fullName, String passwordHash,
                                       String codeHash, Instant expiresAt, Instant sentAt) {
        this.email = email;
        this.fullName = fullName;
        this.passwordHash = passwordHash;
        this.codeHash = codeHash;
        this.expiresAt = expiresAt;
        this.sentAt = sentAt;
        this.createdAt = sentAt;
    }

    public String getEmail() { return email; }
    public String getFullName() { return fullName; }
    public String getPasswordHash() { return passwordHash; }
    public String getCodeHash() { return codeHash; }
    public Instant getExpiresAt() { return expiresAt; }
    public Instant getSentAt() { return sentAt; }
    public int getFailedAttempts() { return failedAttempts; }
    public void incrementFailedAttempts() { failedAttempts++; }
    public void replace(String fullName, String passwordHash, String codeHash,
                        Instant expiresAt, Instant sentAt) {
        this.fullName = fullName;
        this.passwordHash = passwordHash;
        this.codeHash = codeHash;
        this.expiresAt = expiresAt;
        this.sentAt = sentAt;
        this.failedAttempts = 0;
    }
}
