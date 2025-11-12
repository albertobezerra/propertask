// functions/src/index.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
admin.initializeApp();

export const onTaskWrite = functions.firestore
    .document('propertask/tarefas/tarefas/{id}')
    .onWrite(async (change, ctx) => {
        const after = change.after.exists ? change.after.data() as any : null;
        const before = change.before.exists ? change.before.data() as any : null;
        if (!after) return;

        const newResp = after.responsavelId;
        const oldResp = before?.responsavelId;
        if (!newResp || newResp === oldResp) return;

        const tokensSnap = await admin.firestore()
            .collection('propertask').doc('usuarios').collection('usuarios')
            .doc(newResp).collection('tokens').get();
        const tokens = tokensSnap.docs.map(d => d.id).filter(Boolean);
        if (!tokens.length) return;

        const titulo = after.titulo ?? 'Nova tarefa';
        const prop = after.propriedadeNome ?? '';
        const route = `/tarefas/${ctx.params.id}`;

        const message: admin.messaging.MulticastMessage = {
            notification: { title: 'Nova tarefa atribuída', body: `${titulo} — ${prop}` },
            data: { route },
            tokens,
            android: { priority: 'high' },
            apns: { headers: { 'apns-priority': '10' } },
        };

        await admin.messaging().sendEachForMulticast(message);
    });
