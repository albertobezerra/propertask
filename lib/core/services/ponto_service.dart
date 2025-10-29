import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class PontoService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _registros =>
      _db.collection('propertask').doc('ponto').collection('registros');

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

  Future<void> registrarPonto(
    String usuarioId,
    String tipo,
    String? observacao,
  ) async {
    final position = await Geolocator.getCurrentPosition();
    final agora = DateTime.now();
    final arredondado = _arredondarHora(agora);

    await _registros.add({
      'usuarioId': usuarioId,
      'tipo': tipo,
      'horarioReal': Timestamp.fromDate(agora),
      'horarioArredondado': Timestamp.fromDate(arredondado),
      'localizacao': GeoPoint(position.latitude, position.longitude),
      'observacao': observacao,
    });
  }
}
