import 'package:flutter/foundation.dart';
import 'package:budongsan_app/core/extensions/number_extensions.dart';
import 'package:budongsan_app/core/utils/calculators/acquisition_tax_util.dart';
import 'package:budongsan_app/data/models/saved_calculation.dart';

/// 계산 결과 + 입력 스냅샷을 묶는 모델
class AcquisitionTaxSnapshot {
  final String id;
  final int price;
  final PropertyType propertyType;
  final HouseCount houseCount;
  final AreaType areaType;
  final bool isOver85sqm;
  final bool isFirstTimeBuyer;
  final bool isDepopulationArea;
  final NonHousingType? nonHousingType;
  final AcquisitionTaxResult result;
  final DateTime calculatedAt;

  AcquisitionTaxSnapshot({
    String? id,
    required this.price,
    required this.propertyType,
    required this.houseCount,
    required this.areaType,
    required this.isOver85sqm,
    required this.isFirstTimeBuyer,
    required this.isDepopulationArea,
    this.nonHousingType,
    required this.result,
    required this.calculatedAt,
  }) : id = id ?? 'acq_${calculatedAt.millisecondsSinceEpoch}';

  String get houseCountLabel {
    switch (houseCount) {
      case HouseCount.one:
        return '1주택';
      case HouseCount.two:
        return '2주택';
      case HouseCount.three:
        return '3주택';
      case HouseCount.four:
        return '4주택+';
    }
  }

  String get areaTypeLabel =>
      areaType == AreaType.regulated ? '조정대상' : '비규제';

  String get sizeLabel => isOver85sqm ? '85㎡ 초과' : '85㎡ 이하';

  String get firstTimeBuyerLabel {
    if (!isFirstTimeBuyer) return '';
    return isDepopulationArea ? '생애최초(인구감소)' : '생애최초';
  }

  String get propertyTypeLabel {
    if (propertyType == PropertyType.housing) return '주택';
    return nonHousingTypeLabel;
  }

  String get nonHousingTypeLabel {
    switch (nonHousingType) {
      case NonHousingType.purchase:
        return '주택 외 매매(토지/건물)';
      case NonHousingType.originalInherit:
        return '주택 외 신축/상속';
      case NonHousingType.gift:
        return '주택 외 증여';
      case NonHousingType.farmlandNew:
        return '주택 외 농지(신규)';
      case NonHousingType.farmlandSelfFarm:
        return '주택 외 농지(자경)';
      case NonHousingType.farmlandInherit:
        return '주택 외 농지(상속)';
      case null:
        return '';
    }
  }

  /// 태그용 라벨 리스트
  List<String> get tagLabels {
    final tags = <String>[];
    tags.add(propertyTypeLabel);
    if (propertyType == PropertyType.housing) {
      tags.add(houseCountLabel);
      tags.add(areaTypeLabel);
      tags.add(sizeLabel);
      if (firstTimeBuyerLabel.isNotEmpty) tags.add(firstTimeBuyerLabel);
    }

    return tags;
  }

  /// SavedCalculation 모델로 변환
  SavedCalculation toSavedCalculation() {
    return SavedCalculation(
      id: id,
      type: 'acquisition_tax',
      title: '취득세 ${result.totalTax.toKoreanWon()}',
      subtitle: '취득가액 ${price.toKoreanWon()}',
      tags: tagLabels,
      data: {
        'price': price,
        'propertyType': propertyType.index,
        'houseCount': houseCount.index,
        'areaType': areaType.index,
        'isOver85sqm': isOver85sqm,
        'isFirstTimeBuyer': isFirstTimeBuyer,
        'isDepopulationArea': isDepopulationArea,
        'nonHousingType': nonHousingType?.index,
        'acquisitionTax': result.acquisitionTax,
        'ruralSpecialTax': result.ruralSpecialTax,
        'localEducationTax': result.localEducationTax,
        'totalTax': result.totalTax,
        'acquisitionTaxRate': result.acquisitionTaxRate,
        'ruralSpecialTaxRate': result.ruralSpecialTaxRate,
        'localEducationTaxRate': result.localEducationTaxRate,
        'reductionAmount': result.reductionAmount,
      },
      savedAt: calculatedAt,
    );
  }
}

