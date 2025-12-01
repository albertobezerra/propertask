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
        const executorId = ctx.auth?.uid || null;

        // ============ CENÁRIO 1: Nova atribuição ============
        const newResp = after.responsavelId;
        const oldResp = before?.responsavelId;

        if (newResp && newResp !== oldResp) {
            console.log('Nova atribuição detectada');
            await notificarUsuario(
                empresaId,
                newResp,
                'Nova tarefa atribuída',
                `${after.titulo ?? 'Tarefa'} — ${after.propriedadeNome ?? ''}`,
                tarefaId,
                executorId
            );
        }

        // ============ CENÁRIO 2: Tarefa iniciada ============
        const newStatus = after.status;
        const oldStatus = before?.status;

        if (newStatus === 'em_andamento' && oldStatus === 'pendente') {
            console.log('Tarefa iniciada - notificar gestores');
            await notificarGestores(
                empresaId,
                '🟡 Tarefa Iniciada',
                `${after.responsavelNome ?? 'Alguém'} iniciou ${formatTipo(after.tipo)} em ${after.propriedadeNome ?? ''}`,
                tarefaId,
                after.responsavelId
            );
        }

        // ============ CENÁRIO 3: Tarefa concluída ============
        if (newStatus === 'concluida' && oldStatus !== 'concluida') {
            console.log('Tarefa concluída - notificar gestores');
            await notificarGestores(
                empresaId,
                '✅ Tarefa Concluída',
                `${after.responsavelNome ?? 'Alguém'} concluiu ${formatTipo(after.tipo)} em ${after.propriedadeNome ?? ''}`,
                tarefaId,
                after.responsavelId
            );
        }

        // ============ CENÁRIO 4: Tarefa reaberta ============
        if (newStatus === 'reaberta' && oldStatus !== 'reaberta') {
            console.log('Tarefa reaberta');

            // Pega quem reabriu do documento (mais confiável que ctx.auth)
            const quemReabriu = after.reabertaPor || null;

            // Notifica o responsável (se não for ele que reabriu)
            if (after.responsavelId && after.responsavelId !== quemReabriu) {
                await notificarUsuario(
                    empresaId,
                    after.responsavelId,
                    '⚠️ Tarefa Reaberta',
                    `A tarefa de ${formatTipo(after.tipo)} em ${after.propriedadeNome ?? ''} foi reaberta`,
                    tarefaId,
                    quemReabriu // ← USA O CAMPO DO DOCUMENTO
                );
            }

            // Notifica gestores (exceto quem reabriu)
            await notificarGestores(
                empresaId,
                '⚠️ Tarefa Reaberta',
                `${after.responsavelNome ?? 'Alguém'} teve a tarefa de ${formatTipo(after.tipo)} reaberta`,
                tarefaId,
                quemReabriu // ← USA O CAMPO DO DOCUMENTO
            );
        }

    });

// ============ NOTIFICAÇÃO AGENDADA: Lembretes e alertas ============
export const verificarTarefas = functions
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

async function enviarLembretesDiarios(db: admin.firestore.Firestore, empresaId: string) {
    const hoje = new Date();
    hoje.setHours(0, 0, 0, 0);
    const amanha = new Date(hoje);
    amanha.setDate(amanha.getDate() + 1);

    // Verifica se já enviou hoje
    const configRef = db.collection('empresas').doc(empresaId).collection('config').doc('notificacoes');
    const configSnap = await configRef.get();
    const hojeStr = hoje.toISOString().split('T')[0];

    if (configSnap.exists && configSnap.data()?.ultimoLembrete === hojeStr) {
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
            await notificarUsuario(
                empresaId,
                tarefa.responsavelId,
                '⏰ Lembrete: Tarefa para hoje',
                `${formatTipo(tarefa.tipo)} em ${tarefa.propriedadeNome ?? ''}`,
                tarefaDoc.id,
                null
            );
        }
    }

    await configRef.set({ ultimoLembrete: hojeStr }, { merge: true });
}

async function enviarAlertasAtrasadas(db: admin.firestore.Firestore, empresaId: string) {
    const hoje = new Date();
    hoje.setHours(0, 0, 0, 0);

    // Verifica se já enviou hoje
    const configRef = db.collection('empresas').doc(empresaId).collection('config').doc('notificacoes');
    const configSnap = await configRef.get();
    const hojeStr = hoje.toISOString().split('T')[0];

    if (configSnap.exists && configSnap.data()?.ultimoAlerta === hojeStr) {
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
            await notificarUsuario(
                empresaId,
                tarefa.responsavelId,
                '🔴 Tarefa Atrasada',
                `${formatTipo(tarefa.tipo)} em ${tarefa.propriedadeNome ?? ''} está atrasada`,
                tarefaDoc.id,
                null
            );
        }

        await notificarGestores(
            empresaId,
            '🔴 Tarefa Atrasada',
            `${tarefa.responsavelNome ?? 'Alguém'} tem tarefa atrasada: ${formatTipo(tarefa.tipo)}`,
            tarefaDoc.id,
            tarefa.responsavelId
        );
    }

    await configRef.set({ ultimoAlerta: hojeStr }, { merge: true });
}

async function notificarUsuario(
    empresaId: string,
    userId: string,
    title: string,
    body: string,
    tarefaId: string,
    excluirUsuarioId: string | null
) {
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
        console.log(`Notificação para ${userId}: ${resp.successCount}/${tokens.length} enviadas`);
        await limparTokensInvalidos(resp, tokens, empresaId, userId);
    } catch (error) {
        console.error(`Erro notificando ${userId}:`, error);
    }
}

async function notificarGestores(
    empresaId: string,
    title: string,
    body: string,
    tarefaId: string,
    excluirUsuarioId: string | null
) {
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
        .map((doc) =>
            notificarUsuario(empresaId, doc.id, title, body, tarefaId, excluirUsuarioId)
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

function calcularHoraLocal(data: Date, timezone: string): number {
    const offsets: Record<string, number> = {
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
