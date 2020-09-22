import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

///before:上拉加载更多
///ready:松开手刷新
///loading:正在加载
///hasMore:加载到了新数据
///noMore:没有新数据
enum LoadMoreOn { before, ready, loading, hasMore, noMore }

typedef FooterBuilder = Widget Function(double height);

class LoadMore extends StatefulWidget {
  final Widget child;
  final VoidCallback onBeginLoadMore;
  final FooterBuilder beforeBuilder;
  final FooterBuilder readyBuilder;
  final FooterBuilder loadingBuilder;
  final FooterBuilder noMoreBuilder;
  final FooterBuilder hasMoreBuilder;
  final bool needShowHasMore;

  ///大于这个值可以刷新,也用于限制footer的高度
  final double loadingOffset;

  LoadMore(
      {this.child,
      this.onBeginLoadMore,
      this.beforeBuilder,
      this.readyBuilder,
      this.noMoreBuilder,
      this.hasMoreBuilder,
      this.loadingBuilder,
      this.loadingOffset = 50.0,
      this.needShowHasMore = false,
      Key key})
      : super(key: key);

  @override
  LoadMoreState createState() => LoadMoreState();
}

class LoadMoreState extends State<LoadMore> {
  LoadMoreFooterBuilderVM _builderVM;
  LoadMoreChildPaddingVM _paddingVM;
  LoadMoreFooterOffsetVM _offsetVM;
  bool _isUserAction = false;
  double _lastOffset = 0;
  double _maxOffset = 0;

  ///是否有数据更新
  end(bool hasMore) {
    print(hasMore);
    if (_builderVM.on == LoadMoreOn.loading) {
      if (hasMore) {
        if (widget.needShowHasMore) {
          _builderVM.on = LoadMoreOn.hasMore;
          Future.delayed(Duration(seconds: 1), () {
            _paddingVM.show = false;
            _resetFooter();
          });
        } else {
          _paddingVM.show = false;
          _resetFooter();
        }
      } else {
        _builderVM.on = LoadMoreOn.noMore;
        Future.delayed(Duration(seconds: 1), () {
          ///如果是正在刷新或者刚刚刷新完成的时候，用户又拖动ScrollView，则再刷新一次显示
          ///这个时候child的外层padding top一定是为widget.loadingOffset的，计算偏移量的时候要考虑这个因素
          if (_isUserAction) {
            double fitOffset = _lastOffset - _maxOffset;
            if (fitOffset >= 0) {
              _builderVM.on = LoadMoreOn.ready;
              _offsetVM.offset = widget.loadingOffset;
            } else if (fitOffset + widget.loadingOffset >= 0) {
              _builderVM.on = LoadMoreOn.before;
              _offsetVM.offset = fitOffset + widget.loadingOffset;
            } else {
              _resetFooter();
            }
          } else {
            _resetFooter();
          }
          _paddingVM.show = false;
        });
      }
    }
  }

