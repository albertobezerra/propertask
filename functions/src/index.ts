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

        // Pega quem fez a mudança (se disponível no contexto)
        const executorId = ctx.auth?.uid || null;

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
                tarefaId,
                executorId // não notifica quem atribuiu
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
                tarefaId,
                after.responsavelId // não notifica quem iniciou
            );
        }

        // ============ CENÁRIO 3: Tarefa concluída ============
        if (newStatus === 'concluida' && oldStatus !== 'concluida') {
            console.log('tarefa concluída - notificar gestores');
            await notificarGestores(
                empresaId,
                '✅ Tarefa Concluída',
                `${after.responsavelNome ?? 'Alguém'} concluiu ${formatTipo(after.tipo)} em ${after.propriedadeNome ?? ''}`,
                tarefaId,
                after.responsavelId // não notifica quem concluiu
            );
        }

        // ============ CENÁRIO 4: Tarefa reaberta ============
        if (newStatus === 'reaberta' && oldStatus !== 'reaberta') {
            console.log('tarefa reaberta');

            // Notifica o responsável (se não for ele que reabriu)
            if (after.responsavelId && after.responsavelId !== executorId) {
                await notificarUsuario(
                    empresaId,
                    after.responsavelId,
                    '⚠️ Tarefa Reaberta',
                    `A tarefa de ${formatTipo(after.tipo)} em ${after.propriedadeNome ?? ''} foi reaberta`,
                    tarefaId,
                    executorId
                );
            }

            // Notifica gestores (exceto quem reabriu)
            await notificarGestores(
                empresaId,
                '⚠️ Tarefa Reaberta',
                `${after.responsavelNome ?? 'Alguém'} teve a tarefa de ${formatTipo(after.tipo)} reaberta`,
                tarefaId,
                executorId // não notifica quem reabriu
            );
        }
    });

// ============ NOTIFICAÇÃO AGENDADA: Lembretes e alertas ============
// Roda a cada 2 horas para cobrir todos os timezones
export const verificarTarefas = functions
    .region('europe-west1')
    .pubsub.schedule('0 */2 * * *') // A cada 2 horas
    .timeZone('UTC')
    .onRun(async () => {
        console.log('Verificando tarefas em todas as empresas');

        const db = admin.firestore();
        const agora = new Date();
        const horaAtual = agora.getUTCHours();

        // Busca todas as empresas
        const empresasSnap = await db.collection('empresas').get();

        for (const empresaDoc of empresasSnap.docs) {
            const empresaId = empresaDoc.id;
            const empresaData = empresaDoc.data();

            // Pega timezone da empresa (padrão: Europe/Lisbon se não tiver)
            const empresaTimezone = empresaData.timezone || 'Europe/Lisbon';

            // Calcula hora local da empresa
            const horaLocalEmpresa = calcularHoraLocal(agora, empresaTimezone);

            console.log(`Empresa ${empresaId}: hora local ~${horaLocalEmpresa}h (timezone: ${empresaTimezone})`);

            // ======== LEMBRETES MATINAIS (entre 8h e 10h local) ========
            if (horaLocalEmpresa >= 8 && horaLocalEmpresa < 10) {
                await enviarLembretesDiarios(db, empresaId);
            }

            // ======== ALERTAS DE TAREFAS ATRASADAS (entre 15h e 17h local) ========
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

    const tarefasSnap = await db
        .collection('empresas')
        .doc(empresaId)
        .collection('tarefas')
        .where('status', '==', 'pendente')
        .where('data', '>=', admin.firestore.Timestamp.fromDate(hoje))
        .where('data', '<', admin.firestore.Timestamp.fromDate(amanha))
        .get();

    console.log(`Empresa ${empresaId}: ${tarefasSnap.size} tarefas pendentes hoje`);

    // Verifica se já enviou lembretes hoje
    const configRef = db.collection('empresas').doc(empresaId).collection('config').doc('notificacoes');
    const configSnap = await configRef.get();
    const ultimoLembrete = configSnap.exists ? configSnap.data()?.ultimoLembrete : null;

    const hojeStr = hoje.toISOString().split('T')[0];
    if (ultimoLembrete === hojeStr) {
        console.log(`Lembretes já enviados hoje para empresa ${empresaId}`);
        return;
    }

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

    // Marca que já enviou lembretes hoje
    await configRef.set({ ultimoLembrete: hojeStr }, { merge: true });
}

async function enviarAlertasAtrasadas(db: admin.firestore.Firestore, empresaId: string) {
    const hoje = new Date();
    hoje.setHours(0, 0, 0, 0);

    const tarefasSnap = await db
        .collection('empresas')
        .doc(empresaId)
        .collection('tarefas')
        .where('status', 'in', ['pendente', 'em_andamento', 'reaberta'])
        .where('data', '<', admin.firestore.Timestamp.fromDate(hoje))
        .get();

    console.log(`Empresa ${empresaId}: ${tarefasSnap.size} tarefas atrasadas`);

    // Verifica se já enviou alertas hoje
    const configRef = db.collection('empresas').doc(empresaId).collection('config').doc('notificacoes');
    const configSnap = await configRef.get();
    const ultimoAlerta = configSnap.exists ? configSnap.data()?.ultimoAlerta : null;

    const hojeStr = hoje.toISOString().split('T')[0];
    if (ultimoAlerta === hojeStr) {
        console.log(`Alertas já enviados hoje para empresa ${empresaId}`);
        return;
    }

    for (const tarefaDoc of tarefasSnap.docs) {
        const tarefa = tarefaDoc.data();

        // Notifica o responsável
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

        // Notifica gestores
        await notificarGestores(
            empresaId,
            '🔴 Tarefa Atrasada',
            `${tarefa.responsavelNome ?? 'Alguém'} tem tarefa atrasada: ${formatTipo(tarefa.tipo)}`,
            tarefaDoc.id,
            tarefa.responsavelId
        );
    }

    // Marca que já enviou alertas hoje
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
    // Não notifica se for o próprio usuário que executou a ação
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
        console.log(`Notificação enviada para ${userId}: ${resp.successCount} sucesso`);

        await limparTokensInvalidos(resp, tokens, empresaId, userId);
    } catch (error) {
        console.error(`Erro enviando notificação para ${userId}:`, error);
    }
}

async function notificarGestores(
    empresaId: string,
    title: string,
    body: string,
    tarefaId: string,
    excluirUsuarioId: string | null
) {
    const gestoresSnap = await admin
        .firestore()
        .collection('empresas')
        .doc(empresaId)
        .collection('usuarios')
        .where('cargo', 'in', ['coordenador', 'supervisor', 'ceo', 'dev'])
        .get();

    console.log(`Encontrados ${gestoresSnap.size} gestores para notificar`);

    const notificacoes = gestoresSnap.docs
        .filter((doc) => doc.id !== excluirUsuarioId) // Exclui quem fez a ação
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
    // Calcula offset aproximado baseado em timezones comuns
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
