"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.verificarTarefas = exports.onTaskWrite = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
// ============ NOTIFICAÇÕES EM TEMPO REAL (onWrite) ============
exports.onTaskWrite = functions.region('europe-west1').firestore
    .document('empresas/{empresaId}/tarefas/{tarefaId}')
    .onWrite(async (change, ctx) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j;
    const after = change.after.exists ? change.after.data() : null;
    const before = change.before.exists ? change.before.data() : null;
    if (!after)
        return;
    const empresaId = ctx.params.empresaId;
    const tarefaId = ctx.params.tarefaId;
    const executorId = ((_a = ctx.auth) === null || _a === void 0 ? void 0 : _a.uid) || null;
    // ============ CENÁRIO 1: Nova atribuição ============
    const newResp = after.responsavelId;
    const oldResp = before === null || before === void 0 ? void 0 : before.responsavelId;
    if (newResp && newResp !== oldResp) {
        console.log('Nova atribuição detectada');
        await notificarUsuario(empresaId, newResp, 'Nova tarefa atribuída', `${(_b = after.titulo) !== null && _b !== void 0 ? _b : 'Tarefa'} — ${(_c = after.propriedadeNome) !== null && _c !== void 0 ? _c : ''}`, tarefaId, executorId);
    }
    // ============ CENÁRIO 2: Tarefa iniciada ============
    const newStatus = after.status;
    const oldStatus = before === null || before === void 0 ? void 0 : before.status;
    if (newStatus === 'em_andamento' && oldStatus === 'pendente') {
        console.log('Tarefa iniciada - notificar gestores');
        await notificarGestores(empresaId, '🟡 Tarefa Iniciada', `${(_d = after.responsavelNome) !== null && _d !== void 0 ? _d : 'Alguém'} iniciou ${formatTipo(after.tipo)} em ${(_e = after.propriedadeNome) !== null && _e !== void 0 ? _e : ''}`, tarefaId, after.responsavelId);
    }
    // ============ CENÁRIO 3: Tarefa concluída ============
    if (newStatus === 'concluida' && oldStatus !== 'concluida') {
        console.log('Tarefa concluída - notificar gestores');
        await notificarGestores(empresaId, '✅ Tarefa Concluída', `${(_f = after.responsavelNome) !== null && _f !== void 0 ? _f : 'Alguém'} concluiu ${formatTipo(after.tipo)} em ${(_g = after.propriedadeNome) !== null && _g !== void 0 ? _g : ''}`, tarefaId, after.responsavelId);
    }
    // ============ CENÁRIO 4: Tarefa reaberta ============
    if (newStatus === 'reaberta' && oldStatus !== 'reaberta') {
        console.log('Tarefa reaberta');
        // Pega quem reabriu do documento (mais confiável que ctx.auth)
        const quemReabriu = after.reabertaPor || null;
        // Notifica o responsável (se não for ele que reabriu)
        if (after.responsavelId && after.responsavelId !== quemReabriu) {
            await notificarUsuario(empresaId, after.responsavelId, '⚠️ Tarefa Reaberta', `A tarefa de ${formatTipo(after.tipo)} em ${(_h = after.propriedadeNome) !== null && _h !== void 0 ? _h : ''} foi reaberta`, tarefaId, quemReabriu // ← USA O CAMPO DO DOCUMENTO
            );
        }
        // Notifica gestores (exceto quem reabriu)
        await notificarGestores(empresaId, '⚠️ Tarefa Reaberta', `${(_j = after.responsavelNome) !== null && _j !== void 0 ? _j : 'Alguém'} teve a tarefa de ${formatTipo(after.tipo)} reaberta`, tarefaId, quemReabriu // ← USA O CAMPO DO DOCUMENTO
        );
    }
});
// ============ NOTIFICAÇÃO AGENDADA: Lembretes e alertas ============
exports.verificarTarefas = functions
    .region('europe-west1')
    .pubsub.schedule('0 */2 * * *')
    .timeZone('UTC')
    .onRun(async () => {
    console.log('Verificando tarefas em todas as empresas');
    const db = admin.firestore();
    const agora = new Date();
    const empresasSnap = await db.collection('empresas').get();
    for (const empresaDoc of empresasSnap.docs) {
        const empresaId = empresaDoc.id;
        const empresaData = empresaDoc.data();
        const empresaTimezone = empresaData.timezone || 'Europe/Lisbon';
        const horaLocalEmpresa = calcularHoraLocal(agora, empresaTimezone);
        console.log(`Empresa ${empresaId}: ${horaLocalEmpresa}h (${empresaTimezone})`);
        // Lembretes matinais (8h-10h)
        if (horaLocalEmpresa >= 8 && horaLocalEmpresa < 10) {
            await enviarLembretesDiarios(db, empresaId);
        }
        // Alertas de tarefas atrasadas (15h-17h)
        if (horaLocalEmpresa >= 15 && horaLocalEmpresa < 17) {
            await enviarAlertasAtrasadas(db, empresaId);
        }
    }
    return null;
});
// ============ FUNÇÕES AUXILIARES ============
async function enviarLembretesDiarios(db, empresaId) {
    var _a, _b;
    const hoje = new Date();
    hoje.setHours(0, 0, 0, 0);
    const amanha = new Date(hoje);
    amanha.setDate(amanha.getDate() + 1);
    // Verifica se já enviou hoje
    const configRef = db.collection('empresas').doc(empresaId).collection('config').doc('notificacoes');
    const configSnap = await configRef.get();
    const hojeStr = hoje.toISOString().split('T')[0];
    if (configSnap.exists && ((_a = configSnap.data()) === null || _a === void 0 ? void 0 : _a.ultimoLembrete) === hojeStr) {
        console.log(`Lembretes já enviados hoje para ${empresaId}`);
        return;
    }
    const tarefasSnap = await db
        .collection('empresas')
        .doc(empresaId)
        .collection('tarefas')
        .where('status', '==', 'pendente')
        .where('data', '>=', admin.firestore.Timestamp.fromDate(hoje))
        .where('data', '<', admin.firestore.Timestamp.fromDate(amanha))
        .get();
    console.log(`Empresa ${empresaId}: ${tarefasSnap.size} tarefas pendentes hoje`);
    for (const tarefaDoc of tarefasSnap.docs) {
        const tarefa = tarefaDoc.data();
        if (tarefa.responsavelId) {
            await notificarUsuario(empresaId, tarefa.responsavelId, '⏰ Lembrete: Tarefa para hoje', `${formatTipo(tarefa.tipo)} em ${(_b = tarefa.propriedadeNome) !== null && _b !== void 0 ? _b : ''}`, tarefaDoc.id, null);
        }
    }
    await configRef.set({ ultimoLembrete: hojeStr }, { merge: true });
}
async function enviarAlertasAtrasadas(db, empresaId) {
    var _a, _b, _c;
    const hoje = new Date();
    hoje.setHours(0, 0, 0, 0);
    // Verifica se já enviou hoje
    const configRef = db.collection('empresas').doc(empresaId).collection('config').doc('notificacoes');
    const configSnap = await configRef.get();
    const hojeStr = hoje.toISOString().split('T')[0];
    if (configSnap.exists && ((_a = configSnap.data()) === null || _a === void 0 ? void 0 : _a.ultimoAlerta) === hojeStr) {
        console.log(`Alertas já enviados hoje para ${empresaId}`);
        return;
    }
    const tarefasSnap = await db
        .collection('empresas')
        .doc(empresaId)
        .collection('tarefas')
        .where('status', 'in', ['pendente', 'em_andamento', 'reaberta'])
        .where('data', '<', admin.firestore.Timestamp.fromDate(hoje))
        .get();
    console.log(`Empresa ${empresaId}: ${tarefasSnap.size} tarefas atrasadas`);
    for (const tarefaDoc of tarefasSnap.docs) {
        const tarefa = tarefaDoc.data();
        if (tarefa.responsavelId) {
            await notificarUsuario(empresaId, tarefa.responsavelId, '🔴 Tarefa Atrasada', `${formatTipo(tarefa.tipo)} em ${(_b = tarefa.propriedadeNome) !== null && _b !== void 0 ? _b : ''} está atrasada`, tarefaDoc.id, null);
        }
        await notificarGestores(empresaId, '🔴 Tarefa Atrasada', `${(_c = tarefa.responsavelNome) !== null && _c !== void 0 ? _c : 'Alguém'} tem tarefa atrasada: ${formatTipo(tarefa.tipo)}`, tarefaDoc.id, tarefa.responsavelId);
    }
    await configRef.set({ ultimoAlerta: hojeStr }, { merge: true });
}
async function notificarUsuario(empresaId, userId, title, body, tarefaId, excluirUsuarioId) {
    if (userId === excluirUsuarioId) {
        console.log(`Usuário ${userId} executou a ação, não será notificado`);
        return;
    }
    const tokensSnap = await admin
        .firestore()
        .collection('empresas')
        .doc(empresaId)
        .collection('usuarios')
        .doc(userId)
        .collection('tokens')
        .get();
    const tokens = tokensSnap.docs.map((d) => d.id).filter(Boolean);
    if (tokens.length === 0) {
        console.log(`Usuário ${userId} sem tokens`);
        return;
    }
    const message = {
        notification: { title, body },
        data: { route: `/tarefas/${tarefaId}` },
        tokens,
        android: {
            priority: 'high',
            notification: {
                sound: 'default',
                channelId: 'tarefas_updates'
            }
        },
        apns: {
            headers: { 'apns-priority': '10' },
            payload: { aps: { sound: 'default' } }
        },
    };
    try {
        const resp = await admin.messaging().sendEachForMulticast(message);
        console.log(`Notificação para ${userId}: ${resp.successCount}/${tokens.length} enviadas`);
        await limparTokensInvalidos(resp, tokens, empresaId, userId);
    }
    catch (error) {
        console.error(`Erro notificando ${userId}:`, error);
    }
}
async function notificarGestores(empresaId, title, body, tarefaId, excluirUsuarioId) {
    // ← CORREÇÃO: MAIÚSCULAS para combinar com o Flutter
    const gestoresSnap = await admin
        .firestore()
        .collection('empresas')
        .doc(empresaId)
        .collection('usuarios')
        .where('cargo', 'in', ['COORDENADOR', 'SUPERVISOR', 'CEO', 'DEV'])
        .get();
    console.log(`Encontrados ${gestoresSnap.size} gestores para notificar`);
    const notificacoes = gestoresSnap.docs
        .filter((doc) => doc.id !== excluirUsuarioId)
        .map((doc) => notificarUsuario(empresaId, doc.id, title, body, tarefaId, excluirUsuarioId));
    await Promise.all(notificacoes);
}
async function limparTokensInvalidos(resp, tokens, empresaId, userId) {
    const tokensToRemove = [];
    resp.responses.forEach((result, index) => {
        const error = result.error;
        if (error) {
            if (error.code === 'messaging/invalid-registration-token' ||
                error.code === 'messaging/registration-token-not-registered') {
                tokensToRemove.push(admin.firestore()
                    .collection('empresas')
                    .doc(empresaId)
                    .collection('usuarios')
                    .doc(userId)
                    .collection('tokens')
                    .doc(tokens[index])
                    .delete());
            }
        }
    });
    if (tokensToRemove.length > 0) {
        await Promise.all(tokensToRemove);
        console.log(`Removidos ${tokensToRemove.length} tokens inválidos`);
    }
}
function formatTipo(tipo) {
    const tipos = {
        'limpeza': 'limpeza',
        'entrega': 'entrega',
        'recolha': 'recolha',
        'manutencao': 'manutenção'
    };
    return tipos[tipo] || tipo;
}
function calcularHoraLocal(data, timezone) {
    const offsets = {
        'Europe/Lisbon': 0,
        'Europe/London': 0,
        'America/Sao_Paulo': -3,
        'America/Fortaleza': -3,
        'America/Manaus': -4,
        'America/Rio_Branco': -5,
        'UTC': 0
    };
    const offset = offsets[timezone] || 0;
    return (data.getUTCHours() + offset + 24) % 24;
}
