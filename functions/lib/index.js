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
    var _a, _b;
    console.error('DEBUG FORÇADO');
    const after = change.after.exists ? change.after.data() : null;
    const before = change.before.exists ? change.before.data() : null;
    console.log('onTaskWrite fired', {
        empresaId: ctx.params.empresaId,
        tarefaId: ctx.params.tarefaId,
    });
    if (!after) {
        console.log('no after doc, exiting');
        return;
    }
    const newResp = after.responsavelId;
    const oldResp = before === null || before === void 0 ? void 0 : before.responsavelId;
    console.log('responsavelId before/after', { oldResp, newResp });
    if (!newResp || newResp === oldResp) {
        console.log('no new responsavel or unchanged, exiting');
        return;
    }
    const empresaId = ctx.params.empresaId;
    const tarefaId = ctx.params.tarefaId;
    const tokensSnap = await admin
        .firestore()
        .collection('empresas')
        .doc(empresaId)
        .collection('usuarios')
        .doc(newResp)
        .collection('tokens')
        .get();
    const tokens = tokensSnap.docs.map((d) => d.id).filter(Boolean);
    console.log('found tokens', tokens);
    if (!tokens.length) {
        console.log('no tokens for user, exiting');
        return;
    }
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
    console.log('sending multicast', JSON.stringify(message));
    const resp = await admin.messaging().sendEachForMulticast(message);
    console.log('multicast response', JSON.stringify(resp));
});
