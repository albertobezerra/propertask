const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.notifyNewTask = functions.firestore
    .document('propertask/tarefas/tarefas/{tarefaId}')
    .onCreate(async (snap, context) => {
        const tarefa = snap.data();
        const userDoc = await admin.firestore()
            .collection('propertask')
            .doc('usuarios')
            .collection('usuarios')
            .doc(tarefa.responsavelId)
            .get();

        const token = userDoc.data()?.fcmToken;
        if (token) {
            await admin.messaging().send({
                token: token,
                notification: {
                    title: 'Nova Tarefa Atribuída',
                    body: `Você foi atribuído à tarefa: ${tarefa.titulo}`,
                },
            });
            console.log(`Notificação enviada para ${tarefa.responsavelId}`);
        }
    });