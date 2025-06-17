import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:route65/l10n/animation_set.dart';
import 'package:route65/l10n/l10n.dart';
import 'package:route65/no_internet.dart';

class MealSuggestionPage extends StatefulWidget {
  const MealSuggestionPage({super.key});

  @override
  State<MealSuggestionPage> createState() => _MealSuggestionPageState();
}

class Ref<T> {
  T? value;
  Ref(this.value);

  void update(T newV) => this.value = newV;
}

enum MajorType {
  CHICKEN,
  BEEF,
  HOTDOG
}


class RecommendationsContainer {
  MajorType? forType;
  Map<String, List<int>> content = {};

  void from(Map<String, dynamic> r) {
    content.clear();

    for(final key in r.keys) {
      content.addAll({key: (r[key] as List<dynamic>).map((i) => i as int).toList()});
    }
  }
}

class _MealSuggestionPageState extends State<MealSuggestionPage> with TickerProviderStateMixin {
  BoxDecoration? decoration;
  late ColorScheme cs;
  bool render = false, loading = false, connectionErr = false;
  AnimationSet p11 = AnimationSet(), p12 = AnimationSet(), p13 = AnimationSet();
  List<AnimationSet> recommendationsAnimations = [];
  PageController pageController = PageController();

  final Duration _animationDuration = Durations.medium2;

  @override
  void initState() {
    super.initState();

    // cs = Theme.of(context).colorScheme;

    p11.init(this, .0, 1.0, _animationDuration, Curves.easeIn);
    p12.init(this, .0, 1.0, _animationDuration, Curves.easeIn);
    p13.init(this, .0, 1.0, _animationDuration, Curves.easeIn);


    p11.whenHalf(p12);
    p12.whenHalf(p13);
    p11.start();

    setState(() {
      render = true;
    });
  }

  // Declare References here
  Ref<MajorType> majorType = Ref(null);

  String get getCurrentTypeKey => majorType.value == MajorType.CHICKEN ? 'Chicken' : majorType.value == MajorType.BEEF ? 'Beef' : 'Hotdog';

  final recommendationsContainer = RecommendationsContainer();

  Future<void> loadRecommendations() async {
    try {
      setState(() {
        loading = true;
      });

      final response = await http.get(Uri.parse('https://www.route-65-dashboard.com/api/recommendations'));
      if (response.statusCode != 200) throw 'Status code is not 200';

      recommendationsContainer.from(jsonDecode(response.body) as Map<String, dynamic>);

      setState(() {
        loading = false;
        connectionErr = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        loading = false;
        connectionErr = true;
      });
    }
  }

