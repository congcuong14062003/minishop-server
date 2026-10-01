package com.minishop.server.repository;

import com.minishop.server.entity.UserEntity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserRepository extends JpaRepository<UserEntity, UUID> {
    Optional<UserEntity> findByEmailIgnoreCase(String email);
    boolean existsByEmailIgnoreCase(String email);

    @Query(value = """
            SELECT EXISTS (
                SELECT 1 FROM minishop.users u
                JOIN minishop.user_roles ur ON ur.user_id = u.id
                WHERE u.id = :userId AND u.status = 'active' AND ur.role_code = :roleCode
            )
            """, nativeQuery = true)
    boolean hasActiveRole(@Param("userId") UUID userId, @Param("roleCode") String roleCode);
}
