/*
  Configuração do Prumo.
  Cole aqui os dados do seu projeto no Supabase (Project Settings > API).
  A "anon public key" pode ficar pública: quem protege os dados são as
  regras de segurança criadas pelo arquivo supabase/schema.sql.
  Se deixar vazio, o app funciona só no aparelho, sem contas.
*/
window.PRUMO_CONFIG = {
  supabaseUrl: "https://ngneowwmurutsueuyzey.supabase.co",   // exemplo: "https://abcdefghij.supabase.co"
  supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nbmVvd3dtdXJ1dHN1ZXV5emV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI5Nzk5ODgsImV4cCI6MjEwODU1NTk4OH0.JXrWnZodIzbZujr2eH24Y64Pac3nBm16ubJeiu85DCg",   // exemplo: "eyJhbGciOiJIUzI1NiIsInR5cCI6..."

  // Doações voluntárias por Pix (aparecem em Perfil > Apoie o Prumo)
  pix: {
    key: "mateuslealpsi@gmail.com",
    name: "Mateus Leal",   // nome mostrado no código Pix (até 25 letras)
    city: "BRASIL"         // troque pela sua cidade, sem acentos
  }
};
