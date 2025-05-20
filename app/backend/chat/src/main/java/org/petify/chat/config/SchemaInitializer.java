package org.petify.chat.config;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class SchemaInitializer {

    private final JdbcTemplate jdbc;

    @Autowired
    public SchemaInitializer(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @PostConstruct
    public void ensureColumns() {
        log.info("[SchemaInit] Checking chat_room columns…");

        boolean hasUserVisible       = columnExists("chat_room", "user_visible");
        boolean hasShelterVisible    = columnExists("chat_room", "shelter_visible");
        boolean hasUserHiddenAt      = columnExists("chat_room", "user_hidden_at");
        boolean hasShelterHiddenAt   = columnExists("chat_room", "shelter_hidden_at");

        if (hasUserVisible && hasShelterVisible && hasUserHiddenAt && hasShelterHiddenAt) {
            log.info("[SchemaInit] Columns already exist – nothing to do.");
            return;
        }

        StringBuilder alter = new StringBuilder("ALTER TABLE chat_room ");

        if (!hasUserVisible)
            alter.append("ADD COLUMN user_visible BOOLEAN NOT NULL DEFAULT TRUE, ");
        if (!hasShelterVisible)
            alter.append("ADD COLUMN shelter_visible BOOLEAN NOT NULL DEFAULT TRUE, ");
        if (!hasUserHiddenAt)
            alter.append("ADD COLUMN user_hidden_at TIMESTAMP, ");
        if (!hasShelterHiddenAt)
            alter.append("ADD COLUMN shelter_hidden_at TIMESTAMP, ");

        alter.setLength(alter.length() - 2);
        alter.append(";");

        log.warn("[SchemaInit] Executing: {}", alter);
        jdbc.execute(alter.toString());
        log.info("[SchemaInit] Columns added/updated successfully.");
    }

    private boolean columnExists(String table, String column) {
        String sql = """
                SELECT EXISTS (
                   SELECT 1 FROM information_schema.columns
                   WHERE table_name = ?
                     AND column_name = ?
                )
                """;
        return Boolean.TRUE.equals(
                jdbc.queryForObject(sql, Boolean.class, table, column));
    }
}
