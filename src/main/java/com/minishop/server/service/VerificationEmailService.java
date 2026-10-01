package com.minishop.server.service;

import com.minishop.server.common.exception.ApiException;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class VerificationEmailService {
    private final ObjectProvider<JavaMailSender> mailSender;
    private final String from;

    public VerificationEmailService(ObjectProvider<JavaMailSender> mailSender,
                                    @Value("${app.mail.from:}") String from) {
        this.mailSender = mailSender;
        this.from = from;
    }

    public void sendRegistrationCode(String to, String code, long validMinutes) {
        sendCode(to, code, validMinutes, "Mã xác minh MiniShop", "Mã xác minh của bạn là ");
    }

    public void sendPasswordResetCode(String to, String code, long validMinutes) {
        sendCode(to, code, validMinutes, "Khôi phục mật khẩu MiniShop", "Mã đặt lại mật khẩu của bạn là ");
    }

    private void sendCode(String to, String code, long validMinutes, String subject, String prefix) {
        JavaMailSender sender = mailSender.getIfAvailable();
        if (sender == null || from.isBlank()) {
            throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, 503, "Dịch vụ email chưa được cấu hình.");
        }
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(to);
        message.setSubject(subject);
        message.setText(prefix + code + ". Mã có hiệu lực " + validMinutes
                + " phút. Nếu bạn không yêu cầu, hãy bỏ qua email này.");
        try {
            sender.send(message);
        } catch (MailException error) {
            throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, 503, "Không gửi được email xác minh.");
        }
    }
}
