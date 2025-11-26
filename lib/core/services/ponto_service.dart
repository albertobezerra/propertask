import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class PontoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // REFACTORIZADO: recebe empresaId explicitamente
  CollectionReference _registros(String empresaId) =>
      _db.collection('empresas').doc(empresaId).collection('pontoRegistros');

  DateTime _arredondarHora(DateTime hora) {
    final minutos = hora.minute;
    final arredondado = minutos < 15
        ? 0
        : minutos < 45
        ? 30
        : 60;
    final novaHora = hora.copyWith(minute: 0, second: 0, millisecond: 0);
    if (arredondado == 60) {
      return novaHora.add(const Duration(hours: 1));
    }
    return novaHora.add(Duration(minutes: arredondado));
  }

  // REFACTORIZADO: recebe empresaId explicitamente!
  Future<void> registrarPonto(
    String empresaId,
    String usuarioId,
    String tipo,
    String? observacao,
  ) async {
    final position = await Geolocator.getCurrentPosition();
    final agora = DateTime.now();
    final arredondado = _arredondarHora(agora);

    await _registros(empresaId).add({
      'usuarioId': usuarioId,
      'tipo': tipo,
      'horarioReal': Timestamp.fromDate(agora),
      'horarioArredondado': Timestamp.fromDate(arredondado),
      'localizacao': GeoPoint(position.latitude, position.longitude),
      'observacao': observacao,
    });
  }
}
