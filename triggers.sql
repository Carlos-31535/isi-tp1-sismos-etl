-- triggers.sql : ajustes ao esquema + enriquecimento automatico da tabela sismos
-- Executar depois do init.sql (e e idempotente: pode correr varias vezes).

-- 1) Ajustes ao esquema
ALTER TABLE sismos ADD COLUMN IF NOT EXISTS regiao TEXT;
-- horas guardadas em UTC, sem fuso (o KNIME envia a hora tal como esta)
ALTER TABLE sismos ALTER COLUMN data_hora TYPE timestamp;

-- 2) Funcao que preenche geom, dist_portugal_km e nivel_alerta
CREATE OR REPLACE FUNCTION fn_sismos_enriquecer() RETURNS trigger AS $$
BEGIN
    NEW.geom := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);

    -- distancia geodesica (km) ao territorio portugues mais proximo:
    -- continente (Faro, Lisboa, Porto), Acores (9 ilhas) e Madeira (Funchal, Porto Santo)
    NEW.dist_portugal_km := ST_Distance(
        NEW.geom::geography,
        ST_GeogFromText('SRID=4326;MULTIPOINT(-7.93 37.02, -9.14 38.72, -8.61 41.15, -25.67 37.74, -25.15 36.95, -27.22 38.66, -28.02 38.65, -28.63 38.53, -28.35 38.47, -28.01 39.05, -31.13 39.45, -31.20 39.68, -16.91 32.65, -16.34 33.07)')
    ) / 1000;

    -- nivel de alerta (magnitude em falta conta como 0)
    NEW.nivel_alerta := CASE
        WHEN (COALESCE(NEW.magnitude, 0) >= 4 AND NEW.dist_portugal_km <= 300)
          OR (COALESCE(NEW.magnitude, 0) >= 6 AND NEW.dist_portugal_km <= 2000) THEN 'alto'
        WHEN (COALESCE(NEW.magnitude, 0) >= 3 AND NEW.dist_portugal_km <= 300)
          OR (COALESCE(NEW.magnitude, 0) >= 5 AND NEW.dist_portugal_km <= 1500) THEN 'medio'
        WHEN NEW.dist_portugal_km <= 300 THEN 'baixo'
        ELSE 'sem alerta'
    END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3) Trigger: corre em cada INSERT e quando mudam coordenadas ou magnitude
DROP TRIGGER IF EXISTS trg_sismos_enriquecer ON sismos;
CREATE TRIGGER trg_sismos_enriquecer
    BEFORE INSERT OR UPDATE OF latitude, longitude, magnitude ON sismos
    FOR EACH ROW EXECUTE FUNCTION fn_sismos_enriquecer();
