package com.ynov.crud.log;

import java.time.Instant;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Component
public class LogsClient {

    private final RestTemplate restTemplate;
    private final String logsApiUrl;

    public LogsClient(RestTemplate restTemplate, @Value("${logs.api.url}") String logsApiUrl) {
        this.restTemplate = restTemplate;
        this.logsApiUrl = logsApiUrl;
    }

    public void send(String message, String method, String path, LogLevel level) {
        LogPayload payload = new LogPayload(
                message,
                "[CrudAPI] " + method + " " + path,
                Instant.now().toString(),
                level
        );
        try {
            restTemplate.postForEntity(logsApiUrl + "/api/v1/logs", payload, Void.class);
        } catch (Exception ignored) {
        }
    }
}
