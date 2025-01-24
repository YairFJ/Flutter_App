class MeasurementUnits {
  static const Map<String, List<String>> categories = {
    'Volumen': [
      'ml (mililitros)',
      'l (litros)',
      'taza',
      'cucharada',
      'cucharadita',
      'onza fl',
      'taza americana',
    ],
    'Peso': [
      'g (gramos)',
      'kg (kilogramos)',
      'oz (onzas)',
      'lb (libras)',
    ],
    'Unidades': [
      'unidad',
      'diente',
      'pizca',
      'al gusto',
      'puñado',
      'rodaja',
      'trozo',
    ],
    'Medidas específicas': [
      'taza de café',
      'vaso de agua',
      'copa de vino',
      'lata',
      'paquete',
    ],
  };

  static List<String> getAllUnits() {
    List<String> allUnits = [];
    categories.forEach((_, units) => allUnits.addAll(units));
    return allUnits..sort();
  }
} 