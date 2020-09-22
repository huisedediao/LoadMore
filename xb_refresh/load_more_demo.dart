import 'package:flutter/material.dart';
import 'load_more.dart';

class LoadMoreDemo extends StatefulWidget {
  @override
  _LoadMoreDemoState createState() => _LoadMoreDemoState();
}

class _LoadMoreDemoState extends State<LoadMoreDemo> {
  ScrollController _controller = ScrollController();
  GlobalKey<LoadMoreState> _loadMoreKey = GlobalKey();

  int _itemCount = 20;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller.addListener(() {
      ///接收offset
      _loadMoreKey.currentState.receiveOffset(
          _controller.offset, _controller.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("load more demo"),
        ),
        body: LoadMore(
            key: _loadMoreKey,

            ///是否需要展示加载到了更多数据
            needShowHasMore: false,

            ///开始加载更多的回调
            onBeginLoadMore: () {
              Future.delayed(Duration(seconds: 2), () {
                bool hasMore = false;
                if (_itemCount < 40) {
                  hasMore = true;
                  setState(() {
                    _itemCount += 10;
                  });
                }
                ///结束刷新，传是否有新数据
                _loadMoreKey.currentState.end(hasMore);
              });
            },

            ///创建提示继续上拉的widget
            beforeBuilder: (h) {
              return Container(
                height: h,
                alignment: Alignment.center,
                child: Text("继续上拉可以加载更多数据~"),
              );
            },

            ///创建提示松手开始加载的widget
            readyBuilder: (h) {
              return Container(
                height: h,
                alignment: Alignment.center,
                child: Text("准备好啦，松手开始加载~"),
              );
            },

            ///创建正在加载的widget
            loadingBuilder: (h) {
              return Container(
                height: h,
                alignment: Alignment.center,
                child: Text("玩命加载中~"),
              );
            },

            ///创建加载到新数据的widget
            hasMoreBuilder: (h) {
              return Container(
                height: h,
                alignment: Alignment.center,
                child: Text("太棒啦，有新数据诶~"),
              );
            },

            ///创建没有新数据的widget
            noMoreBuilder: (h) {
              return Container(
                height: h,
                alignment: Alignment.center,
                child: Text("没有新数据，看看前面的内容吧~"),
              );
            },
            child: CustomScrollView(
              controller: _controller,
              physics: AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: <Widget>[
                SliverList(
                    delegate: SliverChildBuilderDelegate((ctx, index) {
                  print("display : $index");
                  return Cell("$index", () {});
                }, childCount: _itemCount))
              ],
            )));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Cell extends StatelessWidget {
  static final height = 44.0;
  final String title;
  final VoidCallback onPressed;

  Cell(this.title, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: height,
        color: Colors.black38,
        alignment: Alignment.center,
        child: Column(
          children: <Widget>[
            Expanded(
                child: Center(
                    child: Text(title, style: TextStyle(color: Colors.white)))),
            Container(
              height: 1,
              color: Colors.white,
            )
          ],
        ),
      ),
    );
  }
}
