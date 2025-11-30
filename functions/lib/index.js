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
exports.onTaskWrite = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
exports.onTaskWrite = functions.region('europe-west1').firestore
    .document('empresas/{empresaId}/tarefas/{tarefaId}')
    .onWrite(async (change, ctx) => {
    var _a, _b, _c, _d;
    console.log('onTaskWrite fired', {
        empresaId: ctx.params.empresaId,
        tarefaId: ctx.params.tarefaId,
    });
    const after = change.after.exists ? change.after.data() : null;
    const before = change.before.exists ? change.before.data() : null;
    if (!after) {
        console.log('no after doc, exiting');
        return;
    }
    const empresaId = ctx.params.empresaId;
    const tarefaId = ctx.params.tarefaId;
    // ============ CENÁRIO 1: Nova atribuição de responsável ============
    const newResp = after.responsavelId;
    const oldResp = before === null || before === void 0 ? void 0 : before.responsavelId;
    console.log('responsavelId before/after', { oldResp, newResp });
    if (newResp && newResp !== oldResp) {
        console.log('nova atribuição detectada');
        const tokensSnap = await admin
            .firestore()
            .collection('empresas')
            .doc(empresaId)
            .collection('usuarios')
            .doc(newResp)
            .collection('tokens')
            .get();
        const tokens = tokensSnap.docs.map((d) => d.id).filter(Boolean);
        console.log('found tokens for assignment', tokens);
        if (tokens.length > 0) {
            const titulo = (_a = after.titulo) !== null && _a !== void 0 ? _a : 'Nova tarefa';
            const prop = (_b = after.propriedadeNome) !== null && _b !== void 0 ? _b : '';
            const route = `/tarefas/${tarefaId}`;
            const message = {
                notification: {
                    title: 'Nova tarefa atribuída',
                    body: `${titulo} — ${prop}`,
                },
                data: { route },
                tokens,
                android: { priority: 'high' },
                apns: { headers: { 'apns-priority': '10' } },
            };
            console.log('sending multicast for assignment', JSON.stringify(message));
            try {
                const resp = await admin.messaging().sendEachForMulticast(message);
                console.log('multicast response for assignment', JSON.stringify(resp));
            }
            catch (error) {
                console.error('error sending assignment notification', error);
            }
        }
    }
    // ============ CENÁRIO 2: Tarefa reaberta ============
    const newStatus = after.status;
    const oldStatus = before === null || before === void 0 ? void 0 : before.status;
    console.log('status before/after', { oldStatus, newStatus });
    if (newStatus === 'reaberta' && oldStatus !== 'reaberta') {
        console.log('reabertura detectada');
        const responsavelId = after.responsavelId;
        if (!responsavelId) {
            console.log('tarefa reaberta sem responsável, exiting');
            return;
        }
        const tokensSnap = await admin
            .firestore()
            .collection('empresas')
            .doc(empresaId)
            .collection('usuarios')
            .doc(responsavelId)
            .collection('tokens')
            .get();
        const tokens = tokensSnap.docs.map((d) => d.id).filter(Boolean);
        console.log('found tokens for reopening', tokens);
        if (tokens.length > 0) {
            const tipo = formatTipo((_c = after.tipo) !== null && _c !== void 0 ? _c : 'tarefa');
            const prop = (_d = after.propriedadeNome) !== null && _d !== void 0 ? _d : 'Propriedade';
            const route = `/tarefas/${tarefaId}`;
            const message = {
                notification: {
                    title: '⚠️ Tarefa Reaberta',
                    body: `A tarefa de ${tipo} em ${prop} foi reaberta`,
                },
                data: {
                    route,
                    tipo: 'tarefa_reaberta',
                    status: 'reaberta'
                },
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
                    payload: {
                        aps: {
                            sound: 'default'
                        }
                    }
                },
            };
            console.log('sending multicast for reopening', JSON.stringify(message));
            try {
                const resp = await admin.messaging().sendEachForMulticast(message);
                console.log('multicast response for reopening', JSON.stringify(resp));
                // Remove tokens inválidos automaticamente
                const tokensToRemove = [];
                resp.responses.forEach((result, index) => {
                    const error = result.error;
                    if (error) {
                        console.error('Failure sending to', tokens[index], error);
                        if (error.code === 'messaging/invalid-registration-token' ||
                            error.code === 'messaging/registration-token-not-registered') {
                            tokensToRemove.push(admin.firestore()
                                .collection('empresas')
                                .doc(empresaId)
                                .collection('usuarios')
                                .doc(responsavelId)
                                .collection('tokens')
                                .doc(tokens[index])
                                .delete());
                        }
                    }
                });
                if (tokensToRemove.length > 0) {
                    await Promise.all(tokensToRemove);
                    console.log(`Removed ${tokensToRemove.length} invalid tokens`);
                }
            }
            catch (error) {
                console.error('error sending reopening notification', error);
            }
        }
    }
});
// Helper function para formatar tipo de tarefa
function formatTipo(tipo) {
    const tipos = {
        'limpeza': 'limpeza',
        'entrega': 'entrega',
        'recolha': 'recolha',
        'manutencao': 'manutenção'
    };
    return tipos[tipo] || tipo;
}
