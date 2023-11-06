import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:top_news_app/bloc/comments/audiocomment_bloc.dart';
import 'package:top_news_app/ui/comment/playpausebutton.dart';
import 'package:top_news_app/utils/constants.dart';

import '../../bloc/comments/audiocomment_event.dart';
import '../../bloc/comments/audiocomment_state.dart';
import '../../model/comment/comment.dart';
import '../../resource/dimens.dart';
import '../../utils/commomutils.dart';

class CommentList extends StatefulWidget {
  final String sourceID;

  CommentList({
    super.key,
    required this.sourceID,
  });

  @override
  CommentListState createState() => CommentListState();
}

class CommentListState extends State<CommentList> {
  bool _isPlaying = false;
  bool _isRecording = false;
  String _mPath = '';
  int selectedIndex = -1;
  final AudioCommentsBloc _audioCommentBloc = AudioCommentsBloc();
  List<Comment> comments = [];

  @override
  void initState() {
    _audioCommentBloc.add(FetchAudioComments(id: widget.sourceID));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      BlocConsumer<AudioCommentsBloc, AudioCommentsState>(
          bloc: _audioCommentBloc,
          listener: (context, state) {},
          builder: (context, state) {
            if (state is AudioCommentLoadingState) {
              print("AudioCommentLoadingState");
              return const Center(child: CircularProgressIndicator());
            } else if (state is AudioCommentsLoaded) {
              print("AudioCommentsLoaded");
              comments = (state.comments ?? []);
              print(comments.length);
              if (comments.isNotEmpty) {
                return Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(cornerRadius),
                    ),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: dimen_16),
                  child: ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      return commentTile(comments[index].audioUrl ?? '', index);
                    },
                  ),
                );
              } else {
                return const Center(child: Text(AppConstants.noData));
              }
            } else if (state is AudioCommentsAdded) {
              print("AudioCommentsAdded");
              _audioCommentBloc.add(FetchAudioComments(id: widget.sourceID));
              return const Center(child: CircularProgressIndicator());
            } else if (state is AudioCommentsError) {
              print("AudioCommentsError");
              return Center(
                  child: Text('${AppConstants.loadFailed}: ${state.message}'));
            } //Player Stopped
            else if (state is IdlePlayState) {
              // comments[index].isPlaying = !comments[index].isPlaying;
              return Container();
            } //Recording stopped
            else if (state is IdleRecordState) {
              saveFileToDb();
              return Container();
            } else {
              return const Center(child: Text(AppConstants.noData));
            }
          }),
      recordWidget(),
    ]);
  }

  // List tile for Audio comments
  Widget commentTile(String audioUrl, int index) {
    print("CommentTile $audioUrl");
    print("CommentTile $index");
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(cornerRadius),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: userIconRadius,
            backgroundImage: NetworkImage(AppConstants.sampleAvatar),
          ),
          const SizedBox(width: dimen_16),
          // Add spacing between avatar and audio button
          // Audio Play Button
          PlayPauseButton(
            isPlaying: comments[index].isPlaying,
            onPressed: () {
              // Toggle play/pause state for the clicked item
              setState(() async {
                bool isUrlExists =
                    await checkUrlExists(comments[index].audioUrl);
                if (isUrlExists) {
                  print("IsUrlExists $isUrlExists");
                  comments[index].isPlaying = !comments[index].isPlaying;
                  _isPlaying = !_isPlaying;
                  if (_isPlaying) {
                    playAudio(comments[index].audioUrl, index);
                  } else {
                    stopPlay();
                  }
                }
              });
            },
          ),
        ],
      ),
    );
  }

  // Widget for record the audio file
  Widget recordWidget() {
    return Positioned(
      left: dimen_0,
      right: dimen_0,
      bottom: dimen_0,
      child: Container(
        padding: const EdgeInsets.all(dimen_16),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              //Save file
              _isRecording = !_isRecording;
              if (_isRecording) {
                recordAudio();
              } else {
                stopRecord();
              }
            });
          },
          child: Text(
              // Change the text based if record started
              _isRecording
                  ? AppConstants.stopRecordComment
                  : AppConstants.startRecordComment,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: textFontSize_14,
                  fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  // Function to save the audio file to database
  void saveFileToDb() {
    print("saveFileToDb");
    Comment comment = Comment(newsId: widget.sourceID, audioUrl: _mPath);
    _audioCommentBloc.add(AddAudioComment(comment: comment));
  }

  // Start and Stop record

  void stopRecord() {
    print(" stopRecord Recording: $_isRecording");
    _audioCommentBloc.add(StopRecordingEvent());
  }

  void recordAudio() async {
    print(" recordAudio  Record: $_isRecording");
    final tempDir = await getApplicationCacheDirectory();
    _mPath = await getFilePathMp4();
    _mPath = '${tempDir.path}/$_mPath';
    print("recordAudio : $_mPath");
    _audioCommentBloc.add(StartRecordingEvent(fileName: _mPath));
  }

// Start and Stop play
  void playAudio(String audioUrl, int index) async {
    print(" playAudio  Playing: $_isPlaying $audioUrl");
    comments[selectedIndex].isPlaying = true;
    _audioCommentBloc.add(StartPlayingEvent(audioFilePath: audioUrl));
  }

  void stopPlay() {
    print(" stopPlay Playing : $_isPlaying");
    _audioCommentBloc.add(StopPlayingEvent());
  }
}
