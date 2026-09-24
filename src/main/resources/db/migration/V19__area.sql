CREATE TABLE areas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('Ativo', 'Inativo')),
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP WITHOUT TIME ZONE
);
