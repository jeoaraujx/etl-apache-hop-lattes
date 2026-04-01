-- =============================================================================
-- BUSCA TEXTUAL COMPLETA (FTS) NO POSTGRESQL – DATASET REAL
-- =============================================================================

-- =============================================================================
-- SEÇÃO 0 – EXTENSÕES
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =============================================================================
-- SEÇÃO 2 – TSVECTOR
-- =============================================================================

SELECT to_tsvector('english','Synchronized spread of COVID-19 in the cities of Bahia, Brazil');
SELECT to_tsvector('simple','Robótica Educacional com Arduino');

-- =============================================================================
-- SEÇÃO 3 – CONSULTAS
-- =============================================================================

SELECT nomeartigo, anoartigo
FROM producoes
WHERE to_tsvector('simple', nomeartigo) @@ to_tsquery('simple', 'dengue');

SELECT nomeartigo
FROM producoes
WHERE to_tsvector('simple', nomeartigo) @@ to_tsquery('simple', 'covid & bahia');

SELECT nomeartigo
FROM producoes
WHERE to_tsvector('simple', nomeartigo) @@ to_tsquery('simple', 'robotica | arduino');

SELECT nomeartigo
FROM producoes
WHERE to_tsvector('simple', nomeartigo) @@ to_tsquery('simple', 'network & !dengue');

SELECT nomeartigo
FROM producoes
WHERE to_tsvector('simple', nomeartigo) @@ to_tsquery('simple', 'tecnolog:*');

-- =============================================================================
-- SEÇÃO 4 – CONFIG pt_br
-- =============================================================================

DROP TEXT SEARCH CONFIGURATION IF EXISTS pt_br CASCADE;

CREATE TEXT SEARCH CONFIGURATION pt_br (COPY = portuguese);

ALTER TEXT SEARCH CONFIGURATION pt_br
ALTER MAPPING FOR hword, hword_part, word
WITH unaccent, portuguese_stem;

SELECT nomeartigo
FROM producoes
WHERE to_tsvector('pt_br', nomeartigo)
@@ to_tsquery('pt_br', 'saude');

-- =============================================================================
-- SEÇÃO 5 – RANKING
-- =============================================================================

SELECT 
    nomeartigo,
    ts_rank(
        setweight(to_tsvector('pt_br', nomeartigo), 'A'),
        to_tsquery('pt_br', 'dengue & bahia')
    ) AS relevancia
FROM producoes
WHERE to_tsvector('pt_br', nomeartigo)
@@ to_tsquery('pt_br', 'dengue | bahia')
ORDER BY relevancia DESC;

-- =============================================================================
-- SEÇÃO 6 – MATERIALIZED VIEW
-- =============================================================================

CREATE MATERIALIZED VIEW mv_busca_producoes AS
SELECT 
    p.producoes_id,
    p.nomeartigo,
    p.anoartigo,
    r.nome,
    setweight(to_tsvector('pt_br', p.nomeartigo), 'A') ||
    setweight(to_tsvector('pt_br', COALESCE(r.nome,'')), 'C')
    AS doc
FROM producoes p
LEFT JOIN pesquisadores r
ON r.pesquisadores_id = p.pesquisadores_id;

CREATE INDEX idx_fts
ON mv_busca_producoes
USING gin(doc);

SELECT nomeartigo, nome
FROM mv_busca_producoes
WHERE doc @@ to_tsquery('pt_br', 'covid | omicron');

-- =============================================================================
-- SEÇÃO 7 – TRIGRAM
-- =============================================================================

CREATE MATERIALIZED VIEW mv_dict AS
SELECT word
FROM ts_stat(
'SELECT to_tsvector(''simple'', nomeartigo) FROM producoes'
);

CREATE INDEX idx_trgm
ON mv_dict
USING gin(word gin_trgm_ops);

SELECT word, similarity(word, 'covd') AS score
FROM mv_dict
WHERE similarity(word, 'covd') > 0.3
ORDER BY word <-> 'covd'
LIMIT 3;

SELECT word, similarity(word, 'dengu') AS score
FROM mv_dict
WHERE similarity(word, 'dengu') > 0.3
ORDER BY word <-> 'dengu'
LIMIT 3;