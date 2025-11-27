import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
admin.initializeApp();

export const onTaskWrite = functions.region('europe-west1').firestore
    .document('empresas/{empresaId}/tarefas/{tarefaId}')
    .onWrite(async (change, ctx) => {
        console.error('DEBUG FORÇADO');

        const after = change.after.exists ? (change.after.data() as any) : null;
        const before = change.before.exists ? (change.before.data() as any) : null;

        console.log('onTaskWrite fired', {
            empresaId: ctx.params.empresaId,
            tarefaId: ctx.params.tarefaId,
        });

        if (!after) {
            console.log('no after doc, exiting');
            return;
        }

        const newResp = after.responsavelId;
        const oldResp = before?.responsavelId;
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

        const titulo = after.titulo ?? 'Nova tarefa';
        const prop = after.propriedadeNome ?? '';
        const route = `/tarefas/${tarefaId}`;

        const message: admin.messaging.MulticastMessage = {
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
