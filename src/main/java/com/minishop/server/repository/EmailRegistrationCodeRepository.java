package com.minishop.server.repository;

import com.minishop.server.entity.EmailRegistrationCodeEntity;
import jakarta.persistence.LockModeType;
import java.time.Instant;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface EmailRegistrationCodeRepository extends JpaRepository<EmailRegistrationCodeEntity, String> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<EmailRegistrationCodeEntity> findLockedByEmail(String email);

    @Modifying
    @Query("delete from EmailRegistrationCodeEntity c where c.expiresAt < :now")
    int deleteExpired(@Param("now") Instant now);
}
