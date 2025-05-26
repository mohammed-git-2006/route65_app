
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class MealView extends StatefulWidget {
  const MealView({super.key});

  @override
  State<MealView> createState() => _MealViewState();
}

class _MealViewState extends State<MealView> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final size = MediaQuery.of(context).size;
    final cs = Theme.of(context).colorScheme;
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final data = args['data'];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title:Text('${data[isAr ? 'na' : 'ne']}'),
      ),
      body: SafeArea(child: Hero(
        tag: data['na'],
        child: Container(
          width: size.width,
          height: 350,
          decoration: BoxDecoration(
            image: DecorationImage(image: CachedNetworkImageProvider('https://www.route-65-dashboard.com/api/menu/${data['i']}'),
              fit: BoxFit.cover)
          ),
        ),
      )),
    );
  }
}
