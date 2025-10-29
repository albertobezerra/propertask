// lib/core/utils/permissions.dart
class Permissions {
  // GERENCIAMENTO
  static bool podeGerenciarPropriedades(String cargo) =>
      ['DEV', 'CEO', 'COORDENADOR'].contains(cargo);

  static bool podeGerenciarUsuarios(String cargo) =>
      ['DEV', 'CEO', 'COORDENADOR', 'SUPERVISOR', 'RH'].contains(cargo);

  static bool podeEditarPonto(String cargo) =>
      ['DEV', 'CEO', 'COORDENADOR', 'RH'].contains(cargo);

  // VISUALIZAÇÃO
  static bool podeVerRelatorios(String cargo) =>
      ['DEV', 'CEO', 'COORDENADOR'].contains(cargo);

  static bool podeVerEquipe(String cargo) =>
      ['DEV', 'CEO', 'COORDENADOR', 'SUPERVISOR', 'RH'].contains(cargo);

  static bool podeVerLavanderia(String cargo) =>
      ['DEV', 'CEO', 'COORDENADOR', 'LAVANDERIA'].contains(cargo);

  static bool podeVerTarefas(String cargo) =>
      ['DEV', 'CEO', 'COORDENADOR', 'LIMPEZA', 'LAVANDERIA'].contains(cargo);

  static bool podeVerPropriedades(String cargo) =>
      ['DEV', 'CEO', 'COORDENADOR', 'LIMPEZA', 'LAVANDERIA'].contains(cargo);
}
