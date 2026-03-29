// Location: agrivana\lib\features\community\bloc\community_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../service/community_service.dart';
import '../model/community_model.dart';

// Events
abstract class CommunityEvent extends Equatable {
  const CommunityEvent();
  @override
  List<Object?> get props => [];
}

class CommunityLoadData extends CommunityEvent {}

class CommunitySelectChannel extends CommunityEvent {
  final String? channelId;
  const CommunitySelectChannel(this.channelId);
  @override
  List<Object?> get props => [channelId];
}

class CommunityToggleLike extends CommunityEvent {
  final String postId;
  const CommunityToggleLike(this.postId);
  @override
  List<Object?> get props => [postId];
}

// States
abstract class CommunityState extends Equatable {
  const CommunityState();
  @override
  List<Object?> get props => [];
}

class CommunityInitial extends CommunityState {}
class CommunityLoading extends CommunityState {}

class CommunityLoaded extends CommunityState {
  final List<CommunityChannel> channels;
  final List<CommunityPost> posts;
  final String? selectedChannelId;

  const CommunityLoaded({
    this.channels = const [],
    this.posts = const [],
    this.selectedChannelId,
  });

  @override
  List<Object?> get props => [channels, posts, selectedChannelId];
}

// Bloc
class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  CommunityBloc() : super(CommunityInitial()) {
    on<CommunityLoadData>(_onLoad);
    on<CommunitySelectChannel>(_onSelectChannel);
    on<CommunityToggleLike>(_onToggleLike);
  }

  String? _selectedChannelId;
  List<CommunityChannel> _channels = [];
  List<CommunityPost> _posts = [];

  Future<void> _onLoad(CommunityLoadData event, Emitter<CommunityState> emit) async {
    emit(CommunityLoading());

    final chanResult = await CommunityService.getChannels();
    if (chanResult.success && chanResult.data != null) {
      final list = chanResult.data is List ? chanResult.data : [];
      _channels = list.map<CommunityChannel>((e) => CommunityChannel.fromJson(e)).toList();
    }

    final query = <String, String>{};
    if (_selectedChannelId != null) query['channelId'] = _selectedChannelId!;
    final postResult = await CommunityService.getPosts(query: query.isNotEmpty ? query : null);
    
    if (postResult.success && postResult.data != null) {
      final items = postResult.data['items'] ?? postResult.data;
      final list = items is List ? items : [];
      _posts = list.map<CommunityPost>((e) => CommunityPost.fromJson(e)).toList();
    } else {
      _posts = [];
    }

    emit(CommunityLoaded(channels: _channels, posts: _posts, selectedChannelId: _selectedChannelId));
  }

  void _onSelectChannel(CommunitySelectChannel event, Emitter<CommunityState> emit) {
    _selectedChannelId = event.channelId;
    add(CommunityLoadData());
  }

  Future<void> _onToggleLike(CommunityToggleLike event, Emitter<CommunityState> emit) async {
    final result = await CommunityService.toggleReaction(event.postId, 'like');
    if (result.success) {
      // Background load to refresh data, or we could update the local state manually. Let's just reload.
      add(CommunityLoadData());
    }
  }
}
