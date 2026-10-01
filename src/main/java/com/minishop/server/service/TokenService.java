package com.minishop.server.service;

import com.minishop.server.dto.response.TokenResponse;
import com.minishop.server.entity.RefreshTokenEntity;
import com.minishop.server.entity.UserEntity;
import com.minishop.server.repository.RefreshTokenRepository;
import com.minishop.server.security.TokenHashing;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.stereotype.Service;

@Service
public class TokenService {
    private final RefreshTokenRepository refreshTokens;
    private final JwtEncoder jwtEncoder;
    private final String issuer;
    private final long accessTokenMinutes;
    private final long refreshTokenDays;
    private final SecureRandom random = new SecureRandom();

    public TokenService(RefreshTokenRepository refreshTokens, JwtEncoder jwtEncoder,
                        @Value("${app.auth.issuer}") String issuer,
                        @Value("${app.auth.access-token-minutes}") long accessTokenMinutes,
                        @Value("${app.auth.refresh-token-days}") long refreshTokenDays) {
        this.refreshTokens = refreshTokens;
        this.jwtEncoder = jwtEncoder;
        this.issuer = issuer;
        this.accessTokenMinutes = accessTokenMinutes;
        this.refreshTokenDays = refreshTokenDays;
    }

    public TokenResponse newSession(UserEntity user) {
        return issue(user, UUID.randomUUID(), Instant.now().plus(refreshTokenDays, ChronoUnit.DAYS));
    }

    public TokenResponse rotate(UserEntity user, UUID familyId, Instant absoluteExpiry) {
        return issue(user, familyId, absoluteExpiry);
    }

    private TokenResponse issue(UserEntity user, UUID familyId, Instant refreshExpiry) {
        Instant now = Instant.now();
        Instant accessExpiry = now.plus(accessTokenMinutes, ChronoUnit.MINUTES);
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(issuer)
                .subject(user.getId().toString())
                .issuedAt(now)
                .expiresAt(accessExpiry)
                .id(UUID.randomUUID().toString())
                .claim("token_type", "access")
                .build();
        String accessToken = jwtEncoder.encode(JwtEncoderParameters.from(
                JwsHeader.with(MacAlgorithm.HS256).build(), claims)).getTokenValue();
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        String refreshToken = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        refreshTokens.save(new RefreshTokenEntity(user.getId(), familyId,
                TokenHashing.sha256(refreshToken), refreshExpiry));
        return new TokenResponse(accessToken, refreshToken, "Bearer", accessTokenMinutes * 60);
    }
}
