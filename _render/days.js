const CHK='<span class="chk"><svg viewBox="0 0 24 24"><path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="#fff" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"/></svg></span>';
const PLAY='<span class="play"><svg viewBox="0 0 20 22"><path d="M2 2l16 9-16 9z" fill="#fff"/></svg></span>';
const N=n=>`<span class="num">${n}</span>`;
const E=e=>`<span class="em">${e}</span>`;

module.exports=[
{date:"2026-11-21",pig:"pig-feliz",
 title:"Orçamento enviado. <em>Cliente aprovou.</em>",
 sub:"Monte, mande o link pelo WhatsApp e o cliente aprova com um toque. Depois, vira renda nas suas finanças.",
 card:`<div class="ch"><div><div class="cs">Orçamento nº 0042</div><div class="ct">Maria Silva</div></div><span class="ok">✓ Aprovado</span></div>
 <div class="rows">
  <div class="r"><span class="d"><span>Instalação de prateleiras<small>2 × R$ 180,00</small></span></span><span class="v">R$ 360,00</span></div>
  <div class="r"><span class="d"><span>Pintura do quarto<small>1 × R$ 450,00</small></span></span><span class="v">R$ 450,00</span></div>
 </div>
 <div class="tot"><span>Total</span><span>R$ 810,00</span></div>
 <div class="btn">Lançar R$ 810,00 como renda</div>`,
 q:"Como você manda orçamento hoje? Caderno, áudio, planilha? 📝",
 caption:`Ainda manda orçamento por foto do caderno ou áudio no WhatsApp? 📝

No Prumo você monta o orçamento com seus serviços, sua logo e seu PIX, e envia o link pelo WhatsApp. O cliente abre, vê tudo certinho e aprova com um toque. O status muda sozinho no app. ✅

Aprovou e recebeu? Um toque e o valor entra como renda nas suas finanças.

Profissional, rápido e sem planilha. Começar é grátis, link na bio. 🐷

Marca aquele amigo autônomo 👇

#orcamento #autonomo #empreendedor #financaspessoais`},

{date:"2026-11-22",pig:"pig-feliz",
 title:"Domingo à noite, <em>respira.</em>",
 sub:"Respirações e meditações guiadas no próprio app. Comece com 3 minutos. É o suficiente.",
 card:`<div class="ct">Meditação</div>
 <div class="rows">
  <div class="r"><span class="d">${PLAY}<span>Respiração 4-7-8<small>Inspira 4, segura 7, solta 8. Ótima antes de dormir.</small></span></span></div>
  <div class="r"><span class="d">${PLAY}<span>Acalmar a ansiedade<small>Para quando a cabeça não para.</small></span></span></div>
  <div class="r"><span class="d">${PLAY}<span>Para ouvir já deitado<small>Termina em silêncio, sem te acordar.</small></span></span></div>
 </div>`,
 q:"Qual dia da semana bate mais ansiedade em você? 😮‍💨",
 caption:`Domingo à noite e a cabeça já está na segunda? 😮‍💨

Antes de dormir, experimenta a respiração 4-7-8: inspira contando 4, segura 7, solta em 8. A saída longa ajuda o corpo a desacelerar.

No Prumo tem respirações guiadas e meditações narradas: para a ansiedade, para uma pausa no trabalho e até uma para ouvir já deitado. Comece com 3 minutos. É o suficiente. 🌙

Começar é grátis, link na bio. 🐷

#meditacao #ansiedade #respiracao #saudemental`},

{date:"2026-11-23",pig:"pig-oculos",
 title:"Fatura do cartão <em>sem digitar</em> nada.",
 sub:"Importe o PDF da fatura e o Prumo encontra as compras, separa por categoria e entende as parcelas.",
 card:`<div class="ch"><div><div class="cs">Importar fatura em PDF</div><div class="ct">18 compras encontradas</div></div></div>
 <div class="rows">
  <div class="r"><span class="d">${E("🍔")}<span>iFood<small><span class="chip">Delivery</span></small></span></span><span class="v">R$ 54,90</span></div>
  <div class="r"><span class="d">${E("⛽")}<span>Auto Posto<small><span class="chip">Combustível</span></small></span></span><span class="v">R$ 180,00</span></div>
  <div class="r"><span class="d">${E("👟")}<span>Loja de tênis · parcela 3/10<small><span class="chip">Roupas</span></small></span></span><span class="v">R$ 89,90</span></div>
 </div>`,
 q:"Você confere a fatura antes de pagar? Sim ou não? 💳",
 caption:`A fatura do cartão chegou e você nem lembra direito o que comprou? 💳

No Prumo você importa a fatura em PDF e ele encontra as compras sozinho: separa por categoria e entende até as parcelas (aquele 3/10 no canto). Também dá para usar OFX, CSV ou colar o texto do app do banco.

Você vê para onde foi o dinheiro do cartão sem digitar compra por compra.

Começar é grátis, link na bio. 🐷

#cartaodecredito #fatura #organizacaofinanceira #financaspessoais`},

{date:"2026-11-24",pig:"pig-oculos",
 title:"Seu holerite, <em>traduzido.</em>",
 sub:"O Prumo lê o bruto, os descontos e o líquido. Cada desconto vira um gasto já pago.",
 card:`<div class="ch"><div class="ct">Holerite de novembro</div></div>
 <div class="rows">
  <div class="r"><span class="d">Salário bruto</span><span class="v">R$ 4.200,00</span></div>
  <div class="r"><span class="d">INSS</span><span class="v neg">− R$ 410,00</span></div>
  <div class="r"><span class="d">Imposto de renda</span><span class="v neg">− R$ 160,00</span></div>
  <div class="r"><span class="d">Vale-transporte</span><span class="v neg">− R$ 126,00</span></div>
 </div>
 <div class="tot"><span>Líquido</span><span>R$ 3.504,00</span></div>`,
 q:"Você já leu seu holerite inteiro alguma vez? 🧾",
 caption:`Você sabe quanto do seu salário vai embora antes de cair na conta? 🧾

INSS, imposto de renda, vale-transporte, plano de saúde... O holerite mostra tudo, mas quase ninguém para para ler.

No Prumo você importa o holerite (em PDF ou colando o texto) e ele lê o bruto, os descontos e o líquido. A renda bruta entra como renda e cada desconto vira um gasto já pago, na categoria que você escolher.

Aí sim dá para enxergar o seu dinheiro de verdade. Começar é grátis, link na bio. 🐷

#holerite #salario #clt #financaspessoais`},

{date:"2026-11-25",pig:"pig-feliz",
 title:"Dívidas: <em>por onde começar?</em>",
 sub:"O diagnóstico compara suas dívidas com a sua renda e monta um plano, na ordem certa.",
 card:`<div class="ch"><div class="ct">Diagnóstico financeiro</div><span class="ok wn">Atenção</span></div>
 <div class="p">As dívidas já pesam no seu mês. Siga o plano abaixo, na ordem.</div>
 <div class="rows">
  <div class="r"><span class="d">${N(1)}Garanta o básico primeiro</span></div>
  <div class="r"><span class="d">${N(2)}Negocie antes de pagar</span></div>
  <div class="r"><span class="d">${N(3)}Pague as em dia pela mais cara</span></div>
 </div>`,
 q:"Qual dívida você quer quitar primeiro? 🎯",
 caption:`Dívida tirando o seu sono? Respira: tem saída. 🫶

O primeiro passo é enxergar o tamanho delas perto da sua renda. A partir daí, a ordem importa: garantir o básico, negociar as atrasadas e atacar a mais cara.

No Prumo, o diagnóstico financeiro compara suas dívidas com a sua renda e monta um plano de ação, passo a passo, na ordem certa.

E atenção: desconfie de quem cobra adiantado para limpar o nome ou liberar crédito. É golpe. ⚠️

Começar é grátis, link na bio. 🐷

#dividas #nomelimpo #educacaofinanceira #financaspessoais`},

{date:"2026-11-26",pig:"pig-oculos",
 title:"Crediário, carnê, <em>cartão da mãe.</em>",
 sub:"Parcelas fora do seu cartão também contam. No Prumo, cada uma entra como “a pagar” no mês certo.",
 card:`<div class="ch"><div><div class="cs">Parcelado sem cartão</div><div class="ct">🧊 Geladeira</div></div><div class="cv">10 × R$ 289,00</div></div>
 <div class="rows">
  <div class="r"><span class="d"><span>Dezembro<small>Parcela 1/10 · crediário da loja</small></span></span><span class="v">R$ 289,00</span></div>
  <div class="r"><span class="d"><span>Janeiro<small>Parcela 2/10</small></span></span><span class="v">R$ 289,00</span></div>
  <div class="r"><span class="d"><span>Fevereiro<small>Parcela 3/10 · até setembro de 2027</small></span></span><span class="v">R$ 289,00</span></div>
 </div>`,
 q:"Já comprou no cartão de alguém? Confessa! 😅",
 caption:`Crediário da loja, carnê, cartão emprestado da mãe... 👀

Essas parcelas não aparecem em fatura nenhuma, e é aí que elas somem da cabeça. Até chegar o boleto.

No Prumo você lança o parcelado sem cartão uma vez: valor total, número de parcelas e data da primeira. Cada parcela entra como “a pagar” no mês certo.

Amanhã é Black Friday: antes de parcelar mais, veja quanto dos próximos meses já está comprometido. Começar é grátis, link na bio. 🐷

#crediario #parcelamento #blackfriday #financaspessoais`},

{date:"2026-11-27",pig:"pig-oculos",
 title:"Black Friday: <em>cabe no bolso?</em>",
 sub:"Conte o que quer comprar. O Prumo olha renda, gastos, parcelas e reserva e responde.",
 card:`<div class="ch"><div><div class="cs">Posso comprar?</div><div class="ct">🛒 Air fryer</div></div><div class="cv">10 × R$ 69,90</div></div>
 <div style="margin-top:18px"><span class="ok wn">Dá, mas com cuidado</span></div>
 <div class="rows">
  <div class="r"><span class="d">${CHK}<span>A parcela cabe no que costuma sobrar por mês.</span></span></div>
  <div class="r"><span class="d">${E("⚠️")}<span>O parcelamento custa R$ 100 a mais que à vista (17%).</span></span></div>
 </div>`,
 q:"O que está na sua lista da Black Friday? 🛒",
 caption:`Black Friday chegou. Antes de clicar em “comprar”, uma pergunta: cabe? 🛒

No “Posso comprar?” do Prumo você conta o que quer comprar e em quantas parcelas. Ele olha sua renda, seus gastos, suas parcelas e sua reserva e responde: cabe, cabe com cuidado ou agora não.

E ainda mostra quanto o parcelamento custa a mais que à vista. Spoiler: “sem juros” nem sempre é sem juros. 😉

Desconto bom é o que não aperta o mês. Começar é grátis, link na bio. 🐷

#blackfriday #compras #consumoconsciente #financaspessoais`}
];
