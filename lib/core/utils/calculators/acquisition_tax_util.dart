/// 부동산 유형 구분
enum PropertyType {
  housing,    // 주택
  nonHousing, // 주택 외
}

/// 주택 수 구분
enum HouseCount {
  one,   // 1주택자
  two,   // 2주택자
  three, // 3주택자
  four,  // 4주택자 이상
}

/// 지역 구분
enum AreaType {
  regulated,   // 조정대상지역
  nonRegulated, // 조정대상지역 외 (비규제지역)
}

/// 주택 외 취득 유형
enum NonHousingType {
  purchase,          // 매매 (토지, 건물 등) - 4%
  originalInherit,   // 원시취득(신축), 상속(농지 외) - 2.8%
  gift,              // 무상취득(증여) - 3.5%
  farmlandNew,       // 농지 매매 (신규) - 3%
  farmlandSelfFarm,  // 농지 매매 (2년이상 자경) - 1.5%
  farmlandInherit,   // 농지 상속 - 2.3%
}

/// 취득세 계산 결과
class AcquisitionTaxResult {
  final int acquisitionPrice;       // 취득가액 (원)
  final double acquisitionTaxRate;  // 취득세율
  final int acquisitionTaxBeforeReduction; // 감면 전 취득세 (원)
  final int acquisitionTax;         // 취득세 (원) - 감면 적용 후
  final int reductionAmount;        // 감면액 (원)
  final double ruralSpecialTaxRate; // 농어촌특별세율
  final int ruralSpecialTax;        // 농어촌특별세 (원)
  final double localEducationTaxRate; // 지방교육세율
  final int localEducationTax;      // 지방교육세 (원)
  final int totalTax;               // 총 세금 (원)
  final bool isFirstTimeBuyer;      // 생애최초 여부
  final bool isDepopulationArea;    // 인구감소지역 여부

  const AcquisitionTaxResult({
    required this.acquisitionPrice,
    required this.acquisitionTaxRate,
    required this.acquisitionTaxBeforeReduction,
    required this.acquisitionTax,
    required this.reductionAmount,
    required this.ruralSpecialTaxRate,
    required this.ruralSpecialTax,
    required this.localEducationTaxRate,
    required this.localEducationTax,
    required this.totalTax,
    this.isFirstTimeBuyer = false,
    this.isDepopulationArea = false,
  });
}

/// 취득세 계산 유틸리티
class AcquisitionTaxUtil {
  AcquisitionTaxUtil._();

  static const int _600million = 600000000;
  static const int _900million = 900000000;
  static const int _1200million = 1200000000;

  // 생애최초 감면 한도
  static const int _firstTimeReductionLimit = 2000000;       // 200만원
  static const int _firstTimeReductionLimitDepop = 3000000;  // 인구감소지역 300만원

  // ────────────────────────────────────────
  // 주택 취득세 계산
  // ────────────────────────────────────────

  /// 주택 취득세 계산
  static AcquisitionTaxResult calculateHousing({
    required int price,
    required HouseCount houseCount,
    required AreaType areaType,
    required bool isOver85sqm,
    bool isFirstTimeBuyer = false,
    bool isDepopulationArea = false,
  }) {
    final rates = _getHousingTaxRates(
      price: price,
      houseCount: houseCount,
      areaType: areaType,
      isOver85sqm: isOver85sqm,
    );

    return _buildResult(
      price: price,
      rates: rates,
      isFirstTimeBuyer: isFirstTimeBuyer,
      isDepopulationArea: isDepopulationArea,
    );
  }

  // ────────────────────────────────────────
  // 주택 외 취득세 계산
  // ────────────────────────────────────────

  /// 주택 외 취득세 계산
  static AcquisitionTaxResult calculateNonHousing({
    required int price,
    required NonHousingType type,
  }) {
    final rates = _getNonHousingTaxRates(type);

    return _buildResult(
      price: price,
      rates: rates,
      isFirstTimeBuyer: false,
      isDepopulationArea: false,
    );
  }

  // ────────────────────────────────────────
  // 기존 호환용 (주택 계산 래핑)
  // ────────────────────────────────────────

