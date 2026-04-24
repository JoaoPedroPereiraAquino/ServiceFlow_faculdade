// Mock data (in-memory). Mirrors what MaterialApp route state would store.

const INITIAL_CLIENTS = [
  { id: 'c1', nome: 'Indústrias Bravo Ltda.',  doc: '12.345.678/0001-90', email: 'contato@bravo.com.br',    telefone: '(11) 98452-1100' },
  { id: 'c2', nome: 'Café da Praça ME',        doc: '98.765.432/0001-11', email: 'admin@cafedapraca.com',   telefone: '(11) 99111-2233' },
  { id: 'c3', nome: 'Mariana Ribeiro',         doc: '345.890.123-45',     email: 'mariana.r@gmail.com',     telefone: '(21) 97888-0201' },
  { id: 'c4', nome: 'Oficina Motor Sul',       doc: '28.112.009/0001-56', email: 'oficina@motorsul.com.br', telefone: '(51) 98122-7710' },
];

const INITIAL_OS = [
  { id: 'OS-00412', clienteId: 'c1', descricao: 'Manutenção preventiva do sistema de refrigeração industrial — trocar filtros e calibrar termostato.', valor: 2480.00, status: 'executada', criadoEm: '15 abr', tecnico: 'Ricardo S.' },
  { id: 'OS-00411', clienteId: 'c2', descricao: 'Reparo na máquina de espresso principal; pressão intermitente.', valor: 860.00,  status: 'execucao',  criadoEm: '15 abr', tecnico: 'Paula M.'   },
  { id: 'OS-00410', clienteId: 'c3', descricao: 'Instalação de roteador e extensor Wi-Fi no apartamento.',       valor: 320.00,  status: 'aberto',    criadoEm: '14 abr', tecnico: '—'          },
  { id: 'OS-00409', clienteId: 'c4', descricao: 'Troca de correia dentada e revisão da suspensão dianteira.',    valor: 1920.00, status: 'execucao',  criadoEm: '14 abr', tecnico: 'Ricardo S.' },
  { id: 'OS-00408', clienteId: 'c1', descricao: 'Ajuste de pressostato na caldeira — chamado de urgência.',      valor: 740.00,  status: 'executada', criadoEm: '13 abr', tecnico: 'Paula M.'   },
  { id: 'OS-00407', clienteId: 'c2', descricao: 'Orçamento de reforma da copa e troca do exaustor.',             valor: 4100.00, status: 'aberto',    criadoEm: '12 abr', tecnico: '—'          },
  { id: 'OS-00406', clienteId: 'c3', descricao: 'Configuração de mesh para cobertura completa do sobrado.',      valor: 480.00,  status: 'executada', criadoEm: '12 abr', tecnico: 'Ricardo S.' },
  { id: 'OS-00405', clienteId: 'c4', descricao: 'Balanceamento de rodas e geometria 3D.',                        valor: 380.00,  status: 'execucao',  criadoEm: '11 abr', tecnico: 'Paula M.'   },
];

function summarizeOS(list) {
  const sum = (arr) => arr.reduce((a, o) => a + o.valor, 0);
  return {
    total:      { count: list.length,                           value: sum(list) },
    aberto:     { count: list.filter(o => o.status==='aberto').length,    value: sum(list.filter(o => o.status==='aberto')) },
    execucao:   { count: list.filter(o => o.status==='execucao').length,  value: sum(list.filter(o => o.status==='execucao')) },
    executada:  { count: list.filter(o => o.status==='executada').length, value: sum(list.filter(o => o.status==='executada')) },
  };
}

Object.assign(window, { INITIAL_CLIENTS, INITIAL_OS, summarizeOS });