  receiveOffset(double offset, double maxOffset) {
    _maxOffset = maxOffset;
    bool upward = offset > _lastOffset;
    _lastOffset = offset;

    if (_builderVM.on == LoadMoreOn.loading ||
        _builderVM.on == LoadMoreOn.hasMore ||
        _builderVM.on == LoadMoreOn.noMore) {
      return;
    }
    double fitOffset = offset - maxOffset;
    if (fitOffset <= 0) {
      return;
    }
    _offsetVM.offset = fitOffset;

    if (upward) {
      if (_isUserAction) {
        _isUserActionRun(fitOffset);
      } else {
        _builderVM.on = LoadMoreOn.before;
      }
    } else {
      if (_isUserAction) {
        _isUserActionRun(fitOffset);
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _builderVM = LoadMoreFooterBuilderVM();
    _paddingVM = LoadMoreChildPaddingVM();
    _offsetVM = LoadMoreFooterOffsetVM();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Expanded(child: Container()),
            ChangeNotifierProvider(
              create: (ctx) {
                return _builderVM;
              },
              child:
                  Consumer(builder: (ctx, LoadMoreFooterBuilderVM vm, child) {
                Widget child;
                if (vm.on == LoadMoreOn.before) {
                  child = _beforeDispaly();
                } else if (vm.on == LoadMoreOn.ready) {
                  child = _readyDispaly();
                } else if (vm.on == LoadMoreOn.loading) {
                  child = _loadingDispaly();
                } else if (vm.on == LoadMoreOn.hasMore) {
                  child = _hasMoreDispaly();
                } else if (vm.on == LoadMoreOn.noMore) {
                  child = _noMoreDispaly();
                } else {
                  child = Container();
                }
                return ChangeNotifierProvider(
                  create: (ctx) {
                    return _offsetVM;
                  },
                  child: Consumer(
                    builder: (ctx, LoadMoreFooterOffsetVM offsetVM, reChild) {
                      double top = widget.loadingOffset - offsetVM.offset;
                      if (top < 0) {
                        top = 0;
                      }
                      return Container(
//                        color: Colors.grey,
                        height: widget.loadingOffset,
                        child: Padding(
                          padding: EdgeInsets.only(top: top),
                          child: reChild,
                        ),
                      );
                    },
                    child: child,
                  ),
                );
              }),
            )
          ],
        ),
        Listener(
            onPointerDown: (detail) {
              _isUserAction = true;
            },
            onPointerUp: (detail) {
              _isUserAction = false;
              if (_builderVM.on == LoadMoreOn.ready) {
                _builderVM.on = LoadMoreOn.loading;
                _paddingVM.show = true;
                if (widget.onBeginLoadMore != null) {
                  widget.onBeginLoadMore();
                }
              }
            },
            child: ChangeNotifierProvider(
              create: (ctx) {
                return _paddingVM;
              },
              child: Consumer(
                builder: (ctx, LoadMoreChildPaddingVM vm, child) {
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: vm.show ? widget.loadingOffset : 0.0),
                    child: child,
                  );
                },
                child: widget.child,
              ),
            ))
      ],
    );
  }

  _resetFooter() {
    _builderVM.on = LoadMoreOn.before;
    if (_offsetVM.offset != 0) {
      _offsetVM.offset = 0;
    }
  }

  _isUserActionRun(double fitOffset) {
    if (fitOffset >= widget.loadingOffset) {
      _builderVM.on = LoadMoreOn.ready;
    } else {
      _builderVM.on = LoadMoreOn.before;
    }
  }

  Widget _beforeDispaly() {
    if (widget.beforeBuilder != null)
      return widget.beforeBuilder(widget.loadingOffset);
    return Container(
        alignment: Alignment.center,
        height: widget.loadingOffset,
        child: Text("上拉加载更多"));
  }

  Widget _readyDispaly() {
    if (widget.readyBuilder != null)
      return widget.readyBuilder(widget.loadingOffset);
    return Container(
        alignment: Alignment.center,
        height: widget.loadingOffset,
        child: Text("松开手开始加载"));
  }

  Widget _loadingDispaly() {
    if (widget.loadingBuilder != null)
      return widget.loadingBuilder(widget.loadingOffset);
    return Container(
        alignment: Alignment.center,
        height: widget.loadingOffset,
        child: Text("正在加载"));
  }

  Widget _hasMoreDispaly() {
    if (widget.hasMoreBuilder != null)
      return widget.hasMoreBuilder(widget.loadingOffset);
    return Container(
        alignment: Alignment.center,
        height: widget.loadingOffset,
        child: Text("加载完成"));
  }

  Widget _noMoreDispaly() {
    if (widget.noMoreBuilder != null)
      return widget.noMoreBuilder(widget.loadingOffset);
    return Container(
        alignment: Alignment.center,
        height: widget.loadingOffset,
        child: Text("没有新数据啦~"));
  }
}

class LoadMoreFooterOffsetVM extends ChangeNotifier {
  double _offset = 0;

  double get offset => _offset;

  set offset(double offset) {
    _offset = offset;
    notifyListeners();
  }
}

class LoadMoreFooterBuilderVM extends ChangeNotifier {
  LoadMoreOn _on = LoadMoreOn.before;

  LoadMoreOn get on => _on;

  set on(LoadMoreOn on) {
    _on = on;
    notifyListeners();
  }
}

class LoadMoreChildPaddingVM extends ChangeNotifier {
  bool _show = false;

  bool get show => _show;

  set show(bool show) {
    _show = show;
    notifyListeners();
  }
}