  /// 취득세 계산 (기존 API 호환)
  static AcquisitionTaxResult calculate({
    required int price,
    required HouseCount houseCount,
    required AreaType areaType,
    required bool isOver85sqm,
    bool isFirstTimeBuyer = false,
    bool isDepopulationArea = false,
  }) {
    return calculateHousing(
      price: price,
      houseCount: houseCount,
      areaType: areaType,
      isOver85sqm: isOver85sqm,
      isFirstTimeBuyer: isFirstTimeBuyer,
      isDepopulationArea: isDepopulationArea,
    );
  }

  // ────────────────────────────────────────
  // 내부: 결과 생성
  // ────────────────────────────────────────

  static AcquisitionTaxResult _buildResult({
    required int price,
    required Map<String, double> rates,
    required bool isFirstTimeBuyer,
    required bool isDepopulationArea,
  }) {
    final double acqRate = rates['acquisitionTaxRate']!;
    final double ruralRate = rates['ruralSpecialTaxRate']!;
    final double localEduRate = rates['localEducationTaxRate']!;

    final int acqTaxBeforeReduction = (price * acqRate).round();
    final int ruralTax = (price * ruralRate).round();

    // 생애최초 감면 적용
    int acqTax = acqTaxBeforeReduction;
    int reductionAmount = 0;

    if (isFirstTimeBuyer && price <= _1200million) {
      final int limit = isDepopulationArea
          ? _firstTimeReductionLimitDepop
          : _firstTimeReductionLimit;

      if (acqTaxBeforeReduction <= limit) {
        reductionAmount = acqTaxBeforeReduction;
        acqTax = 0;
      } else {
        reductionAmount = limit;
        acqTax = acqTaxBeforeReduction - limit;
      }
    }

    // 지방교육세 = 취득세(감면 후) × 10%
    final int localEduTax = (acqTax * 0.1).round();

    return AcquisitionTaxResult(
      acquisitionPrice: price,
      acquisitionTaxRate: acqRate,
      acquisitionTaxBeforeReduction: acqTaxBeforeReduction,
      acquisitionTax: acqTax,
      reductionAmount: reductionAmount,
      ruralSpecialTaxRate: ruralRate,
      ruralSpecialTax: ruralTax,
      localEducationTaxRate: localEduRate,
      localEducationTax: localEduTax,
      totalTax: acqTax + ruralTax + localEduTax,
      isFirstTimeBuyer: isFirstTimeBuyer,
      isDepopulationArea: isDepopulationArea,
    );
  }

  // ────────────────────────────────────────
  // 내부: 주택 세율 조회
  // ────────────────────────────────────────

  static Map<String, double> _getHousingTaxRates({
    required int price,
    required HouseCount houseCount,
    required AreaType areaType,
    required bool isOver85sqm,
  }) {
    switch (houseCount) {
      case HouseCount.one:
        return _getOneHouseRates(price, isOver85sqm);
      case HouseCount.two:
        return _getTwoHouseRates(price, areaType, isOver85sqm);
      case HouseCount.three:
        return _getThreeHouseRates(areaType);
      case HouseCount.four:
        return _getFourPlusHouseRates(areaType);
    }
  }

  /// 1주택자 세율
  static Map<String, double> _getOneHouseRates(int price, bool isOver85sqm) {
    if (price <= _600million) {
      return {
        'acquisitionTaxRate': 0.01,
        'ruralSpecialTaxRate': 0.0,
        'localEducationTaxRate': 0.001,
      };
    } else if (price <= _900million) {
      final double acqRate = _calculateMiddleRangeRate(price);
      return {
        'acquisitionTaxRate': acqRate,
        'ruralSpecialTaxRate': isOver85sqm ? 0.002 : 0.0,
        'localEducationTaxRate': acqRate / 10,
      };
    } else {
      return {
        'acquisitionTaxRate': 0.03,
        'ruralSpecialTaxRate': isOver85sqm ? 0.002 : 0.0,
        'localEducationTaxRate': 0.003,
      };
    }
  }

