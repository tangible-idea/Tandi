import 'package:flutter/foundation.dart';

import '../data/hiker_client.dart';
import '../data/ig_repository.dart';
import '../models/ig_post.dart';
import '../models/ig_user.dart';

/// 프로필 화면에서 보고 있는 목록의 종류.
enum ProfileFeed { posts, reels, stories }

extension ProfileFeedLabel on ProfileFeed {
  String get label => switch (this) {
    ProfileFeed.posts => '게시물',
    ProfileFeed.reels => '릴스',
    ProfileFeed.stories => '스토리',
  };
}

/// 계정 하나의 미디어를 페이지 단위로 불러오는 상태.
class ProfileController extends ChangeNotifier {
  ProfileController(this._repository);

  final IgRepository _repository;

  IgUser? _user;
  ProfileFeed _feed = ProfileFeed.posts;
  final List<IgPost> _posts = [];
  String? _cursor;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  bool _needsApiKey = false;

  IgUser? get user => _user;
  ProfileFeed get feed => _feed;
  List<IgPost> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get needsApiKey => _needsApiKey;

  /// 스토리는 한 번에 전부 오므로 더 불러올 페이지가 없다.
  bool get hasMore => _feed != ProfileFeed.stories && _cursor != null;

  Future<void> open(String username) async {
    _isLoading = true;
    _error = null;
    _needsApiKey = false;
    _posts.clear();
    _cursor = null;
    _user = null;
    _feed = ProfileFeed.posts;
    notifyListeners();

    try {
      _user = await _repository.fetchUser(username);
      await _loadFirstPage();
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

  Future<void> switchFeed(ProfileFeed value) async {
    if (_feed == value || _user == null) return;
    _feed = value;
    _posts.clear();
    _cursor = null;
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      await _loadFirstPage();
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

  Future<void> loadMore() async {
    final user = _user;
    final cursor = _cursor;
    if (user == null || cursor == null || _isLoadingMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final page = _feed == ProfileFeed.reels
          ? await _repository.fetchUserClips(user.pk, cursor: cursor)
          : await _repository.fetchUserMedias(user.pk, cursor: cursor);
      _posts.addAll(page.posts);
      // 커서가 그대로면 서버가 같은 페이지를 계속 줄 수 있으므로 여기서 끊는다.
      _cursor = page.nextCursor == cursor ? null : page.nextCursor;
    } on HikerException catch (error) {
      _error = error.message;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _loadFirstPage() async {
    final user = _user!;
    switch (_feed) {
      case ProfileFeed.posts:
        final page = await _repository.fetchUserMedias(user.pk);
        _posts.addAll(page.posts);
        _cursor = page.nextCursor;
      case ProfileFeed.reels:
        final page = await _repository.fetchUserClips(user.pk);
        _posts.addAll(page.posts);
        _cursor = page.nextCursor;
      case ProfileFeed.stories:
        _posts.addAll(await _repository.fetchUserStories(user.username));
        _cursor = null;
    }
  }

  void clear() {
    _user = null;
    _posts.clear();
    _cursor = null;
    _error = null;
    _needsApiKey = false;
    _feed = ProfileFeed.posts;
    notifyListeners();
  }
}
