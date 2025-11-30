import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
admin.initializeApp();

export const onTaskWrite = functions.region('europe-west1').firestore
    .document('empresas/{empresaId}/tarefas/{tarefaId}')
    .onWrite(async (change, ctx) => {
        console.log('onTaskWrite fired', {
            empresaId: ctx.params.empresaId,
            tarefaId: ctx.params.tarefaId,
        });

        const after = change.after.exists ? (change.after.data() as any) : null;
        const before = change.before.exists ? (change.before.data() as any) : null;

        if (!after) {
            console.log('no after doc, exiting');
            return;
        }

        const empresaId = ctx.params.empresaId;
        const tarefaId = ctx.params.tarefaId;

        // ============ CENÁRIO 1: Nova atribuição de responsável ============
        const newResp = after.responsavelId;
        const oldResp = before?.responsavelId;
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

                console.log('sending multicast for assignment', JSON.stringify(message));

                try {
                    const resp = await admin.messaging().sendEachForMulticast(message);
                    console.log('multicast response for assignment', JSON.stringify(resp));
                } catch (error) {
                    console.error('error sending assignment notification', error);
                }
            }
        }

        // ============ CENÁRIO 2: Tarefa reaberta ============
        const newStatus = after.status;
        const oldStatus = before?.status;
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
                const tipo = formatTipo(after.tipo ?? 'tarefa');
                const prop = after.propriedadeNome ?? 'Propriedade';
                const route = `/tarefas/${tarefaId}`;

                const message: admin.messaging.MulticastMessage = {
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
                    const tokensToRemove: Promise<any>[] = [];
                    resp.responses.forEach((result, index) => {
                        const error = result.error;
                        if (error) {
                            console.error('Failure sending to', tokens[index], error);
                            if (error.code === 'messaging/invalid-registration-token' ||
                                error.code === 'messaging/registration-token-not-registered') {
                                tokensToRemove.push(
                                    admin.firestore()
                                        .collection('empresas')
                                        .doc(empresaId)
                                        .collection('usuarios')
                                        .doc(responsavelId)
                                        .collection('tokens')
                                        .doc(tokens[index])
                                        .delete()
                                );
                            }
                        }
                    });

                    if (tokensToRemove.length > 0) {
                        await Promise.all(tokensToRemove);
                        console.log(`Removed ${tokensToRemove.length} invalid tokens`);
                    }
                } catch (error) {
                    console.error('error sending reopening notification', error);
                }
            }
        }
    });

// Helper function para formatar tipo de tarefa
function formatTipo(tipo: string): string {
    const tipos: Record<string, string> = {
        'limpeza': 'limpeza',
        'entrega': 'entrega',
        'recolha': 'recolha',
        'manutencao': 'manutenção'
    };
    return tipos[tipo] || tipo;
}