class AcquisitionTaxProvider extends ChangeNotifier {
  int _price = 0;
  PropertyType _propertyType = PropertyType.housing;
  HouseCount _houseCount = HouseCount.one;
  AreaType _areaType = AreaType.nonRegulated;
  bool _isOver85sqm = false;
  bool _isFirstTimeBuyer = false;
  bool _isDepopulationArea = false;
  NonHousingType _nonHousingType = NonHousingType.purchase;
  final List<AcquisitionTaxSnapshot> _results = [];

  int get price => _price;
  PropertyType get propertyType => _propertyType;
  HouseCount get houseCount => _houseCount;
  AreaType get areaType => _areaType;
  bool get isOver85sqm => _isOver85sqm;
  bool get isFirstTimeBuyer => _isFirstTimeBuyer;
  bool get isDepopulationArea => _isDepopulationArea;
  NonHousingType get nonHousingType => _nonHousingType;
  List<AcquisitionTaxSnapshot> get results => List.unmodifiable(_results);

  void setPrice(int value) {
    _price = value;
    notifyListeners();
  }

  void setPropertyType(PropertyType value) {
    _propertyType = value;
    notifyListeners();
  }

  void setHouseCount(HouseCount value) {
    _houseCount = value;
    notifyListeners();
  }

  void setAreaType(AreaType value) {
    _areaType = value;
    notifyListeners();
  }

  void setIsOver85sqm(bool value) {
    _isOver85sqm = value;
    notifyListeners();
  }

  void setIsFirstTimeBuyer(bool value) {
    _isFirstTimeBuyer = value;
    if (!value) _isDepopulationArea = false;
    notifyListeners();
  }

  void setIsDepopulationArea(bool value) {
    _isDepopulationArea = value;
    notifyListeners();
  }

  void setNonHousingType(NonHousingType value) {
    _nonHousingType = value;
    notifyListeners();
  }

  /// 계산 버튼 클릭 시 호출 - 결과 누적
  bool calculate() {
    if (_price <= 0) return false;

    final AcquisitionTaxResult result;

    if (_propertyType == PropertyType.housing) {
      result = AcquisitionTaxUtil.calculateHousing(
        price: _price,
        houseCount: _houseCount,
        areaType: _areaType,
        isOver85sqm: _isOver85sqm,
        isFirstTimeBuyer: _isFirstTimeBuyer,
        isDepopulationArea: _isDepopulationArea,
      );
    } else {
      result = AcquisitionTaxUtil.calculateNonHousing(
        price: _price,
        type: _nonHousingType,
      );
    }

    _results.add(AcquisitionTaxSnapshot(
      price: _price,
      propertyType: _propertyType,
      houseCount: _houseCount,
      areaType: _areaType,
      isOver85sqm: _isOver85sqm,
      isFirstTimeBuyer: _isFirstTimeBuyer,
      isDepopulationArea: _isDepopulationArea,
      nonHousingType: _propertyType == PropertyType.nonHousing ? _nonHousingType : null,
      result: result,
      calculatedAt: DateTime.now(),
    ));

    notifyListeners();
    return true;
  }

  void removeResult(int index) {
    if (index >= 0 && index < _results.length) {
      _results.removeAt(index);
      notifyListeners();
    }
  }

  void clearResults() {
    _results.clear();
    notifyListeners();
  }

  void reset() {
    _price = 0;
    _propertyType = PropertyType.housing;
    _houseCount = HouseCount.one;
    _areaType = AreaType.nonRegulated;
    _isOver85sqm = false;
    _isFirstTimeBuyer = false;
    _isDepopulationArea = false;
    _nonHousingType = NonHousingType.purchase;
    _results.clear();
    notifyListeners();
  }
}
