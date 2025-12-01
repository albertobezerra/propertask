import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
admin.initializeApp();

// ============ NOTIFICAÇÕES EM TEMPO REAL (onWrite) ============
export const onTaskWrite = functions.region('europe-west1').firestore
    .document('empresas/{empresaId}/tarefas/{tarefaId}')
    .onWrite(async (change, ctx) => {
        const after = change.after.exists ? (change.after.data() as any) : null;
        const before = change.before.exists ? (change.before.data() as any) : null;

        if (!after) return;

        const empresaId = ctx.params.empresaId;
        const tarefaId = ctx.params.tarefaId;

        // ============ CENÁRIO 1: Nova atribuição ============
        const newResp = after.responsavelId;
        const oldResp = before?.responsavelId;

        if (newResp && newResp !== oldResp) {
            console.log('nova atribuição detectada');
            await notificarUsuario(
                empresaId,
                newResp,
                'Nova tarefa atribuída',
                `${after.titulo ?? 'Tarefa'} — ${after.propriedadeNome ?? ''}`,
                tarefaId
            );
        }

        // ============ CENÁRIO 2: Tarefa iniciada ============
        const newStatus = after.status;
        const oldStatus = before?.status;

        if (newStatus === 'em_andamento' && oldStatus === 'pendente') {
            console.log('tarefa iniciada - notificar gestores');
            await notificarGestores(
                empresaId,
                '🟡 Tarefa Iniciada',
                `${after.responsavelNome ?? 'Alguém'} iniciou ${formatTipo(after.tipo)} em ${after.propriedadeNome ?? ''}`,
                tarefaId
            );
        }

        // ============ CENÁRIO 3: Tarefa concluída ============
        if (newStatus === 'concluida' && oldStatus !== 'concluida') {
            console.log('tarefa concluída - notificar gestores');
            await notificarGestores(
                empresaId,
                '✅ Tarefa Concluída',
                `${after.responsavelNome ?? 'Alguém'} concluiu ${formatTipo(after.tipo)} em ${after.propriedadeNome ?? ''}`,
                tarefaId
            );
        }

        // ============ CENÁRIO 4: Tarefa reaberta ============
        if (newStatus === 'reaberta' && oldStatus !== 'reaberta') {
            console.log('tarefa reaberta');

            // Notifica o responsável
            if (after.responsavelId) {
                await notificarUsuario(
                    empresaId,
                    after.responsavelId,
                    '⚠️ Tarefa Reaberta',
                    `A tarefa de ${formatTipo(after.tipo)} em ${after.propriedadeNome ?? ''} foi reaberta`,
                    tarefaId
                );
            }

            // Notifica gestores
            await notificarGestores(
                empresaId,
                '⚠️ Tarefa Reaberta',
                `${after.responsavelNome ?? 'Alguém'} teve a tarefa de ${formatTipo(after.tipo)} reaberta`,
                tarefaId
            );
        }
    });

// ============ NOTIFICAÇÃO AGENDADA: Lembretes diários ============
// Roda todos os dias às 12h (hora de Portugal)
export const lembretesTarefasDiarias = functions
    .region('europe-west1')
    .pubsub.schedule('0 12 * * *')
    .timeZone('Europe/Lisbon')
    .onRun(async () => {
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
                    await notificarUsuario(
                        empresaId,
                        tarefa.responsavelId,
                        '⏰ Lembrete: Tarefa para hoje',
                        `${formatTipo(tarefa.tipo)} em ${tarefa.propriedadeNome ?? ''}`,
                        tarefaDoc.id
                    );
                }
            }
        }

        return null;
    });

// ============ NOTIFICAÇÃO AGENDADA: Tarefas atrasadas ============
// Roda todos os dias às 16h (hora de Portugal)
export const alertaTarefasAtrasadas = functions
    .region('europe-west1')
    .pubsub.schedule('0 16 * * *')
    .timeZone('Europe/Lisbon')
    .onRun(async () => {
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
                    await notificarUsuario(
                        empresaId,
                        tarefa.responsavelId,
                        '🔴 Tarefa Atrasada',
                        `${formatTipo(tarefa.tipo)} em ${tarefa.propriedadeNome ?? ''} está atrasada`,
                        tarefaDoc.id
                    );
                }

                // Notifica gestores
                await notificarGestores(
                    empresaId,
                    '🔴 Tarefa Atrasada',
                    `${tarefa.responsavelNome ?? 'Alguém'} tem tarefa atrasada: ${formatTipo(tarefa.tipo)}`,
                    tarefaDoc.id
                );
            }
        }

        return null;
    });

// ============ FUNÇÕES AUXILIARES ============

async function notificarUsuario(
    empresaId: string,
    userId: string,
    title: string,
    body: string,
    tarefaId: string
) {
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

    const message: admin.messaging.MulticastMessage = {
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
    } catch (error) {
        console.error(`Erro enviando notificação para ${userId}:`, error);
    }
}

async function notificarGestores(
    empresaId: string,
    title: string,
    body: string,
    tarefaId: string
) {
    const gestoresSnap = await admin
        .firestore()
        .collection('empresas')
        .doc(empresaId)
        .collection('usuarios')
        .where('cargo', 'in', ['coordenador', 'supervisor', 'ceo', 'dev'])
        .get();

    console.log(`Encontrados ${gestoresSnap.size} gestores para notificar`);

    const notificacoes = gestoresSnap.docs.map((doc) =>
        notificarUsuario(empresaId, doc.id, title, body, tarefaId)
    );

    await Promise.all(notificacoes);
}

async function limparTokensInvalidos(
    resp: admin.messaging.BatchResponse,
    tokens: string[],
    empresaId: string,
    userId: string
) {
    const tokensToRemove: Promise<any>[] = [];

    resp.responses.forEach((result, index) => {
        const error = result.error;
        if (error) {
            if (error.code === 'messaging/invalid-registration-token' ||
                error.code === 'messaging/registration-token-not-registered') {
                tokensToRemove.push(
                    admin.firestore()
                        .collection('empresas')
                        .doc(empresaId)
                        .collection('usuarios')
                        .doc(userId)
                        .collection('tokens')
                        .doc(tokens[index])
                        .delete()
                );
            }
        }
    });

    if (tokensToRemove.length > 0) {
        await Promise.all(tokensToRemove);
        console.log(`Removidos ${tokensToRemove.length} tokens inválidos`);
    }
}

function formatTipo(tipo: string): string {
    const tipos: Record<string, string> = {
        'limpeza': 'limpeza',
        'entrega': 'entrega',
        'recolha': 'recolha',
        'manutencao': 'manutenção'
    };
    return tipos[tipo] || tipo;
}
