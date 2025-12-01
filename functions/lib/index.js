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
exports.alertaTarefasAtrasadas = exports.lembretesTarefasDiarias = exports.onTaskWrite = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
// ============ NOTIFICAÇÕES EM TEMPO REAL (onWrite) ============
exports.onTaskWrite = functions.region('europe-west1').firestore
    .document('empresas/{empresaId}/tarefas/{tarefaId}')
    .onWrite(async (change, ctx) => {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    const after = change.after.exists ? change.after.data() : null;
    const before = change.before.exists ? change.before.data() : null;
    if (!after)
        return;
    const empresaId = ctx.params.empresaId;
    const tarefaId = ctx.params.tarefaId;
    // ============ CENÁRIO 1: Nova atribuição ============
    const newResp = after.responsavelId;
    const oldResp = before === null || before === void 0 ? void 0 : before.responsavelId;
    if (newResp && newResp !== oldResp) {
        console.log('nova atribuição detectada');
        await notificarUsuario(empresaId, newResp, 'Nova tarefa atribuída', `${(_a = after.titulo) !== null && _a !== void 0 ? _a : 'Tarefa'} — ${(_b = after.propriedadeNome) !== null && _b !== void 0 ? _b : ''}`, tarefaId);
    }
    // ============ CENÁRIO 2: Tarefa iniciada ============
    const newStatus = after.status;
    const oldStatus = before === null || before === void 0 ? void 0 : before.status;
    if (newStatus === 'em_andamento' && oldStatus === 'pendente') {
        console.log('tarefa iniciada - notificar gestores');
        await notificarGestores(empresaId, '🟡 Tarefa Iniciada', `${(_c = after.responsavelNome) !== null && _c !== void 0 ? _c : 'Alguém'} iniciou ${formatTipo(after.tipo)} em ${(_d = after.propriedadeNome) !== null && _d !== void 0 ? _d : ''}`, tarefaId);
    }
    // ============ CENÁRIO 3: Tarefa concluída ============
    if (newStatus === 'concluida' && oldStatus !== 'concluida') {
        console.log('tarefa concluída - notificar gestores');
        await notificarGestores(empresaId, '✅ Tarefa Concluída', `${(_e = after.responsavelNome) !== null && _e !== void 0 ? _e : 'Alguém'} concluiu ${formatTipo(after.tipo)} em ${(_f = after.propriedadeNome) !== null && _f !== void 0 ? _f : ''}`, tarefaId);
    }
    // ============ CENÁRIO 4: Tarefa reaberta ============
    if (newStatus === 'reaberta' && oldStatus !== 'reaberta') {
        console.log('tarefa reaberta');
        // Notifica o responsável
        if (after.responsavelId) {
            await notificarUsuario(empresaId, after.responsavelId, '⚠️ Tarefa Reaberta', `A tarefa de ${formatTipo(after.tipo)} em ${(_g = after.propriedadeNome) !== null && _g !== void 0 ? _g : ''} foi reaberta`, tarefaId);
        }
        // Notifica gestores
        await notificarGestores(empresaId, '⚠️ Tarefa Reaberta', `${(_h = after.responsavelNome) !== null && _h !== void 0 ? _h : 'Alguém'} teve a tarefa de ${formatTipo(after.tipo)} reaberta`, tarefaId);
    }
});
// ============ NOTIFICAÇÃO AGENDADA: Lembretes diários ============
// Roda todos os dias às 12h (hora de Portugal)
exports.lembretesTarefasDiarias = functions
    .region('europe-west1')
    .pubsub.schedule('0 12 * * *')
    .timeZone('Europe/Lisbon')
    .onRun(async () => {
    var _a;
    console.log('Verificando tarefas pendentes do dia');
    const db = admin.firestore();
    const hoje = new Date();
    hoje.setHours(0, 0, 0, 0);
    const amanha = new Date(hoje);
    amanha.setDate(amanha.getDate() + 1);
    // Busca todas as empresas
    const empresasSnap = await db.collection('empresas').get();
    for (const empresaDoc of empresasSnap.docs) {
        const empresaId = empresaDoc.id;
        // Busca tarefas pendentes do dia
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
                await notificarUsuario(empresaId, tarefa.responsavelId, '⏰ Lembrete: Tarefa para hoje', `${formatTipo(tarefa.tipo)} em ${(_a = tarefa.propriedadeNome) !== null && _a !== void 0 ? _a : ''}`, tarefaDoc.id);
            }
        }
    }
    return null;
});
// ============ NOTIFICAÇÃO AGENDADA: Tarefas atrasadas ============
// Roda todos os dias às 16h (hora de Portugal)
exports.alertaTarefasAtrasadas = functions
    .region('europe-west1')
    .pubsub.schedule('0 16 * * *')
    .timeZone('Europe/Lisbon')
    .onRun(async () => {
    var _a, _b;
    console.log('Verificando tarefas atrasadas');
    const db = admin.firestore();
    const hoje = new Date();
    hoje.setHours(0, 0, 0, 0);
    const empresasSnap = await db.collection('empresas').get();
    for (const empresaDoc of empresasSnap.docs) {
        const empresaId = empresaDoc.id;
        // Busca tarefas não concluídas de dias anteriores
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
            // Notifica o responsável
            if (tarefa.responsavelId) {
                await notificarUsuario(empresaId, tarefa.responsavelId, '🔴 Tarefa Atrasada', `${formatTipo(tarefa.tipo)} em ${(_a = tarefa.propriedadeNome) !== null && _a !== void 0 ? _a : ''} está atrasada`, tarefaDoc.id);
            }
            // Notifica gestores
            await notificarGestores(empresaId, '🔴 Tarefa Atrasada', `${(_b = tarefa.responsavelNome) !== null && _b !== void 0 ? _b : 'Alguém'} tem tarefa atrasada: ${formatTipo(tarefa.tipo)}`, tarefaDoc.id);
        }
    }
    return null;
});
// ============ FUNÇÕES AUXILIARES ============
async function notificarUsuario(empresaId, userId, title, body, tarefaId) {
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
        console.log(`Notificação enviada para ${userId}: ${resp.successCount} sucesso`);
        // Remove tokens inválidos
        await limparTokensInvalidos(resp, tokens, empresaId, userId);
    }
    catch (error) {
        console.error(`Erro enviando notificação para ${userId}:`, error);
    }
}
async function notificarGestores(empresaId, title, body, tarefaId) {
    const gestoresSnap = await admin
        .firestore()
        .collection('empresas')
        .doc(empresaId)
        .collection('usuarios')
        .where('cargo', 'in', ['coordenador', 'supervisor', 'ceo', 'dev'])
        .get();
    console.log(`Encontrados ${gestoresSnap.size} gestores para notificar`);
    const notificacoes = gestoresSnap.docs.map((doc) => notificarUsuario(empresaId, doc.id, title, body, tarefaId));
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
