-- Auditoria (Hibernate Envers) das areas comuns e das reservas.
-- DDL derivada do schema gerado pelo Hibernate e ajustada para TEXT, conforme decisao de tipos do projeto.
-- Escopo inicial: areas e solicitacoes_area. As colunas nao auditadas devem ser explicitadas com @NotAudited.

CREATE SEQUENCE revinfo_seq START WITH 1 INCREMENT BY 50;

-- Revisoes: instante (epoch, mesma origem de tempo dos negocios) + snapshot do ator.
CREATE TABLE revinfo (
    id INTEGER NOT NULL,
    "timestamp" BIGINT NOT NULL,
    usuario_id UUID,
    usuario_role TEXT,
    usuario_email TEXT,
    CONSTRAINT revinfo_pkey PRIMARY KEY (id)
);

CREATE TABLE areas_aud (
    rev INTEGER NOT NULL,
    revtype SMALLINT,
    created_at TIMESTAMP WITHOUT TIME ZONE,
    deleted_at TIMESTAMP WITHOUT TIME ZONE,
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    id UUID NOT NULL,
    nome TEXT,
    status TEXT,
    CONSTRAINT areas_aud_pkey PRIMARY KEY (rev, id),
    CONSTRAINT areas_aud_status_check CHECK (status IN ('Inativo', 'Ativo')),
    CONSTRAINT fk_areas_aud_rev FOREIGN KEY (rev) REFERENCES revinfo (id)
);

CREATE TABLE solicitacoes_area_aud (
    rev INTEGER NOT NULL,
    revtype SMALLINT,
    created_at TIMESTAMP WITHOUT TIME ZONE,
    deleted_at TIMESTAMP WITHOUT TIME ZONE,
    fim TIMESTAMP WITHOUT TIME ZONE,
    inicio TIMESTAMP WITHOUT TIME ZONE,
    updated_at TIMESTAMP WITHOUT TIME ZONE,
    area_id UUID,
    id UUID NOT NULL,
    morador_id UUID,
    unidade_id UUID,
    status TEXT,
    motivo_negacao TEXT,
    CONSTRAINT solicitacoes_area_aud_pkey PRIMARY KEY (rev, id),
    CONSTRAINT solicitacoes_area_aud_status_check CHECK (status IN ('Solicitado', 'Aprovado', 'Negado', 'Cancelado')),
    CONSTRAINT fk_solicitacoes_area_aud_rev FOREIGN KEY (rev) REFERENCES revinfo (id)
);

-- Apoio ao historico por entidade (a PK cobre a busca por revisao).
CREATE INDEX idx_areas_aud_id ON areas_aud (id, rev);
CREATE INDEX idx_solicitacoes_area_aud_id ON solicitacoes_area_aud (id, rev);
