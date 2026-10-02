-- Indice de apoio a listagem das reservas do morador (solicitacoes_area por morador_id).
-- A busca de conflito por area ja e amparada por solicitacoes_area_por_data (area_id, inicio) e
-- pelo indice GiST da constraint excl_solicitacoes_area_overlap (V20).
CREATE INDEX solicitacoes_area_por_morador ON solicitacoes_area (morador_id, inicio);
