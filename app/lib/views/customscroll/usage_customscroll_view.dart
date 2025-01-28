import 'package:flutter/material.dart';

class ViewCustomScroll extends StatefulWidget {
  const ViewCustomScroll({super.key});

  @override
  State<ViewCustomScroll> createState() => _ViewCustomScrollState();
}

class _ViewCustomScrollState extends State<ViewCustomScroll> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text("appbar"),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Container(
                  width: 100,
                  height: 100,
                  color: Colors.red,
                );
              },
              childCount: 10,
            ),
          ),
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
                  height: 100,
                  child: const Center(
                    child: Text("hello"),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.all(5),
                    color: Colors.blue,
                    child: Center(
                      child: Text('Item $index'),
                    ),
                  );
                },
              ),
            ),
          ),
           SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Container(
                  width: 100,
                  height: 100,
                  color: const Color.fromARGB(255, 68, 145, 5),
                );
              },
              childCount: 10,
            ),
          ),
        ],
      ),
    );
  }
}
