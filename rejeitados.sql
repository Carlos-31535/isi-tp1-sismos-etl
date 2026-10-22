-- Tabela dos eventos rejeitados pela validacao do KNIME (valores impossiveis).
-- Executar depois do init.sql e do triggers.sql.
CREATE TABLE IF NOT EXISTS sismos_rejeitados (
    id               BIGSERIAL PRIMARY KEY,
    rejeitado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),
    fonte            TEXT,
    formato          TEXT,
    id_evento        TEXT,
    data_hora        TIMESTAMP,
    magnitude        DOUBLE PRECISION,
    local_original   TEXT,
    longitude        DOUBLE PRECISION,
    latitude         DOUBLE PRECISION,
    profundidade_km  DOUBLE PRECISION,
    motivo           TEXT
);
