import 'package:flutter/foundation.dart';

import '../data/hiker_client.dart';
import '../data/ig_repository.dart';
import '../data/ig_url.dart';

/// 홈 화면의 링크 해석 상태.
class ResolveController extends ChangeNotifier {
  ResolveController(this._repository);

  final IgRepository _repository;

  bool _isLoading = false;
  String? _error;
  ResolveResult? _result;
  IgLink? _link;

  bool get isLoading => _isLoading;
  String? get error => _error;
  ResolveResult? get result => _result;

  /// 마지막으로 해석한 링크. 프로필 링크였을 때 프로필 탭으로 안내하는 데 쓴다.
  IgLink? get link => _link;

  /// 오류가 API 키 문제라서 설정 화면으로 보내야 하는지.
  bool _needsApiKey = false;
  bool get needsApiKey => _needsApiKey;

  Future<void> resolve(String input) async {
    final link = IgUrlParser.parse(input);
    _link = link;
    _isLoading = true;
    _error = null;
    _needsApiKey = false;
    _result = null;
    notifyListeners();

    try {
      _result = await _repository.resolve(link);
    } on HikerException catch (error) {
      _error = error.message;
      _needsApiKey = error.isAuthProblem;
    } catch (error) {
      _error = '알 수 없는 오류가 발생했습니다: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _result = null;
    _error = null;
    _link = null;
    _needsApiKey = false;
    notifyListeners();
  }
}
