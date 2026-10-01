package com.minishop.server.security;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.HexFormat;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class VerificationCodeHasher {
    private final SecretKeySpec key;

    public VerificationCodeHasher(@Value("${app.auth.otp-secret}") String base64Secret) {
        byte[] secret = Base64.getDecoder().decode(base64Secret);
        if (secret.length < 32) throw new IllegalArgumentException("app.auth.otp-secret must be at least 32 bytes (Base64)");
        this.key = new SecretKeySpec(secret, "HmacSHA256");
    }

    public String hash(String email, String code) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(key);
            return HexFormat.of().formatHex(mac.doFinal((email + ":" + code).getBytes(StandardCharsets.UTF_8)));
        } catch (Exception error) {
            throw new IllegalStateException("Cannot hash verification code", error);
        }
    }

    public boolean matches(String email, String code, String expectedHash) {
        return MessageDigest.isEqual(hash(email, code).getBytes(StandardCharsets.US_ASCII),
                expectedHash.getBytes(StandardCharsets.US_ASCII));
    }
}
