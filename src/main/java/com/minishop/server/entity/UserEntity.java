package com.minishop.server.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "users", schema = "minishop")
public class UserEntity {
    @Id
    private UUID id;
    @Column(columnDefinition = "text")
    private String email;
    @Column(name = "full_name", nullable = false, columnDefinition = "text")
    private String fullName;
    @Column(name = "password_hash", columnDefinition = "text")
    private String passwordHash;
    @Column(nullable = false, columnDefinition = "text")
    private String status;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected UserEntity() {}

    public UserEntity(String email, String fullName, String passwordHash) {
        this.id = UUID.randomUUID();
        this.email = email;
        this.fullName = fullName;
        this.passwordHash = passwordHash;
        this.status = "active";
        this.createdAt = Instant.now();
        this.updatedAt = this.createdAt;
    }

    public UUID getId() { return id; }
    public String getEmail() { return email; }
    public String getFullName() { return fullName; }
    public String getPasswordHash() { return passwordHash; }
    public String getStatus() { return status; }
    public void changePassword(String hash) {
        passwordHash = hash;
        updatedAt = Instant.now();
    }
}
