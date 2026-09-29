CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE solicitacoes_area (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    area_id UUID NOT NULL REFERENCES areas(id),
    morador_id UUID NOT NULL REFERENCES moradores(id),
    unidade_id UUID NOT NULL REFERENCES unidades(id),
    inicio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    fim TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('Solicitado', 'Aprovado', 'Negado', 'Cancelado')),
    motivo_negacao TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP WITHOUT TIME ZONE,

    CONSTRAINT chk_solicitacoes_area_periodo CHECK (inicio < fim)
);

CREATE INDEX solicitacoes_area_por_data ON solicitacoes_area (area_id, inicio);

-- Impede duas reservas Aprovadas sobrepostas na mesma area.
-- Canceladas/negadas e soft-deleted nao bloqueiam o horario.
ALTER TABLE solicitacoes_area
    ADD CONSTRAINT excl_solicitacoes_area_overlap
    EXCLUDE USING gist (area_id WITH =, tsrange(inicio, fim) WITH &&)
    WHERE (status = 'Aprovado' AND deleted_at IS NULL);
