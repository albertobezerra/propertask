// lib/core/utils/permissions.dart
enum Cargo {
  dev,
  ceo,
  coordenador,
  supervisor,
  rh,
  limpeza,
  lavanderia,
  outro, // default/visitante etc.
}

class Permissions {
  // Ranking de poder (menor número = mais poder)
  static const _rank = {
    Cargo.dev: 0,
    Cargo.ceo: 1,
    Cargo.coordenador: 2,
    Cargo.supervisor: 3,
    Cargo.rh: 4,
    Cargo.limpeza: 5,
    Cargo.lavanderia: 5,
    Cargo.outro: 6,
  };

  // Mapeia string do banco para enum com fallback
  static Cargo cargoFromString(String s) {
    switch (s.trim().toUpperCase()) {
      case 'DEV':
        return Cargo.dev;
      case 'CEO':
        return Cargo.ceo;
      case 'COORDENADOR':
      case 'COORD':
        return Cargo.coordenador;
      case 'SUPERVISOR':
      case 'SUPS':
        return Cargo.supervisor;
      case 'RH':
        return Cargo.rh;
      case 'LIMPEZA':
        return Cargo.limpeza;
      case 'LAVANDERIA':
        return Cargo.lavanderia;
      default:
        return Cargo.outro;
    }
  }

  // ---------- VISIBILIDADE DE TELAS (Drawer) ----------
  // Observação: SUPERVISOR vê tudo exceto Lavanderia
  static bool podeVerDashboard(String cargo) => true;

  static bool podeVerPropriedades(String cargo) {
    final c = cargoFromString(cargo);
    return {
      Cargo.dev,
      Cargo.ceo,
      Cargo.coordenador,
      Cargo.supervisor,
      Cargo.limpeza,
      Cargo.lavanderia,
      Cargo.rh,
    }.contains(c);
  }

  static bool podeVerTarefas(String cargo) {
    final c = cargoFromString(cargo);
    return {
      Cargo.dev,
      Cargo.ceo,
      Cargo.coordenador,
      Cargo.supervisor,
      Cargo.limpeza,
      Cargo.lavanderia,
    }.contains(c);
  }

  static bool podeVerLavanderia(String cargo) {
    final c = cargoFromString(cargo);
    // SUPERVISOR não pode ver Lavanderia (exceção solicitada)
    if (c == Cargo.supervisor) return false;
    return {
      Cargo.dev,
      Cargo.ceo,
      Cargo.coordenador,
      Cargo.lavanderia,
    }.contains(c);
  }

  static bool podeVerEquipe(String cargo) {
    final c = cargoFromString(cargo);
    return {
      Cargo.dev,
      Cargo.ceo,
      Cargo.coordenador,
      Cargo.supervisor,
      Cargo.rh,
    }.contains(c);
  }

  static bool podeVerRelatorios(String cargo) {
    final c = cargoFromString(cargo);
    return {Cargo.dev, Cargo.ceo, Cargo.coordenador}.contains(c);
  }

  // ---------- GERENCIAMENTO DE DOMÍNIO ----------
  static bool podeGerenciarPropriedades(String cargo) {
    final c = cargoFromString(cargo);
    return {Cargo.dev, Cargo.ceo, Cargo.coordenador}.contains(c);
  }

  static bool podeGerenciarUsuarios(String cargo) {
    final c = cargoFromString(cargo);
    // Sups podem criar (add) na Equipe (ver abaixo em regras por ação)
    return {
      Cargo.dev,
      Cargo.ceo,
      Cargo.coordenador,
      Cargo.supervisor,
      Cargo.rh,
    }.contains(c);
  }

  static bool podeEditarPonto(String cargo) {
    final c = cargoFromString(cargo);
    return {Cargo.dev, Cargo.ceo, Cargo.coordenador, Cargo.rh}.contains(c);
  }

  // ---------- EQUIPE: CRUD COM HIERARQUIA ----------
  // Regras:
  // - DEV pode criar/editar/excluir todos.
  // - CEO idem para todos abaixo de CEO (não mexe em DEV).
  // - COORD pode tudo em quem tem rank maior (abaixo de COORD: SUP, RH, LIMPEZA, LAVANDERIA, OUTRO).
  // - SUPERVISOR:
  //   * Pode criar novos usuários (qualquer cargo até SUPERVISOR no máximo).
  //   * Pode editar/excluir apenas cargos com rank maior que SUPERVISOR (ou seja, abaixo: RH, LIMPEZA, LAVANDERIA, OUTRO).
  //   * Não pode editar/excluir CEOs e COORDENADOR(es).
  // - RH segue regras de rank (padrão), sem privilégios adicionais sobre C-level/coord.

  static bool podeCriarUsuario(String autorCargo, String novoCargo) {
    final a = cargoFromString(autorCargo);
    final n = cargoFromString(novoCargo);
    if (a == Cargo.dev) return true;
    if (a == Cargo.ceo) return _rank[a]! < _rank[n]!;
    if (a == Cargo.coordenador) return _rank[a]! < _rank[n]!;
    if (a == Cargo.supervisor) {
      // Sup pode criar até SUPERVISOR (não pode criar COORD/CEO/DEV)
      return _rank[n]! >= _rank[Cargo.supervisor]!;
    }
    // RH e demais: só cargos abaixo (sem poder sobre sup/coord/ceo/dev)
    return _rank[a]! < _rank[n]!;
  }

  static bool podeEditarUsuario(String autorCargo, String alvoCargo) {
    final a = cargoFromString(autorCargo);
    final t = cargoFromString(alvoCargo);
    if (a == Cargo.dev) return true;
    if (a == Cargo.ceo) return _rank[a]! < _rank[t]!;
    if (a == Cargo.coordenador) return _rank[a]! < _rank[t]!;
    if (a == Cargo.supervisor) {
      // Não pode editar CEO/COORD/DEV/SUP (si mesmo ou pares)
      // Pode editar RH/LIMPEZA/LAVANDERIA/OUTRO
      return _rank[t]! > _rank[Cargo.supervisor]!;
    }
    // RH e demais: apenas quem está abaixo
    return _rank[a]! < _rank[t]!;
  }

  static bool podeExcluirUsuario(String autorCargo, String alvoCargo) {
    final a = cargoFromString(autorCargo);
    final t = cargoFromString(alvoCargo);
    if (a == Cargo.dev) return true;
    if (a == Cargo.ceo) return _rank[a]! < _rank[t]!;
    if (a == Cargo.coordenador) return _rank[a]! < _rank[t]!;
    if (a == Cargo.supervisor) {
      // Mesmo critério do editar: não pode em CEO/COORD/DEV/SUP
      return _rank[t]! > _rank[Cargo.supervisor]!;
    }
    return _rank[a]! < _rank[t]!;
  }

  // Utilitário para ordenar por poder (útil na UI)
  static int compareCargos(String a, String b) {
    return _rank[cargoFromString(a)]!.compareTo(_rank[cargoFromString(b)]!);
  }
}
