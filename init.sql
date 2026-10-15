-- Corre automaticamente na primeira vez que o contentor do Postgres arranca.
-- Para repetir: docker compose down -v  (apaga os dados) e docker compose up -d

CREATE EXTENSION IF NOT EXISTS postgis;

-- 1) Dados brutos, tal como chegam das APIs (guardados pelo Node-RED)
CREATE TABLE IF NOT EXISTS raw_sismos (
    id            BIGSERIAL PRIMARY KEY,
    fonte         TEXT        NOT NULL,          -- 'USGS', 'IPMA', ...
    formato       TEXT,                          -- 'geojson', 'csv', 'xml', 'json'
    id_externo    TEXT,                          -- id do evento na fonte
    payload       TEXT        NOT NULL,          -- registo original
    recolhido_em  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (fonte, id_externo)
);

-- 2) Dados tratados e fundidos (escritos pelo KNIME)
CREATE TABLE IF NOT EXISTS sismos (
    id                BIGSERIAL PRIMARY KEY,
    data_hora         TIMESTAMPTZ      NOT NULL,
    latitude          DOUBLE PRECISION NOT NULL,
    longitude         DOUBLE PRECISION NOT NULL,
    profundidade_km   DOUBLE PRECISION,
    magnitude         DOUBLE PRECISION,
    classe_magnitude  TEXT,                      -- micro, ligeiro, moderado, forte
    local_original    TEXT,                      -- texto livre da fonte
    localidade        TEXT,                      -- extraído por regex
    pais              TEXT,
    distancia_km      DOUBLE PRECISION,          -- extraída por regex
    direcao           TEXT,                      -- extraída por regex (N, SW, ...)
    dist_portugal_km  DOUBLE PRECISION,
    nivel_alerta      TEXT,
    fontes            TEXT,                      -- ex.: 'USGS,IPMA' após merge
    ids_externos      TEXT,
    geom              geometry(Point, 4326),
    carregado_em      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sismos_data_hora ON sismos (data_hora DESC);
CREATE INDEX IF NOT EXISTS idx_sismos_magnitude ON sismos (magnitude);
CREATE INDEX IF NOT EXISTS idx_sismos_geom      ON sismos USING GIST (geom);

-- 3) Logs de execução (Node-RED e KNIME escrevem aqui)
CREATE TABLE IF NOT EXISTS etl_log (
    id            BIGSERIAL PRIMARY KEY,
    executado_em  TIMESTAMPTZ NOT NULL DEFAULT now(),
    componente    TEXT        NOT NULL,          -- 'nodered-usgs', 'knime-merge', ...
    nivel         TEXT        NOT NULL DEFAULT 'INFO',  -- INFO, WARN, ERROR
    mensagem      TEXT,
    n_registos    INTEGER
);
