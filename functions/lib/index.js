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
// functions/src/index.ts
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
exports.onTaskWrite = functions.region('europe-west1').firestore
    .document('propertask/tarefas/tarefas/{id}')
    .onWrite(async (change, ctx) => {
    var _a, _b;
    const after = change.after.exists ? change.after.data() : null;
    const before = change.before.exists ? change.before.data() : null;
    if (!after)
        return;
    const newResp = after.responsavelId;
    const oldResp = before === null || before === void 0 ? void 0 : before.responsavelId;
    if (!newResp || newResp === oldResp)
        return;
    const tokensSnap = await admin.firestore()
        .collection('propertask').doc('usuarios').collection('usuarios')
        .doc(newResp).collection('tokens').get();
    const tokens = tokensSnap.docs.map(d => d.id).filter(Boolean);
    if (!tokens.length)
        return;
    const titulo = (_a = after.titulo) !== null && _a !== void 0 ? _a : 'Nova tarefa';
    const prop = (_b = after.propriedadeNome) !== null && _b !== void 0 ? _b : '';
    const route = `/tarefas/${ctx.params.id}`;
    const message = {
        notification: { title: 'Nova tarefa atribuída', body: `${titulo} — ${prop}` },
        data: { route },
        tokens,
        android: { priority: 'high' },
        apns: { headers: { 'apns-priority': '10' } },
    };
    await admin.messaging().sendEachForMulticast(message);
});