  Widget optionsContainer<T>({
    required Ref<T> ptr,
    required T newValue,
    required Function() onCall,
    required String content,
    required AnimationSet animation,
    required String img,
    double imageSize = 75,
    double? height
  }) {
    final cs = Theme.of(context).colorScheme;
    final selected = ptr.value == newValue;
    return Expanded(
      child: optionAnimator(
        value: animation.value,
        child: AnimatedContainer(
          duration: Durations.medium1,
          curve: Curves.easeIn,
          padding: EdgeInsets.all(15),
          height: height??double.infinity,
          // decoration: decoration?.copyWith(color: ptr.value == newValue ? cs.secondary : cs.surface),
          decoration: BoxDecoration(
            color: selected ? cs.secondary : cs.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: cs.secondary, width: 2)
          ),
          child: InkWell(
            onTap: () {
              ptr.update(newValue);
              setState(() {});
              onCall();
            },
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(content, style: TextStyle(color: selected ? cs.surface : cs.primary, fontSize: 18, fontWeight: FontWeight.bold),),
                  SizedBox(height: imageSize, child: Image.asset(img),)
                ],
              ),
            )
          )
        ),
      ),
    );
  }

  Widget optionAnimator({required Widget child, required double value}) {
    final size = MediaQuery.of(context).size;
    return Transform.translate(
      offset: Offset(size.width * (1.0 - value), 0),
      child: child,
    );

    // return Opacity();
  }

  Widget continueButton({required Function() callback, required bool rule}) {
    return SizedBox(width: double.infinity, child: ElevatedButton(onPressed: rule? () {
      nextPage(callback);
    }:null, child: Text('Continue')));
  }

  void nextPage(Function() callback) {
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('next Page called'),));
    pageController.nextPage(duration: Durations.medium1, curve: Curves.decelerate).then((_) => callback());
  }

  /*
   * what diversions i found : Chicken or beef,
   * Beef:
   *    Cooked,
   * The options will be viewed (pages) :
   *    chicken or beef
   *
   */

  Widget customColumn({required List<Widget> children}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, spacing: 25,
      children: children,
    );
  }

  Map<String, dynamic>? menuData;
  Map<String, FileImage>? savedImages;

  Map<String, dynamic> getItemFromMenu(int id) {
    final r = Map<String, dynamic>();

    // for(final key in menuData!.keys) {
    //   for (final item in menuData![key]) {
    //     if (item['i'] == id) {
    //       r.addAll(item as Map<String, dynamic>);
    //       break;
    //     }
    //   }
    // }

    // r.addAll(menuData![getCurrentTypeKey]![id] as Map<String, dynamic>);
    for(final item in menuData![getCurrentTypeKey]!) {
      if (item['id'] == id) {
        r.addAll(item);
        break;
      }
    }

    return r;
  }

  @override
  Widget build(BuildContext context) {
    final dic = L10n.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final q = MediaQuery.of(context);

    final safeMargin = EdgeInsets.only(top: q.padding.top + 20, left: 20, right: 20, bottom: 20);

    if (menuData == null || savedImages == null) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      menuData = args['menuData'];
      savedImages = args['images'];
    }

    return Scaffold(
      body: !render ? Center(
        child: SizedBox(width: 250, child: Lottie.asset('assets/loading.json')),
      ) : PageView(
        physics:NeverScrollableScrollPhysics(),
        controller: pageController,
        children: [
          /// --PAGE-CHICKEN-BEEF
          Container(
            margin: safeMargin,
            height: double.infinity,
            child: customColumn(children: [
              optionsContainer<MajorType>(ptr: majorType, newValue: MajorType.CHICKEN, content: dic.sug_chicken, animation: p11, onCall: () {

              }, img: 'assets/chicken.png'),

              optionsContainer<MajorType>(ptr: majorType, newValue: MajorType.BEEF, content: dic.sug_beef, animation: p12, onCall: () {

              }, img: 'assets/beef.png'),

              optionsContainer<MajorType>(ptr: majorType, newValue: MajorType.HOTDOG, content: dic.sug_hotdog, animation: p13, onCall: () {

              }, img: 'assets/hotdog.png'),

              continueButton(callback: () {
                loadRecommendations().then((_) {
                  if (!connectionErr) {
                    recommendationsAnimations = List.generate(recommendationsContainer.content.length, (i) {
                      final AnimationSet newAnimation = new AnimationSet();
                      newAnimation.init(this, .0, 1.0, _animationDuration, Curves.easeIn);
                      if (i != recommendationsContainer.content.length-1) newAnimation.whenDone(recommendationsAnimations[i+1]);
                      return newAnimation;
                    });
                  }
                });
                recommendationsAnimations.first.start();
              }, rule: majorType.value != null)
            ],),
          ),

          // --PAGE-2
          loading ? Center(
            child: SizedBox(width: 250, child: Lottie.asset('assets/loading.json'),),
          ) : connectionErr ? NoInternetPage(refreshCallback: loadRecommendations) : Container(
            // margin: safeMargin,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.only(top: q.padding.top + 10, bottom: 20, left: 10, right: 10),
                  width: double.infinity,
                  // margin: EdgeInsets.all(15),
                  child: Text(dic.route65_recommendation, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: cs.surface),),
                  decoration: BoxDecoration(
                    color: cs.secondary
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(children: (recommendationsContainer.content[getCurrentTypeKey]??[]).map((i) {
                      final item = getItemFromMenu(i);
                      final isAr = L10n.of(context)!.localeName == 'ar';

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        width: double.infinity,
                        // height: 500,
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(color: cs.secondary.withAlpha(15), spreadRadius: 5, blurRadius: 3)
                          ]
                        ),

                        child: Column(
                          spacing: 10,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(15),topRight: Radius.circular(15),),
                              child: Container(
                                width: MediaQuery.of(context).size.width - 40,
                                height: 300,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: savedImages?[item['i'] as String] as ImageProvider,
                                    fit: BoxFit.cover
                                  )
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15.0),
                              child: Row(
                                children: [
                                  Text('${item[isAr ? 'na' : 'ne']}', textAlign: TextAlign.start, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 7.0),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: (item['c'] as List<dynamic>).map((component) {
                                  return Container(
                                    height: 32.5,
                                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: cs.secondary.withOpacity(.7),
                                      borderRadius: BorderRadius.circular(15)
                                    ),
                                    child: Text(menuData?['cs'][component as String][0], style: TextStyle(color: cs.surface, fontSize: 16, fontWeight: FontWeight.bold),),
                                  );
                                }).toList(),
                              ),
                            ),

                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(side: BorderSide(color: cs.secondary, width: 2)),
                                onPressed: () {
                                  Navigator.pop(context, {
                                    'menuItem' : item,
                                    'cat' : getCurrentTypeKey
                                  });
                                },

                                child: Text('Go to meal view', style: TextStyle(color: cs.secondary, fontWeight: FontWeight.bold),),
                              ),
                            )
                          ],
                        ),
                      );
                    }).toList()),
                  ),
                ),
              ],
            )
            // Text('${recommendationsContainer.content}')
          )
        ],
      ),
    );
  }
}