  /// 2주택자 세율
  static Map<String, double> _getTwoHouseRates(
    int price,
    AreaType areaType,
    bool isOver85sqm,
  ) {
    if (areaType == AreaType.regulated) {
      return {
        'acquisitionTaxRate': 0.08,
        'ruralSpecialTaxRate': 0.006,
        'localEducationTaxRate': 0.004,
      };
    }

    // 비규제지역 - 1주택자와 동일 기준
    if (price <= _600million) {
      return {
        'acquisitionTaxRate': 0.01,
        'ruralSpecialTaxRate': 0.0,
        'localEducationTaxRate': 0.001,
      };
    } else if (price <= _900million) {
      final double acqRate = _calculateMiddleRangeRate(price);
      return {
        'acquisitionTaxRate': acqRate,
        'ruralSpecialTaxRate': isOver85sqm ? 0.002 : 0.0,
        'localEducationTaxRate': acqRate / 10,
      };
    } else {
      return {
        'acquisitionTaxRate': 0.03,
        'ruralSpecialTaxRate': isOver85sqm ? 0.002 : 0.0,
        'localEducationTaxRate': 0.003,
      };
    }
  }

  /// 3주택자 세율
  static Map<String, double> _getThreeHouseRates(AreaType areaType) {
    if (areaType == AreaType.regulated) {
      return {
        'acquisitionTaxRate': 0.12,
        'ruralSpecialTaxRate': 0.01,
        'localEducationTaxRate': 0.004,
      };
    }
    return {
      'acquisitionTaxRate': 0.08,
      'ruralSpecialTaxRate': 0.006,
      'localEducationTaxRate': 0.004,
    };
  }

  /// 4주택 이상 세율
  static Map<String, double> _getFourPlusHouseRates(AreaType areaType) {
    if (areaType == AreaType.regulated) {
      return {
        'acquisitionTaxRate': 0.12,
        'ruralSpecialTaxRate': 0.01,
        'localEducationTaxRate': 0.004,
      };
    }
    return {
      'acquisitionTaxRate': 0.12,
      'ruralSpecialTaxRate': 0.01,
      'localEducationTaxRate': 0.004,
    };
  }

  // ────────────────────────────────────────
  // 내부: 주택 외 세율 조회
  // ────────────────────────────────────────

  static Map<String, double> _getNonHousingTaxRates(NonHousingType type) {
    switch (type) {
      case NonHousingType.purchase:
        // 주택 외 매매 (토지, 건물 등)
        return {
          'acquisitionTaxRate': 0.04,
          'ruralSpecialTaxRate': 0.002,
          'localEducationTaxRate': 0.004,
        };
      case NonHousingType.originalInherit:
        // 원시취득(신축), 상속(농지 외)
        return {
          'acquisitionTaxRate': 0.028,
          'ruralSpecialTaxRate': 0.002,
          'localEducationTaxRate': 0.0016,
        };
      case NonHousingType.gift:
        // 무상취득(증여)
        return {
          'acquisitionTaxRate': 0.035,
          'ruralSpecialTaxRate': 0.002,
          'localEducationTaxRate': 0.003,
        };
      case NonHousingType.farmlandNew:
        // 농지 매매 - 신규
        return {
          'acquisitionTaxRate': 0.03,
          'ruralSpecialTaxRate': 0.002,
          'localEducationTaxRate': 0.002,
        };
      case NonHousingType.farmlandSelfFarm:
        // 농지 매매 - 2년이상 자경
        return {
          'acquisitionTaxRate': 0.015,
          'ruralSpecialTaxRate': 0.0,
          'localEducationTaxRate': 0.001,
        };
      case NonHousingType.farmlandInherit:
        // 농지 상속
        return {
          'acquisitionTaxRate': 0.023,
          'ruralSpecialTaxRate': 0.002,
          'localEducationTaxRate': 0.0006,
        };
    }
  }

  /// 6억 초과 ~ 9억 이하 구간 취득세율 계산
  /// 공식: (취득가액 × 2/3억원 - 3) × 1/100
  static double _calculateMiddleRangeRate(int price) {
    return (price * 2 / 300000000 - 3) / 100;
  }
}
